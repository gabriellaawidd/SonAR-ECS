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
    private static var cyanMaterial: SimpleMaterial?
    private static var greenMaterial: SimpleMaterial?
    private static var redMaterial: SimpleMaterial?
    private static var decalMaterial: SimpleMaterial?
    
    private static var availableArrows: [Entity] = []
    private static var availableDecals: [ModelEntity] = []
    private static var cachedDecalMesh: MeshResource?

    static func configure(scene: RealityKit.Scene) {
        if let template = scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.arrowTemplate) }).first {
            template.isEnabled = false
            template.generateCollisionShapes(recursive: true)
            cachedArrowTemplate = template
        }
        if cachedDecalMesh == nil {
            cachedDecalMesh = MeshResource.generateCylinder(height: 0.001, radius: 0.0035)
        }
    }

    private static func applyColor(to entity: Entity, color: UIColor, opacity: Float) {
        if var model = entity.components[ModelComponent.self] {
            let mat: SimpleMaterial
            if color == .cyan {
                if cyanMaterial == nil {
                    cyanMaterial = SimpleMaterial(color: color.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
                    cyanMaterial?.roughness = .float(0.3)
                }
                mat = cyanMaterial!
            } else if color == .green {
                if greenMaterial == nil {
                    greenMaterial = SimpleMaterial(color: color.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
                    greenMaterial?.roughness = .float(0.3)
                }
                mat = greenMaterial!
            } else if color == .red {
                if redMaterial == nil {
                    redMaterial = SimpleMaterial(color: color.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
                    redMaterial?.roughness = .float(0.3)
                }
                mat = redMaterial!
            } else {
                mat = SimpleMaterial(color: color.withAlphaComponent(CGFloat(opacity)), isMetallic: false)
            }
            model.materials = [mat]
            entity.components.set(model)
        }
        for child in entity.children {
            applyColor(to: child, color: color, opacity: opacity)
        }
    }

    private static func makeArrowFromRCP(color: UIColor, opacity: Float) -> Entity? {
        let clone: Entity
        if let pooledArrow = availableArrows.popLast() {
            clone = pooledArrow
        } else {
            guard let template = cachedArrowTemplate else { return nil }
            clone = template.clone(recursive: true)
        }

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
        opacity: Float = 1.0,
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
        let hitScale = scale > 1e-4 ? 0.08 / scale : 0.08
        pulse.components.set(CollisionComponent(
            shapes: [.generateSphere(radius: hitScale)]
        ))
        if pulse.parent != anchor {
            pulse.removeFromParent()
            anchor.addChild(pulse)
        }

        let targetPosition = anchor.convert(position: end, from: nil)
        var targetTransform = pulse.transform
        targetTransform.translation = targetPosition

        pulse.move(to: targetTransform, relativeTo: anchor, duration: duration, timingFunction: .linear)

        WaveSimulationSystem.scheduleAction(after: duration) {
            pulse.isEnabled = false
            availableArrows.append(pulse)
        }
    }

    static func spawnHitDecal(at position: SIMD3<Float>, normal: SIMD3<Float>, anchor: AnchorEntity) {
        if decalMaterial == nil {
            decalMaterial = SimpleMaterial(color: UIColor.black.withAlphaComponent(0.35), isMetallic: false)
        }

        let decal: ModelEntity
        if let pooledDecal = availableDecals.popLast() {
            decal = pooledDecal
        } else {
            guard let mesh = cachedDecalMesh else { return }
            decal = ModelEntity(mesh: mesh, materials: [decalMaterial!])
        }

        decal.isEnabled = true
        decal.scale = [1.0, 1.0, 1.0]

        if decal.parent != anchor {
            decal.removeFromParent()
            anchor.addChild(decal)
        }

        decal.position = anchor.convert(position: position + normal * 0.002, from: nil)
        decal.orientation = simd_quatf(from: [0, 1, 0], to: normal)

        WaveSimulationSystem.scheduleAction(after: 0.5) {
            var targetTransform = decal.transform
            targetTransform.scale = [0.01, 0.01, 0.01]
            decal.move(to: targetTransform, relativeTo: decal.parent, duration: 0.2, timingFunction: .easeOut)
        }

        WaveSimulationSystem.scheduleAction(after: 0.7) {
            decal.isEnabled = false
            availableDecals.append(decal)
        }
    }
}
