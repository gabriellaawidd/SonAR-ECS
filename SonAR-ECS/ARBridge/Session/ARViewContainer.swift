//
//  ARViewContainer.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARSessionMode
    var onPlacementReady: ((PlacementService) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        guard ARSessionConfigurator.run(on: arView) else {
            return arView
        }

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        arView.session.delegate = context.coordinator
        context.coordinator.scene = arView.scene

        Task {
            await ARSceneSetup.setup(arView: arView)

            let guidedBridge = ARGuidedBridge(scene: arView.scene, mode: mode)
            context.coordinator.guidedBridge = guidedBridge

            let placementService = PlacementService(arView: arView, guidedBridge: guidedBridge)
            context.coordinator.placementService = placementService

            onPlacementReady?(placementService)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if case .freeExplore(let freeExploreViewModel) = mode {
            context.coordinator.guidedBridge?.switchToFreeExplore(freeExploreViewModel)
        }
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        var placementService: PlacementService?
        var guidedBridge: ARGuidedBridge?
        var scene: RealityKit.Scene?
        private var hasRevealedSensor = false

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard !hasRevealedSensor else { return }
            hasRevealedSensor = true
            
            // Unhide sensor once we have actual camera frames
            if let sensor = scene?.findEntity(named: "SensorContainer") ?? scene?.findEntity(named: "SensorNode") {
                sensor.isEnabled = true
            }
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let point = recognizer.location(in: arView)

            Task {
                guard let placementService = self.placementService else { return }

                let markerHandled = await placementService.handleMarkerTap(at: point)
                if !markerHandled {
                    await placementService.handleTap(at: point)
                }
            }
        }
    }
}
