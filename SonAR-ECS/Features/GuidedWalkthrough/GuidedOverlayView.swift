//
//  GuidedOverlayView.swift
//  SonAR-ECS
//

import SwiftUI

struct GuidedOverlayView: View {
    let step: GuidedStep

    let onHome: () -> Void
    let onHowItWorks: () -> Void
    let onContinue: () -> Void
    let onRetry: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ToolBarView(onHome: onHome, onHowItWorks: onHowItWorks)

            stepContent
                .allowsHitTesting(false)

            Spacer(minLength: 0)

            footer
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.28), value: step)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .placePrompt(let prompt):
            MascotPromptView(
                mascot: prompt.mascot,
                text: prompt.bubbleText,
                mascotHeight: prompt.mascotHeight
            )
            .padding(.top, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))

        case .retry(let reason):
            MascotPromptView(
                mascot: reason.mascot,
                text: reason.bubbleText,
                mascotHeight: reason.mascotHeight
            )
            .padding(.top, 12)
            .transition(.opacity)

        case .feedback:
            EmptyView()

        case .finale:
            MascotPromptView(
                mascot: MascotAsset.neutral,
                text: GuidedCopy.finale,
                mascotHeight: 120
            )
            .padding(.top, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var footer: some View {
        Group {
            switch step {
            case .placePrompt(let prompt):
                HintCapsule(text: prompt.footerHint)
                    .allowsHitTesting(false)

            case .retry(let reason):
                CapsuleActionButton(title: reason.actionTitle, action: onRetry)

            case .feedback:
                CapsuleActionButton(title: GuidedCopy.continueTitle, action: onContinue)

            case .finale:
                CapsuleActionButton(title: GuidedCopy.exploreTitle, action: onFinish)
            }
        }
        .padding(.bottom, 32)
        .transition(.opacity)
    }
}

#Preview("Guided Overlay") {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        GuidedOverlayView(
            step: .placePrompt(.findFlat),
            onHome: {},
            onHowItWorks: {},
            onContinue: {},
            onRetry: {},
            onFinish: {}
        )
    }
}