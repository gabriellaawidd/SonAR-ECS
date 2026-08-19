//
//  AmbientIntensity.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 19/08/26.
//

import ARKit
import RealityKit

extension ARView {
    private static let lowLightThreshold: Double = 400
    private static let lowLightExponent: Float = 0.5

    func adjustLightingForAmbient(frame: ARFrame) {
        guard let ambientIntensity = frame.lightEstimate?.ambientIntensity else { return }

        environment.lighting.intensityExponent =
            ambientIntensity < Self.lowLightThreshold ? Self.lowLightExponent : 1.0
    }
}
