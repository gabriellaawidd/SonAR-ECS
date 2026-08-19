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

    private static let appearanceDuration: TimeInterval = 0.55
    private static let disappearanceDuration: TimeInterval = 0.30
    private static let hintCardName = "robotHintCard"

    private static let robotScale: Float = 0.45
    private static let cardWidth: Float = 0.56

    private static let hoverBobAmplitude: Float = 0.004
    private static let hoverBobPeriod: TimeInterval = 1.6
    private static let hoverScalePulse: Float = 0.012

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

            let mascotNode = entity.parent
            let card = mascotNode?.findEntity(named: Self.hintCardName)

            switch anim.stage {
            case .appearing:
                let t = min(Float(anim.elapsed / Self.appearanceDuration), 1)
                let eased = Self.easeOutBack(t)
                entity.scale = SIMD3<Float>(repeating: eased * Self.robotScale)
                card?.scale = SIMD3<Float>(repeating: eased)

                if anim.elapsed >= Self.appearanceDuration {
                    anim.stage = .hovering
                    anim.elapsed = 0
                    anim.hoverElapsed = 0
                }

            case .hovering:
                anim.hoverElapsed += TimeInterval(context.deltaTime)
                let phase = Float(anim.hoverElapsed) * (2 * .pi / Float(Self.hoverBobPeriod))

                let bob = sin(phase) * Self.hoverBobAmplitude
                mascotNode?.setPosition(
                    anim.baseWorldPosition + SIMD3<Float>(0, bob, 0),
                    relativeTo: nil
                )

                let pulse = 1 + Self.hoverScalePulse * sin(phase)
                entity.scale = SIMD3<Float>(repeating: Self.robotScale * pulse)
                card?.scale = SIMD3<Float>(repeating: pulse)

            case .leaving:
                mascotNode?.setPosition(anim.baseWorldPosition, relativeTo: nil)

                let t = min(Float(anim.elapsed / Self.disappearanceDuration), 1)
                let eased = 1 - Self.easeIn(t)
                entity.scale = SIMD3<Float>(repeating: eased * Self.robotScale)
                card?.scale = SIMD3<Float>(repeating: eased)

                if anim.elapsed >= Self.disappearanceDuration {
                    card?.removeFromParent()
                    entity.isEnabled = false
                    entity.components.remove(MascotAnimationComponent.self)
                    continue
                }
            }

            entity.components[MascotAnimationComponent.self] = anim
        }
    }

    private func beginAppearing(_ entity: Entity, content: FeedbackPresentation) {
        entity.isEnabled = true
        entity.scale = SIMD3<Float>(repeating: 0.001)

        entity.position = .zero

        var baseWorldPosition = entity.position(relativeTo: nil)

        if let mascotNode = entity.parent,
           let sensorContainer = Self.placedSensor(startingFrom: mascotNode) {

            let worldUp = SIMD3<Float>(0, 1, 0)

            let sensorWorldPos = sensorContainer.position(relativeTo: nil)
            let sensorWorldOrientation = sensorContainer.orientation(relativeTo: nil)
            let sensorForward = sensorWorldOrientation.act(SIMD3<Float>(0, 0, -1))
            let towardsUser = -sensorForward
            let userRight = simd_normalize(simd_cross(towardsUser, worldUp))

            let mascotWorldPos = sensorWorldPos
                - towardsUser * 0.07
                - userRight * 0.07
                + worldUp * 0.05

            mascotNode.setPosition(mascotWorldPos, relativeTo: nil)
            baseWorldPosition = mascotWorldPos

            let fwd = simd_normalize(towardsUser)
            let right = simd_normalize(simd_cross(worldUp, fwd))
            let up = simd_cross(fwd, right)
            let desiredWorldOrientation = simd_quatf(simd_float3x3(right, up, fwd))
            mascotNode.setOrientation(desiredWorldOrientation, relativeTo: nil)

            mascotNode.components.set(CustomBillboardComponent(
                maxPitchDegrees: 45,
                pitchSofteningFactor: 1.0,
                smoothing: 0.12,
                facesPositiveZ: true
            ))

            attachHintCard(content, mascotNode: mascotNode)
        }

        var anim = MascotAnimationComponent(stage: .appearing, currentContent: content)
        anim.baseWorldPosition = baseWorldPosition
        entity.components.set(anim)
    }

    private static func placedSensor(startingFrom node: Entity) -> Entity? {
        var probe: Entity? = node
        while let current = probe {
            if current.components[SensorStateComponent.self] != nil {
                return current
            }
            probe = current.parent
        }
        return node.parent
    }

    private func attachHintCard(_ content: FeedbackPresentation, mascotNode: Entity) {
        guard let textAnchor = mascotNode.findEntity(named: SceneEntityNames.textAnchor)
                ?? mascotNode.findEntity(named: "TextAnchor") else { return }

        textAnchor.children.filter { $0.name == Self.hintCardName }.forEach { $0.removeFromParent() }

        textAnchor.position = SIMD3<Float>(-0.52, 0.34, 0)

        guard let card = RobotHintCard.makeEntity(for: content, width: Self.cardWidth) else { return }
        card.position = .zero
        card.scale = SIMD3<Float>(repeating: 0.001)
        textAnchor.addChild(card)
    }

    private static func easeOut(_ t: Float) -> Float { 1 - pow(1 - t, 3) }
    private static func easeIn(_ t: Float) -> Float { t * t * t }

    private static func easeOutBack(_ t: Float) -> Float {
        let c1: Float = 0.9
        let c3 = c1 + 1
        let p = t - 1
        return 1 + c3 * p * p * p + c1 * p * p
    }
}
