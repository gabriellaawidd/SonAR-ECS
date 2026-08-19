import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARSessionMode
    @Binding var isCoachingActive: Bool
    var onPlacementReady: ((PlacementService) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(isCoachingActive: $isCoachingActive)
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

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .tracking
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.delegate = context.coordinator
        arView.addSubview(coachingOverlay)

        context.coordinator.coachingOverlay = coachingOverlay
        context.coordinator.arView = arView
        context.coordinator.scene = arView.scene
        arView.session.delegate = context.coordinator

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

    final class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        weak var arView: ARView?
        weak var coachingOverlay: ARCoachingOverlayView?
        var placementService: PlacementService?
        var guidedBridge: ARGuidedBridge?
        var scene: RealityKit.Scene?
        private var hasRevealedSensor = false

        @Binding var isCoachingActive: Bool
        private let darkThreshold: Double = 350.0

        init(isCoachingActive: Binding<Bool>) {
            self._isCoachingActive = isCoachingActive
        }

        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                self.isCoachingActive = true
                self.placementService?.isCoachingActive = true
            }
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                self.isCoachingActive = false
                self.placementService?.isCoachingActive = false
            }
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            arView?.adjustLightingForAmbient(frame: frame)

            if let ambient = frame.lightEstimate?.ambientIntensity {
                let isTooDark = ambient < darkThreshold
                if isTooDark && !(coachingOverlay?.isActive ?? false) {
                    coachingOverlay?.setActive(true, animated: true)
                }
            }

            guard !hasRevealedSensor else { return }
            hasRevealedSensor = true

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
