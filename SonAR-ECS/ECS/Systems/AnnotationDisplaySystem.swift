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

    private static let heightAboveSensor: Float = 0.08
    private static let bobHeight: Float = 0.008
    private static let bobDuration: TimeInterval = 0.9

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.needsDisplayQuery, updatingSystemWhen: .rendering) {
            guard let needs = entity.components[NeedsAnnotationDisplay.self] else { continue }

            for old in context.entities(matching: Self.existingMarkerQuery, updatingSystemWhen: .rendering) {
                old.removeFromParent()
            }

            if let marker = AnnotationMarker.makeEntity() {
                let sensorOrientation = entity.orientation(relativeTo: nil)
                let sensorForward = sensorOrientation.act(SIMD3<Float>(0, 0, -1))
                let towardsUser = -sensorForward

                let worldPosition = needs.hitPosition
                    + SIMD3<Float>(0, Self.heightAboveSensor, 0)
                    + towardsUser * 0.08

                if let anchor = context.scene.anchors.first {
                    anchor.addChild(marker)
                    marker.setPosition(worldPosition, relativeTo: nil)
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
