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
            
            let dirToCamera = SIMD3<Float>(delta.x / horizontalDist, 0, delta.z / horizontalDist)
            let worldUp = SIMD3<Float>(0, 1, 0)
            
            if billboardComp.facesPositiveZ {
                // +Z faces camera
                let right = simd_normalize(simd_cross(worldUp, dirToCamera))
                let up = simd_cross(dirToCamera, right)
                let targetRot = simd_quatf(simd_float3x3(right, up, dirToCamera))
                entity.setOrientation(targetRot, relativeTo: nil)
            } else {
                // -Z faces camera
                let fwd = -dirToCamera
                let right = simd_normalize(simd_cross(worldUp, fwd))
                let up = simd_cross(fwd, right)
                let targetRot = simd_quatf(simd_float3x3(right, up, fwd))
                entity.setOrientation(targetRot, relativeTo: nil)
            }
        }
    }
}
