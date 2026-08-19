//
//  PlacementService.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import ARKit
import RealityKit
import simd
import UIKit

final class PlacementService {
    private weak var arView: ARView?
    private let tapFeedback = UIImpactFeedbackGenerator(style: .light)
    private let materialDetectionManager = MaterialDetectionManager()
    private weak var guidedBridge: ARGuidedBridge?

    init(arView: ARView, guidedBridge: ARGuidedBridge) {
        self.arView = arView
        self.guidedBridge = guidedBridge
        tapFeedback.prepare()
    }

    @MainActor
    func handleTap(at point: CGPoint) async {
        guard let arView else { return }

        guard let sensor = arView.scene.anchors.compactMap({ $0.findEntity(named: "SensorContainer") ?? $0.findEntity(named: SceneEntityNames.sensorNode) }).first else {
            return
        }

        var state = sensor.components[SensorStateComponent.self] ?? SensorStateComponent()
        if state.phase == .placed { return }

        let preview = sensor.components[SensorPreviewComponent.self]
        let finalPosition = preview?.lastTargetPosition ?? sensor.position(relativeTo: nil)
        let finalOrientation = preview?.lastTargetOrientation ?? sensor.orientation(relativeTo: nil)

        tapFeedback.impactOccurred()

        state.phase = .placed
        state.currentLockID = UUID()
        let lockID = state.currentLockID!
        sensor.components[SensorStateComponent.self] = state

        if let sensorMesh = sensor.findEntity(named: "sensor") ?? sensor.findEntity(named: "SensorNode") {
            SensorMaterialManager.restoreOriginal(to: sensorMesh)
        }

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

        guidedBridge?.beginMeasurement()

        let anyHit = hits.compactMap({ $0 }).first
        let pixelBuffer = arView.session.currentFrame?.capturedImage
        if let targetHit = anyHit {
            detectMaterial(
                pixelBuffer: pixelBuffer,
                hit: targetHit,
                facingDirection: directions.first ?? SIMD3<Float>(0, 0, -1),
                sensor: sensor,
                lockID: lockID
            )
        } else {
            if var surface = sensor.components[ReconstructedSurfaceComponent.self], surface.lockID == lockID {
                surface.isMaterialEvaluated = true
                sensor.components[ReconstructedSurfaceComponent.self] = surface
            }
        }
    }
    
    private static let markerScreenTapRadius: CGFloat = 64

    @MainActor
    func handleMarkerTap(at point: CGPoint) async -> Bool {
        guard let arView,
              let marker = activeAnnotationMarker(),
              let markerComponent = marker.components[AnnotationMarkerComponent.self] else {
            return false
        }

        if isTapOnMarker(point, marker: marker, in: arView) {
            return spawnRobot(with: markerComponent.content, removing: marker)
        }
        return false
    }

    @MainActor
    private func isTapOnMarker(_ point: CGPoint, marker: Entity, in arView: ARView) -> Bool {
        let samplePoints = [
            point,
            CGPoint(x: point.x - 24, y: point.y),
            CGPoint(x: point.x + 24, y: point.y),
            CGPoint(x: point.x, y: point.y - 24),
            CGPoint(x: point.x, y: point.y + 24),
            CGPoint(x: point.x - 18, y: point.y - 18),
            CGPoint(x: point.x + 18, y: point.y + 18)
        ]

        for p in samplePoints {
            if let entity = arView.entity(at: p) ?? arView.hitTest(p).first?.entity,
               AnnotationMarker.isTappable(entity) || isSensorOrWave(entity) {
                return true
            }
        }

        if let screen = arView.project(marker.position(relativeTo: nil)) {
            let dx = screen.x - point.x
            let dy = screen.y - point.y
            if (dx * dx + dy * dy) <= Self.markerScreenTapRadius * Self.markerScreenTapRadius {
                return true
            }
        }

        return false
    }

    @MainActor
    private func activeAnnotationMarker() -> Entity? {
        guard let arView else { return nil }
        let query = EntityQuery(where: .has(AnnotationMarkerComponent.self))
        return Array(arView.scene.performQuery(query)).first
    }

    private func isSensorOrWave(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let node = current {
            let name = node.name
            if name == "wavePulse"
                || name == "SensorContainer"
                || name == SceneEntityNames.sensorNode
                || name == "sensor" {
                return true
            }
            current = node.parent
        }
        return false
    }

    @MainActor
    private func spawnRobot(with content: FeedbackPresentation, removing marker: Entity) -> Bool {
        guard let arView,
              let mascotNode = arView.scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.mascotNode) ?? $0.findEntity(named: "MascotNode") }).first,
              let robotMascot = mascotNode.findEntity(named: SceneEntityNames.robotMascot) ?? mascotNode.findEntity(named: "robot_mascot") else {
            return false
        }

        mascotNode.isEnabled = true
        robotMascot.isEnabled = true
        robotMascot.components.set(NeedsMascotFeedback(content: content))
        marker.removeFromParent()
        return true
    }

    private static let layerConfigs: [(angle: Float, count: Int)] = [
        (3.75, 8), (7.5, 12), (11.25, 16), (15.0, 20)
    ]

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
    
    private func raycast(from origin: SIMD3<Float>, directions: [SIMD3<Float>], session: ARSession) async -> [RaycastHit?] {
        let timestamp = session.currentFrame?.timestamp ?? 0
        let pixelBuffer = session.currentFrame?.capturedImage

        return await Task.detached(priority: .userInitiated) {
            directions.map { direction -> RaycastHit? in
                let query = ARRaycastQuery(
                    origin: origin,
                    direction: simd_normalize(direction),
                    allowing: .estimatedPlane,
                    alignment: .any
                )
                guard let result = session.raycast(query).first else { return nil }

                let worldPosition = SIMD3<Float>(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                let axisY = simd_normalize(SIMD3<Float>(
                    result.worldTransform.columns.1.x,
                    result.worldTransform.columns.1.y,
                    result.worldTransform.columns.1.z
                ))
                let axisZ = simd_normalize(SIMD3<Float>(
                    result.worldTransform.columns.2.x,
                    result.worldTransform.columns.2.y,
                    result.worldTransform.columns.2.z
                ))
                let rayDir = simd_normalize(direction)
                var normal = abs(simd_dot(rayDir, axisZ)) >= abs(simd_dot(rayDir, axisY)) ? axisZ : axisY
                if simd_dot(normal, rayDir) > 0 {
                    normal = -normal
                }

                return RaycastHit(
                    worldPosition: worldPosition,
                    normal: normal,
                    distance: simd_distance(origin, worldPosition),
                    screenPoint: nil,
                    timestamp: timestamp,
                    pixelBuffer: pixelBuffer
                )
            }
        }.value
    }

    private func detectMaterial(pixelBuffer: CVPixelBuffer?, hit: RaycastHit, facingDirection: SIMD3<Float>, sensor: Entity, lockID: UUID) {
        guard let pixelBuffer else {
            if var surface = sensor.components[ReconstructedSurfaceComponent.self], surface.lockID == lockID {
                surface.isMaterialEvaluated = true
                sensor.components[ReconstructedSurfaceComponent.self] = surface
            }
            return
        }
        materialDetectionManager.detect(
            pixelBuffer: pixelBuffer,
            hit: hit,
            facingDirection: facingDirection
        ) { [weak sensor] reading in
            guard let sensor,
                  var surface = sensor.components[ReconstructedSurfaceComponent.self],
                  surface.lockID == lockID else { return }
            surface.materialCategory = reading.materialCategory
            surface.materialConfidence = reading.materialConfidence
            surface.isMaterialEvaluated = true
            sensor.components[ReconstructedSurfaceComponent.self] = surface
        }
    }
}
