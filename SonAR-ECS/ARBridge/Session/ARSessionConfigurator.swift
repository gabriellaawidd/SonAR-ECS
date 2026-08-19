//
//  ARSessionConfigurator.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

//
//  ARSessionConfigurator.swift
//  SonAR-ECS
//

import ARKit
import RealityKit

enum ARSessionConfigurator {
    static func run(on arView: ARView) -> Bool {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("[ARSession] Perangkat tidak mendukung world tracking.")
            return false
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(
            configuration,
            options: [.resetTracking, .removeExistingAnchors]
        )
        return true
    }
}
