//
//  PreviewFollowSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import simd

struct PreviewFollowSystem: System {
    private static let previewQuery = EntityQuery(
        where: .has(SensorPreviewComponent.self) && .has(SensorStateComponent.self)
    )
    private static let cameraQuery = EntityQuery(where: .has(CameraTrackingComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        guard let cameraEntity = Array(context.entities(matching: Self.cameraQuery, updatingSystemWhen: .rendering)).first,
              let camera = cameraEntity.components[CameraTrackingComponent.self] else { return }

        for entity in context.entities(matching: Self.previewQuery, updatingSystemWhen: .rendering) {
            guard var preview = entity.components[SensorPreviewComponent.self],
                  let state = entity.components[SensorStateComponent.self],
                  state.phase == .carrying else { continue }

            let targetPosition = PlacementSolver.previewPosition(
                cameraTransform: camera.worldTransform,
                distance: preview.followDistance
            )
            let targetOrientation = PlacementSolver.previewOrientation(
                cameraTransform: camera.worldTransform
            )

            if preview.lastTargetPosition == nil {
                entity.position = targetPosition
                entity.orientation = targetOrientation
                preview.lastTargetPosition = targetPosition
                preview.lastTargetOrientation = targetOrientation
                entity.components[SensorPreviewComponent.self] = preview
                continue
            }

            let currentPosition = preview.lastTargetPosition!
            let currentOrientation = preview.lastTargetOrientation ?? targetOrientation

            let factor = PlacementSolver.lerpFactor(deltaTime: Float(context.deltaTime), smoothing: preview.smoothing)

            let newPosition = simd_mix(currentPosition, targetPosition, SIMD3<Float>(repeating: factor))
            let newOrientation = simd_slerp(currentOrientation, targetOrientation, factor)

            entity.position = newPosition
            entity.orientation = newOrientation

            preview.lastTargetPosition = newPosition
            preview.lastTargetOrientation = newOrientation
            entity.components[SensorPreviewComponent.self] = preview
        }
    }
}
