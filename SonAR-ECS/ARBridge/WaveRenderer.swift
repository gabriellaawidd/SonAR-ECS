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
    private static let arrowTemplateName = "ArrowTemplate"
    private static var cachedArrowTemplate: Entity?

    private static let pulseRadius: Float = 0.003
    private static var cachedDecalMesh: MeshResource?
    private static var cachedDecalMaterial: PhysicallyBasedMaterial?
    private static var cachedDecalTemplate: ModelEntity?

    /// Dipanggil SEKALI, di titik setup (misal dari SurfaceReconstructionSystem
    /// atau ECSBootstrap-adjacent code) yang punya akses ke scene.
    static func configure(scene: RealityKit.Scene) {
        cachedArrowTemplate = scene.findEntity(named: arrowTemplateName)
    }

    private static func makeArrow(color: UIColor, opacity: Float) -> Entity? {
        guard let template = cachedArrowTemplate else { return nil }
        let clone = template.clone(recursive: true)

        // Timpa material binding "Hologram" dengan warna solid sesuai outcome.
        if var model = clone.components[ModelComponent.self] {
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: color.withAlphaComponent(CGFloat(opacity)))
            material.emissiveColor = .init(color: color)
            material.emissiveIntensity = 0.5
            material.roughness = 0.6
            material.metallic = 0.0
            if opacity < 1.0 {
                material.blending = .transparent(opacity: .init(floatLiteral: opacity))
            }
            model.materials = [material]
            clone.components.set(model)
        }

        return clone
    }

    static func spawnPulse(
        color: UIColor, from start: SIMD3<Float>, to end: SIMD3<Float>, anchor: AnchorEntity, duration: TimeInterval,
        opacity: Float = 1.0, scale: Float = 1.0
    ) {
        if simd_distance(start, end) < 0.001 { return }
        guard let arrowContainer = makeArrow(color: color, opacity: opacity) else { return }

        arrowContainer.setPosition(start, relativeTo: nil)
        arrowContainer.look(at: end, from: start, relativeTo: nil)
        arrowContainer.scale = [scale, scale, scale]

        anchor.addChild(arrowContainer)

        var targetTransform = arrowContainer.transform
        targetTransform.translation = anchor.convert(position: end, from: nil)
        arrowContainer.move(to: targetTransform, relativeTo: anchor, duration: duration, timingFunction: .linear)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            arrowContainer.removeFromParent()
        }
    }

    // Decal tetap procedural — sudah efisien (cached mesh+material, generate
    // sekali dipakai berkali-kali lewat clone), gak ada perubahan pendekatan.
    private static func getDecalTemplate() -> ModelEntity {
        if let cached = cachedDecalTemplate { return cached.clone(recursive: true) }

        if cachedDecalMesh == nil {
            cachedDecalMesh = MeshResource.generateCylinder(height: 0.001, radius: pulseRadius * 1.75 * 0.5)
        }
        if cachedDecalMaterial == nil {
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: UIColor.gray.withAlphaComponent(0.6))
            material.roughness = 0.9
            material.metallic = 0.0
            material.blending = .transparent(opacity: .init(floatLiteral: 0.6))
            cachedDecalMaterial = material
        }

        let decal = ModelEntity(mesh: cachedDecalMesh!, materials: [cachedDecalMaterial!])
        cachedDecalTemplate = decal
        return decal.clone(recursive: true)
    }

    static func spawnHitDecal(at position: SIMD3<Float>, normal: SIMD3<Float>, anchor: AnchorEntity) {
        let decal = getDecalTemplate()

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