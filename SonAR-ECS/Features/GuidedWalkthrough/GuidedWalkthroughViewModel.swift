//
//  GuidedWalkthroughViewModel.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import Foundation

@MainActor
@Observable
final class GuidedWalkthroughViewModel {

    private(set) var step: GuidedStep = .placePrompt(.findFlat)
    private(set) var progress = GuidedProgress()
    private(set) var feedback: FeedbackPresentation?
    var isShowingInstruction: Bool = true

    @ObservationIgnored weak var bridge: ARGuidedBridge?
    @ObservationIgnored private var isAdvancing = false
    @ObservationIgnored var onFinished: (() -> Void)?

    private static let robotExitDuration: Duration = .milliseconds(450)

    var helpText: String { step.helpText }

    func dismissInstruction() {
        isShowingInstruction = false
    }

    func applyLesson(_ lesson: GuidedLesson, presentation: FeedbackPresentation) {
        feedback = presentation
        step = .feedback(lesson)
    }

    func applyRetry(_ reason: GuidedRetryReason) {
        step = .retry(reason)
    }

    func recordOutcome(_ outcome: PlacementOutcome) -> GuidedResolution {
        progress.record(outcome)
    }

    func homeTapped(onExit: () -> Void) {
        bridge?.dismissFeedbackRobot()
        onExit()
    }

    func continueTapped() {
        advanceFromFeedback()
    }

    func retryTapped() {
        bridge?.dismissFeedbackRobot()
        bridge?.placeAgain()
        step = .placePrompt(progress.prompt)
        isShowingInstruction = true
    }

    func restart() {
        progress.reset()
        isAdvancing = false
        feedback = nil
        step = .placePrompt(progress.prompt)
        isShowingInstruction = true
        bridge?.dismissFeedbackRobot()
        bridge?.placeAgain()
    }

    private func advanceFromFeedback() {
        guard !isAdvancing else { return }
        isAdvancing = true
        bridge?.dismissFeedbackRobot()

        Task { [weak self] in
            try? await Task.sleep(for: Self.robotExitDuration)
            guard let self else { return }
            self.isAdvancing = false
            self.feedback = nil

            if self.progress.isFinished {
                self.step = .finale
                self.onFinished?()
            } else {
                self.step = .placePrompt(self.progress.prompt)
                self.isShowingInstruction = true
                self.bridge?.placeAgain()
            }
        }
    }
}
