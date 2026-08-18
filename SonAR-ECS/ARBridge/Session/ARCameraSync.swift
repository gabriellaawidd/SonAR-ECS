//
//  ARCameraSync.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import ARKit
import RealityKit

final class ARCameraSync: NSObject, ARSessionDelegate {
    private weak var scene: RealityKit.Scene?
    private static let cameraTrackerQuery = EntityQuery(where: .has(CameraTrackingComponent.self))

    init(scene: RealityKit.Scene) {
        self.scene = scene
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let scene else { return }
        let transform = frame.camera.transform

        DispatchQueue.main.async {
            guard let cameraEntity = Array(scene.performQuery(Self.cameraTrackerQuery)).first else { return }
            var tracking = cameraEntity.components[CameraTrackingComponent.self] ?? CameraTrackingComponent()
            tracking.worldTransform = transform
            cameraEntity.components[CameraTrackingComponent.self] = tracking
        }
    }
}
