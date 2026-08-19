//
//  BillboardSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import simd

struct BillboardSystem: System {
    private static let billboardQuery = EntityQuery(where: .has(CustomBillboardComponent.self))
    private static let cameraQuery = EntityQuery(where: .has(CameraTrackingComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        guard let cameraEntity = Array(context.entities(matching: Self.cameraQuery, updatingSystemWhen: .rendering)).first,
              let camera = cameraEntity.components[CameraTrackingComponent.self] else { return }
        
        let cameraPosition = SIMD3<Float>(
            camera.worldTransform.columns.3.x,
            camera.worldTransform.columns.3.y,
            camera.worldTransform.columns.3.z
        )
        
        for entity in context.entities(matching: Self.billboardQuery, updatingSystemWhen: .rendering) {
            guard let billboardComp = entity.components[CustomBillboardComponent.self] else { continue }
            let entityPosition = entity.position(relativeTo: nil)

            let delta = cameraPosition - entityPosition
            let horizontalDist = sqrt(delta.x * delta.x + delta.z * delta.z)
            guard horizontalDist > 1e-4 else { continue }

            let flatDir = SIMD3<Float>(delta.x / horizontalDist, 0, delta.z / horizontalDist)

            let rawPitch = atan2(delta.y, horizontalDist)
            let maxPitch = billboardComp.maxPitchDegrees * .pi / 180
            let softenedPitch = max(-maxPitch, min(maxPitch, rawPitch * billboardComp.pitchSofteningFactor))

            let cosP = cos(softenedPitch)
            let dirToCamera = SIMD3<Float>(
                flatDir.x * cosP,
                sin(softenedPitch),
                flatDir.z * cosP
            )
            let worldUp = SIMD3<Float>(0, 1, 0)

            let forward = billboardComp.facesPositiveZ ? dirToCamera : -dirToCamera
            var right = simd_cross(worldUp, forward)
            if simd_length_squared(right) < 1e-6 {
                right = SIMD3<Float>(1, 0, 0)
            }
            right = simd_normalize(right)
            let up = simd_normalize(simd_cross(forward, right))
            let targetRot = simd_quatf(simd_float3x3(right, up, forward))

            let current = entity.orientation(relativeTo: nil)
            let smoothed = simd_slerp(current, targetRot, billboardComp.smoothing)
            entity.setOrientation(smoothed, relativeTo: nil)
        }
    }
}
