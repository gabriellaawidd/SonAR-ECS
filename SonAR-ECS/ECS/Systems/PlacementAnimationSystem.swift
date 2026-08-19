//
//  PlacementAnimationSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import simd
import Foundation

struct PlacementAnimationSystem: System {
    private static let query = EntityQuery(where: .has(PlacementAnimationComponent.self))
    private static let baseScale: Float = 0.12

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        typealias S = PlacementSolver.Settle

        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var anim = entity.components[PlacementAnimationComponent.self] else { continue }

            let facing = PlacementSolver.facingDirection(of: anim.finalOrientation)
            let towardUser = -facing

            switch anim.phase {
            case .launch:
                let startPosition = anim.finalPosition + towardUser * S.launchBackset
                let startOrientation = anim.finalOrientation * simd_quatf(angle: S.launchTilt, axis: SIMD3<Float>(1, 0, 0))
                let overshootPosition = anim.finalPosition + facing * S.overshoot

                anim.elapsedInPhase += TimeInterval(context.deltaTime)
                let t = min(Float(anim.elapsedInPhase / anim.launchDuration), 1)
                let eased = Self.easeOut(t)

                entity.position = simd_mix(startPosition, overshootPosition, SIMD3<Float>(repeating: eased))
                entity.orientation = simd_slerp(startOrientation, anim.finalOrientation, eased)
                entity.scale = SIMD3<Float>(repeating: (S.launchScale + (S.overshootScale - S.launchScale) * eased) * Self.baseScale)

                if anim.elapsedInPhase >= anim.launchDuration {
                    anim.phase = .settle
                    anim.elapsedInPhase = 0
                }

            case .settle:
                let overshootPosition = anim.finalPosition + facing * S.overshoot

                anim.elapsedInPhase += TimeInterval(context.deltaTime)
                let t = min(Float(anim.elapsedInPhase / anim.settleDuration), 1)
                let eased = Self.easeInOut(t)

                entity.position = simd_mix(overshootPosition, anim.finalPosition, SIMD3<Float>(repeating: eased))
                entity.orientation = anim.finalOrientation
                entity.scale = SIMD3<Float>(repeating: (S.overshootScale + (1.0 - S.overshootScale) * eased) * Self.baseScale)

                if anim.elapsedInPhase >= anim.settleDuration {
                    anim.phase = .finished
                }

            case .finished:
                entity.position = anim.finalPosition
                entity.orientation = anim.finalOrientation
                entity.scale = SIMD3<Float>(repeating: Self.baseScale)
                entity.components.remove(PlacementAnimationComponent.self)
                continue
            }

            entity.components[PlacementAnimationComponent.self] = anim
        }
    }

    private static func easeOut(_ t: Float) -> Float {
        sin(t * .pi / 2)
    }

    private static func easeInOut(_ t: Float) -> Float {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}
