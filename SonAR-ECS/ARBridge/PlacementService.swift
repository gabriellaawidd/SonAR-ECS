import ARKit
import RealityKit
import simd
import UIKit

final class PlacementService {
    private weak var arView: ARView?
    private let tapFeedback = UIImpactFeedbackGenerator(style: .light)
    private let materialDetectionManager = MaterialDetectionManager()

    private static let sensorNodeName = "SensorNode"
    private static let layerConfigs: [(angle: Float, count: Int)] = [
        (3.75, 8), (7.5, 12), (11.25, 16), (15.0, 20)
    ]

    init(arView: ARView) {
        self.arView = arView
        tapFeedback.prepare()
    }

    @MainActor
    func handleTap(at point: CGPoint) async {
        guard let arView,
              let scene = arView.scene as RealityKit.Scene?,
              let sensor = scene.findEntity(named: Self.sensorNodeName),
              var state = sensor.components[SensorStateComponent.self] else { return }

        if state.phase == .placed {
            return
        }

        guard let preview = sensor.components[SensorPreviewComponent.self],
              let finalPosition = preview.lastTargetPosition,
              let finalOrientation = preview.lastTargetOrientation else { return }

        tapFeedback.impactOccurred()

        state.phase = .placed
        state.currentLockID = UUID()
        let lockID = state.currentLockID!
        sensor.components[SensorStateComponent.self] = state

        sensor.components.set(PlacementAnimationComponent(
            finalPosition: finalPosition,
            finalOrientation: finalOrientation
        ))

        let directions = Self.generateConeDirections(orientation: finalOrientation)
        let hits = await raycast(from: finalPosition, directions: directions, session: arView.session)

        sensor.components.set(NeedsSurfaceReconstruction(
            lockID: lockID,
            hits: hits,
            directions: directions
        ))

        if let centerHit = hits.first ?? nil {
            let pixelBuffer = arView.session.currentFrame?.capturedImage
            detectMaterial(
                pixelBuffer: pixelBuffer,
                hit: centerHit,
                facingDirection: directions.first ?? SIMD3<Float>(0, 0, -1),
                sensor: sensor,
                lockID: lockID
            )
        }
    }

    private func raycast(from origin: SIMD3<Float>, directions: [SIMD3<Float>], session: ARSession) async -> [RaycastHit?] {
        await Task.detached(priority: .userInitiated) {
            directions.map { direction -> RaycastHit? in
                let query = ARRaycastQuery(
                    origin: origin,
                    direction: simd_normalize(direction),
                    allowing: .estimatedPlane,
                    alignment: .any
                )
                guard let result = session.raycast(query).first else { return nil }

                let worldPosition = SIMD3<Float>(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                let normal = simd_normalize(SIMD3<Float>(result.worldTransform.columns.1.x, result.worldTransform.columns.1.y, result.worldTransform.columns.1.z))

                return RaycastHit(
                    worldPosition: worldPosition,
                    normal: normal,
                    distance: simd_distance(origin, worldPosition),
                    screenPoint: nil,
                    timestamp: session.currentFrame?.timestamp ?? 0,
                    pixelBuffer: session.currentFrame?.capturedImage
                )
            }
        }.value
    }

    private static func generateConeDirections(orientation: simd_quatf) -> [SIMD3<Float>] {
        var angles: [(Float, SIMD3<Float>)] = [(0, [1, 0, 0])]
        for config in layerConfigs {
            for i in 0..<config.count {
                let theta = Float(i) * 2.0 * .pi / Float(config.count)
                let axis = SIMD3<Float>(cos(theta), sin(theta), 0)
                angles.append((config.angle, axis))
            }
        }
        return angles.map { angle, axis in
            let rotation = simd_quatf(angle: angle * .pi / 180, axis: axis)
            return (orientation * rotation).act(SIMD3<Float>(0, 0, -1))
        }
    }

    private func detectMaterial(pixelBuffer: CVPixelBuffer?, hit: RaycastHit, facingDirection: SIMD3<Float>, sensor: Entity, lockID: UUID) {
        materialDetectionManager.detect(pixelBuffer: pixelBuffer, hit: hit, facingDirection: facingDirection) { [weak sensor] reading in
            DispatchQueue.main.async {
                guard let sensor,
                      var surface = sensor.components[ReconstructedSurfaceComponent.self],
                      surface.lockID == lockID else { return }

                surface.materialCategory = reading.materialCategory
                surface.materialConfidence = reading.materialConfidence
                sensor.components[ReconstructedSurfaceComponent.self] = surface
            }
        }
    }
}