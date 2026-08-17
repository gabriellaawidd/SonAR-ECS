import Foundation
import RealityKit
import Combine

@MainActor
final class ARGuidedBridge {
    private weak var scene: RealityKit.Scene?
    private let viewModel: GuidedWalkthroughViewModel
    private var cancellable: AnyCancellable?
    private var hasEvaluatedCurrentPlacement = false

    init(scene: RealityKit.Scene, viewModel: GuidedWalkthroughViewModel) {
        self.scene = scene
        self.viewModel = viewModel
        subscribe()
    }

    private func subscribe() {
        cancellable = AREventBus.shared.pulseCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                self?.handlePulse(report)
            }
    }

    func beginMeasurement() {
        hasEvaluatedCurrentPlacement = false
    }

    private func handlePulse(_ report: PulseReport) {
        guard !hasEvaluatedCurrentPlacement else { return }
        hasEvaluatedCurrentPlacement = true

        guard let scene, let sensor = scene.findEntity(named: SceneEntityNames.sensorNode),
              let surface = sensor.components[ReconstructedSurfaceComponent.self] else { return }

        let outcome: PlacementOutcome
        if viewModel.progress.usesMaterialDetection, surface.materialCategory == .soft {
            outcome = .absorbed
        } else {
            outcome = report.isBounceBack ? .bounceBack : .bounceAway
        }

        if viewModel.progress.isFinished {
            let lesson = outcome.guidedLesson
            let presentation = FeedbackPresentation(lesson: lesson, report: report)
            guard let centerHit = surface.hits.first ?? nil else { return }
            sensor.components.set(NeedsAnnotationDisplay(hitPosition: centerHit.worldPosition, content: presentation))
        } else {
            let resolution = viewModel.progress.record(outcome)
            switch resolution {
            case .lesson(let lesson):
                let presentation = FeedbackPresentation(lesson: lesson, report: report)
                viewModel.feedback = presentation
                viewModel.step = .feedback(lesson)
                sendMascotFeedback(presentation)
            case .retry(let reason):
                viewModel.step = .retry(reason)
            }
        }
    }

    private func sendMascotFeedback(_ content: FeedbackPresentation) {
        guard let scene,
              let mascotNode = scene.findEntity(named: SceneEntityNames.mascotNode),
              let robotMascot = mascotNode.findEntity(named: SceneEntityNames.robotMascot) else { return }
        robotMascot.components.set(NeedsMascotFeedback(content: content))
    }
}