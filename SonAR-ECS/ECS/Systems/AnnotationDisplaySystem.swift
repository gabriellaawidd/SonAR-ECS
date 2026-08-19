//
//  AnnotationDisplaySystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import simd
import Foundation

struct AnnotationDisplaySystem: System {
    private static let needsDisplayQuery = EntityQuery(where: .has(NeedsAnnotationDisplay.self))
    private static let existingMarkerQuery = EntityQuery(where: .has(AnnotationMarkerComponent.self))

    private static let heightAboveSensor: Float = 0.045
    private static let bobHeight: Float = 0.006
    private static let bobDuration: TimeInterval = 0.9

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.needsDisplayQuery, updatingSystemWhen: .rendering) {
            guard let needs = entity.components[NeedsAnnotationDisplay.self] else { continue }

            for old in context.entities(matching: Self.existingMarkerQuery, updatingSystemWhen: .rendering) {
                old.removeFromParent()
            }

            if let marker = AnnotationMarker.makeEntity() {
                let sensorWorldPos = entity.position(relativeTo: nil)
                let worldPosition = sensorWorldPos
                    + SIMD3<Float>(0, Self.heightAboveSensor, 0)

                if let anchor = context.scene.anchors.first {
                    anchor.addChild(marker)
                    marker.setPosition(worldPosition, relativeTo: nil)
                }

                if let cameraAnchor = context.scene.findEntity(named: "CameraTracker") {
                    let cameraTransform = cameraAnchor.transformMatrix(relativeTo: nil)
                    let camPos = SIMD3<Float>(
                        cameraTransform.columns.3.x,
                        cameraTransform.columns.3.y,
                        cameraTransform.columns.3.z
                    )
                    let delta = camPos - marker.position(relativeTo: nil)
                    let horizontal = sqrt(delta.x * delta.x + delta.z * delta.z)
                    if horizontal > 1e-4 {
                        let dir = SIMD3<Float>(delta.x / horizontal, 0, delta.z / horizontal)
                        let worldUp = SIMD3<Float>(0, 1, 0)
                        var right = simd_cross(worldUp, dir)
                        if simd_length_squared(right) > 1e-6 {
                            right = simd_normalize(right)
                            let up = simd_normalize(simd_cross(dir, right))
                            marker.setOrientation(simd_quatf(simd_float3x3(right, up, dir)), relativeTo: nil)
                        }
                    }
                }

                marker.components.set(AnnotationMarkerComponent(content: needs.content))
                marker.components.set(CustomBillboardComponent(facesPositiveZ: true))
                marker.components.set(BobbingComponent(
                    baseLocalY: marker.position.y,
                    bobHeight: Self.bobHeight,
                    legDuration: Self.bobDuration
                ))
            }

            entity.components.remove(NeedsAnnotationDisplay.self)
        }
    }
}
