//
//  ARSceneSetup.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import ARKit
import SonARAssets

enum ARSceneSetup {

    @MainActor
    static func setup(arView: ARView) async {
        guard let mainScene = await AppSceneCache.getScene() else {
            return
        }

        let anchor = AnchorEntity(world: matrix_identity_float4x4)
        anchor.addChild(mainScene)
        arView.scene.addAnchor(anchor)

        let cameraTracker = AnchorEntity(.camera)
        cameraTracker.name = "CameraTracker"
        arView.scene.addAnchor(cameraTracker)

        configureSensor(in: mainScene)
        configureMascot(in: mainScene)

        WaveRenderer.configure(scene: arView.scene)
    }
    
    private static func configureSensor(in scene: Entity) {
        guard let sensorContainer = scene.findEntity(named: "SensorContainer")
                ?? scene.findEntity(named: SceneEntityNames.sensorNode) else {
            return
        }

        sensorContainer.scale = SIMD3<Float>(repeating: 0.12)
        sensorContainer.isEnabled = false

        sensorContainer.components.set(SensorStateComponent())
        sensorContainer.components.set(SensorPreviewComponent())
        sensorContainer.components.set(WaveEmitterComponent(pulseInterval: 1.0, elapsedSinceLastPulse: 1.0))

        if let sensor = sensorContainer.findEntity(named: "sensor") ?? sensorContainer.findEntity(named: "SensorNode") {
            SensorMaterialManager.applyHologram(to: sensor)
            sensor.generateCollisionShapes(recursive: true)
        }

        sensorContainer.components.set(CollisionComponent(
            shapes: [.generateBox(size: SIMD3<Float>(repeating: 0.6))]
        ))
    }

    private static func configureMascot(in scene: Entity) {
        guard let mascotNode = scene.findEntity(named: SceneEntityNames.mascotNode)
                ?? scene.findEntity(named: "MascotNode"),
              let robotMascot = mascotNode.findEntity(named: SceneEntityNames.robotMascot)
                ?? mascotNode.findEntity(named: "robot_mascot") else {
            return
        }

        robotMascot.isEnabled = false
    }
}
