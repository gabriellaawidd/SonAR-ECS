//
//  TransparentRealityView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI
import RealityKit
import SonARAssets

struct TransparentRealityView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.backgroundColor = .clear
        arView.environment.background = .color(.clear)

        let cameraAnchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        camera.position = [0, 0, 0.35]
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        let lightAnchor = AnchorEntity(world: .zero)
        let light = DirectionalLight()
        light.light.color = .white
        light.light.intensity = 2000
        light.look(at: [0, 0, 0], from: [0.5, 1.0, 1.0], relativeTo: nil)
        lightAnchor.addChild(light)
        arView.scene.addAnchor(lightAnchor)

        Task { @MainActor in
            var loadedScene: Entity?

            if let s = try? await Entity(named: "Models/MainScene", in: SonARAssets.sonARAssetsBundle) {
                loadedScene = s
            } else if let s = try? await Entity(named: "MainScene", in: SonARAssets.sonARAssetsBundle) {
                loadedScene = s
            }

            guard let mainScene = loadedScene,
                  let sensorNode = mainScene.findEntity(named: "SensorNode")
                    ?? mainScene.findEntity(named: "sensor")
                    ?? mainScene.findEntity(named: "SensorContainer") else { return }

            let model = sensorNode.clone(recursive: true)
            model.isEnabled = true

            let modelAnchor = AnchorEntity(world: .zero)
            
            let bounds = model.visualBounds(relativeTo: nil)
            let center = bounds.center
            model.position = -center

            let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            if maxDim > 0 {
                let targetSize: Float = 0.12
                let scaleFactor = targetSize / maxDim
                model.scale = SIMD3<Float>(repeating: scaleFactor)
            }

            modelAnchor.addChild(model)
            arView.scene.addAnchor(modelAnchor)
            
            context.coordinator.modelAnchor = modelAnchor
            context.coordinator.applyRotation(to: modelAnchor)
        }

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(panGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var modelAnchor: AnchorEntity?

        var angleX: Float = 0.0
        var angleY: Float = 0.0

        var displayLink: CADisplayLink?
        var velocity: CGPoint = .zero

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let model = modelAnchor else { return }

            if gesture.state == .began {
                displayLink?.invalidate()
                displayLink = nil
                velocity = .zero
            } else if gesture.state == .changed {
                let translation = gesture.translation(in: view)
                
                angleY += Float(translation.x) * 0.01
                angleX += Float(translation.y) * 0.01
                applyRotation(to: model)

                gesture.setTranslation(.zero, in: view)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                let gestureVelocity = gesture.velocity(in: view)
                velocity = CGPoint(x: gestureVelocity.x * 0.0002, y: gestureVelocity.y * 0.0002)

                displayLink = CADisplayLink(target: self, selector: #selector(applyMomentum))
                displayLink?.add(to: .main, forMode: .common)
            }
        }

        @objc func applyMomentum() {
            guard let model = modelAnchor else { return }

            angleY += Float(velocity.x)
            angleX += Float(velocity.y)
            applyRotation(to: model)

            velocity.x *= 0.92
            velocity.y *= 0.92

            if abs(velocity.x) < 0.0001 && abs(velocity.y) < 0.0001 {
                displayLink?.invalidate()
                displayLink = nil
            }
        }

        func applyRotation(to model: Entity) {
            let baseRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            let rotationY = simd_quatf(angle: angleY, axis: [0, 1, 0])
            let rotationX = simd_quatf(angle: angleX, axis: [1, 0, 0])
            model.transform.rotation = rotationY * rotationX * baseRotation
        }

        deinit {
            displayLink?.invalidate()
        }
    }
}

#Preview() {
    ZStack {
        Color("bgMain").ignoresSafeArea()
        TransparentRealityView()
            .frame(width: 250, height: 250)
    }
}
