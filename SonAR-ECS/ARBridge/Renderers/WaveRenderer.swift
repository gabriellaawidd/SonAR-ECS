//
//  WaveRenderer.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import Foundation
import RealityKit
import UIKit

enum WaveRenderer {
    private static var cachedArrowTemplate: Entity?

    static func configure(scene: RealityKit.Scene) {
        if let template = scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.arrowTemplate) }).first {
            template.isEnabled = false
            cachedArrowTemplate = template
        }
    }

    private static func applyColor(to entity: Entity, color: UIColor, opacity: Float) {
        if var model = entity.components[ModelComponent.self] {
            var material = SimpleMaterial()
            material.color = .init(tint: color.withAlphaComponent(CGFloat(opacity)))
            material.metallic = .float(0.0)
            material.roughness = .float(0.3)
            model.materials = [material]
            entity.components.set(model)
        }
        for child in entity.children {
            applyColor(to: child, color: color, opacity: opacity)
        }
    }

    private static func makeArrowFromRCP(color: UIColor, opacity: Float) -> Entity? {
        guard let template = cachedArrowTemplate else { return nil }

        let clone = template.clone(recursive: true)
        clone.isEnabled = true

        applyColor(to: clone, color: color, opacity: opacity)

        return clone
    }

    static func spawnPulse(
        color: UIColor,
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        anchor: AnchorEntity,
        duration: TimeInterval,
        opacity: Float = 0.85,
        scale: Float = 1.0
    ) {
        if simd_distance(start, end) < 0.001 { return }
        guard let pulse = makeArrowFromRCP(color: color, opacity: opacity) else { return }
        pulse.name = "wavePulse"

        pulse.position = anchor.convert(position: start, from: nil)
        pulse.look(at: end, from: start, relativeTo: nil)

        let coneFacingTarget = simd_quatf(angle: .pi / 2, axis: [-1, 0, 0])
        pulse.orientation = pulse.orientation * coneFacingTarget

        pulse.scale = SIMD3<Float>(repeating: scale)
        anchor.addChild(pulse)
        // Collision agar pulse gelombang bisa di-tap untuk memunculkan robot.
        pulse.generateCollisionShapes(recursive: true)

        let targetPosition = anchor.convert(position: end, from: nil)
        var targetTransform = pulse.transform
        targetTransform.translation = targetPosition

        pulse.move(to: targetTransform, relativeTo: anchor, duration: duration, timingFunction: .linear)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            pulse.removeFromParent()
        }
    }

    static func spawnHitDecal(at position: SIMD3<Float>, normal: SIMD3<Float>, anchor: AnchorEntity) {
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor.cyan.withAlphaComponent(0.6))

        let decal = ModelEntity(
            mesh: MeshResource.generateCylinder(height: 0.001, radius: 0.02),
            materials: [material]
        )
        decal.position = anchor.convert(position: position + normal * 0.002, from: nil)
        decal.orientation = simd_quatf(from: [0, 1, 0], to: normal)

        anchor.addChild(decal)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var targetTransform = decal.transform
            targetTransform.scale = [0.01, 0.01, 0.01]
            decal.move(to: targetTransform, relativeTo: decal.parent, duration: 0.2, timingFunction: .easeOut)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            decal.removeFromParent()
        }
    }
}
