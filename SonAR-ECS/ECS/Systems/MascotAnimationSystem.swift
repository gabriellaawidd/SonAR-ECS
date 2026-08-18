//
//  MascotAnimationSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import simd
import Foundation

struct MascotAnimationSystem: System {
    private static let needsFeedbackQuery = EntityQuery(where: .has(NeedsMascotFeedback.self))
    private static let animatingQuery = EntityQuery(where: .has(MascotAnimationComponent.self))

    private static let appearanceDuration: TimeInterval = 0.5
    private static let disappearanceDuration: TimeInterval = 0.3
    private static let hintCardName = "robotHintCard"

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.needsFeedbackQuery, updatingSystemWhen: .rendering) {
            guard let needs = entity.components[NeedsMascotFeedback.self] else { continue }
            beginAppearing(entity, content: needs.content)
            entity.components.remove(NeedsMascotFeedback.self)
        }

        for entity in context.entities(matching: Self.animatingQuery, updatingSystemWhen: .rendering) {
            guard var anim = entity.components[MascotAnimationComponent.self] else { continue }
            anim.elapsed += TimeInterval(context.deltaTime)

            switch anim.stage {
            case .appearing:
                let t = min(Float(anim.elapsed / Self.appearanceDuration), 1)
                let eased = Self.easeOut(t)
                entity.scale = SIMD3<Float>(repeating: eased * 0.5)

                if anim.elapsed >= Self.appearanceDuration {
                    anim.stage = .hovering
                    anim.elapsed = 0
                }

            case .hovering:
                break

            case .leaving:
                let t = min(Float(anim.elapsed / Self.disappearanceDuration), 1)
                let eased = Self.easeIn(t)
                entity.scale = SIMD3<Float>(repeating: (1 - eased) * 0.5)

                if anim.elapsed >= Self.disappearanceDuration {
                    entity.isEnabled = false
                    entity.components.remove(MascotAnimationComponent.self)
                    entity.components.remove(BobbingComponent.self)
                    continue
                }
            }

            entity.components[MascotAnimationComponent.self] = anim
        }
    }

    private func beginAppearing(_ entity: Entity, content: FeedbackPresentation) {
        entity.isEnabled = true
        entity.scale = SIMD3<Float>(repeating: 0.001)

        if let mascotNode = entity.parent,
           let sensorContainer = mascotNode.parent {

            let sensorWorldPos = sensorContainer.position(relativeTo: nil)
            let sensorWorldOrientation = sensorContainer.orientation(relativeTo: nil)

            let sensorForward = sensorWorldOrientation.act(SIMD3<Float>(0, 0, -1))
            let towardsUser = -sensorForward
            let worldUp = SIMD3<Float>(0, 1, 0)
            let userRight = simd_normalize(simd_cross(towardsUser, worldUp))

            let mascotWorldPos = sensorWorldPos
                + towardsUser * 0.06
                + userRight * 0.03
                + worldUp * 0.04

            mascotNode.position = sensorContainer.convert(position: mascotWorldPos, from: nil)

            let fwd = simd_normalize(towardsUser)
            let right = simd_normalize(simd_cross(worldUp, fwd))
            let up = simd_cross(fwd, right)
            let desiredWorldOrientation = simd_quatf(simd_float3x3(right, up, fwd))
            mascotNode.orientation = simd_inverse(sensorWorldOrientation) * desiredWorldOrientation

            mascotNode.components.set(CustomBillboardComponent(facesPositiveZ: true))

            attachHintCard(content, mascotNode: mascotNode, robotEntity: entity)
        }

        entity.components.set(MascotAnimationComponent(stage: .appearing, currentContent: content))
    }

    private func attachHintCard(_ content: FeedbackPresentation, mascotNode: Entity, robotEntity: Entity) {
        guard let textAnchor = mascotNode.findEntity(named: SceneEntityNames.textAnchor)
                ?? mascotNode.findEntity(named: "TextAnchor") else { return }

        textAnchor.children.filter { $0.name == Self.hintCardName }.forEach { $0.removeFromParent() }

        let robotPos = robotEntity.position
        textAnchor.position = SIMD3<Float>(robotPos.x - 0.40, robotPos.y + 0.28, robotPos.z)

        guard let card = RobotHintCard.makeEntity(for: content, width: 0.40) else { return }
        card.position = .zero
        textAnchor.addChild(card)
    }

    private static func easeOut(_ t: Float) -> Float { 1 - pow(1 - t, 3) }
    private static func easeIn(_ t: Float) -> Float { t * t * t }
}
