//
//  RealityKitRegistry.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 13/08/26.
//

import RealityKit
import SonARAssets

enum RealityKitRegistry {
    static func registerAll() {
        WavePropertiesComponent.registerComponent()
    }
}
