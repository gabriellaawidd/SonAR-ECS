//
//  SensorMaterialManager.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//


//
//  SensorMaterialManager.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import RealityKit
import UIKit

enum SensorMaterialManager {
    private static var originalMaterials: [ObjectIdentifier: [RealityKit.Material]] = [:]

    // ✨ Material Hologram: Cyan Semi-Transparan Bercahaya
    static let hologramMaterial: RealityKit.Material = {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.48))
        mat.metallic = .float(0.0)
        mat.roughness = .float(0.2)
        return mat
    }()

    /// Ubah semua bagian mesh sensor menjadi Hologram Biru Transparan
    static func applyHologram(to entity: Entity) {
        applyRecursively(to: entity, isHologram: true)
    }

    /// Kembalikan tekstur sensor menjadi model fisik padat/asli
    static func restoreOriginal(to entity: Entity) {
        applyRecursively(to: entity, isHologram: false)
    }

    private static func applyRecursively(to entity: Entity, isHologram: Bool) {
        if var model = entity as? ModelEntity {
            let id = ObjectIdentifier(model)
            if isHologram {
                if originalMaterials[id] == nil, let current = model.model?.materials {
                    originalMaterials[id] = current
                }
                model.model?.materials = [hologramMaterial]
            } else {
                if let original = originalMaterials[id] {
                    model.model?.materials = original
                }
            }
        }
        for child in entity.children {
            applyRecursively(to: child, isHologram: isHologram)
        }
    }
}