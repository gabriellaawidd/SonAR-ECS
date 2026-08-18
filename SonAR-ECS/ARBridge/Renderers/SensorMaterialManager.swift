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

    static let hologramMaterial: RealityKit.Material = {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.48))
        mat.metallic = .float(0.0)
        mat.roughness = .float(0.2)
        return mat
    }()

    /// Ubah semua mesh sensor menjadi Hologram Biru Transparan
    static func applyHologram(to entity: Entity) {
        applyRecursively(to: entity, isHologram: true)
    }

    static func restoreOriginal(to entity: Entity) {
        applyRecursively(to: entity, isHologram: false)
    }

    private static func applyRecursively(to entity: Entity, isHologram: Bool) {
        if entity.name == SceneEntityNames.mascotNode
            || entity.name == SceneEntityNames.robotMascot
            || entity.name == "MascotNode"
            || entity.name == "robot_mascot" {
            return
        }

        if var modelComponent = entity.components[ModelComponent.self] {
            let id = ObjectIdentifier(entity)
            if isHologram {
                if originalMaterials[id] == nil {
                    originalMaterials[id] = modelComponent.materials
                }
                modelComponent.materials = [hologramMaterial]
            } else {
                if let original = originalMaterials[id] {
                    modelComponent.materials = original
                }
            }
            entity.components.set(modelComponent)
        }

        for child in entity.children {
            applyRecursively(to: child, isHologram: isHologram)
        }
    }
}
