//
//  SurfaceReconstructionSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import simd
import os

struct SurfaceReconstructionSystem: System {
    private static let query = EntityQuery(where: .has(NeedsSurfaceReconstruction.self))
    private static let echoReturnAngleLimitDeg: Float = 10

    private static let logger = Logger(subsystem: "com.sonar.ecs", category: "SurfaceReconstruction")

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let needs = entity.components[NeedsSurfaceReconstruction.self] else { continue }

            let centerHit = needs.hits.first ?? nil
            let centerDirection = needs.directions.first ?? SIMD3<Float>(0, 0, -1)
            let centerAngle = centerHit?.incidenceAngleDegrees(incoming: centerDirection)

            let centerAngleCategory: AngleCategory
            if let centerAngle {
                centerAngleCategory = centerAngle <= Self.echoReturnAngleLimitDeg ? .flat : .angled
            } else {
                centerAngleCategory = .unknown
            }

            entity.components.set(ReconstructedSurfaceComponent(
                lockID: needs.lockID,
                hits: needs.hits,
                directions: needs.directions,
                centerAngleDegrees: centerAngle,
                centerAngleCategory: centerAngleCategory
            ))

            if let centerHit {
                spawnVisualPlane(at: centerHit, relativeTo: entity, in: context.scene)
            }

            entity.components.remove(NeedsSurfaceReconstruction.self)
        }
    }

    private func spawnVisualPlane(at hit: RaycastHit, relativeTo parentEntity: Entity, in scene: RealityKit.Scene) {
        guard let template = scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.surfacePlane) }).first else {
            Self.logger.error("Template '\(SceneEntityNames.surfacePlane)' tidak ditemukan di scene.")
            return
        }

        let clone = template.clone(recursive: true)
        clone.isEnabled = true
        clone.components.set(SurfacePlaneInstanceComponent())
        clone.setPosition(hit.worldPosition, relativeTo: nil)

        parentEntity.addChild(clone)
    }
    
    private func removeExistingSurfacePlane(in scene: RealityKit.Scene) {
        let query = EntityQuery(where: .has(SurfacePlaneInstanceComponent.self))
        for plane in Array(scene.performQuery(query)) {
            plane.removeFromParent()
        }
    }
}
