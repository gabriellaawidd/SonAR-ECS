//
//  GuidedOverlayView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct GuidedOverlayView: View {
    let step: GuidedStep
    let isShowingInstruction: Bool
    let isCoachingActive: Bool
    let onDismissInstruction: () -> Void

    let onHome: () -> Void
    let onHowItWorks: () -> Void
    let onContinue: () -> Void
    let onRetry: () -> Void
    let onFinish: () -> Void

    @State private var showLeaveConfirm = false

    var body: some View {
        ZStack {
            if isShowingInstruction {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                ToolBarView(
                    onHome: { showLeaveConfirm = true },
                    onHowItWorks: onHowItWorks
                )

                if isShowingInstruction {
                    instructionHeader
                        .padding(.top, 40)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if case .placePrompt(let prompt) = step, !prompt.needsBriefing {
                    MascotPromptView(
                        mascot: prompt.mascot,
                        text: prompt.bubbleText,
                        mascotHeight: prompt.mascotHeight
                    )
                    .padding(.top, 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if case .retry(let reason) = step {
                    MascotPromptView(
                        mascot: reason.mascot,
                        text: reason.bubbleText,
                        mascotHeight: reason.mascotHeight
                    )
                    .padding(.top, 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if case .finale = step {
                    MascotPromptView(
                        mascot: MascotAsset.neutral,
                        text: GuidedCopy.finale,
                        mascotHeight: 120
                    )
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.28), value: isShowingInstruction)
        .animation(.easeInOut(duration: 0.28), value: step)
        .alert(
            GuidedCopy.leaveTitle,
            isPresented: $showLeaveConfirm
        ) {
            Button(GuidedCopy.leaveConfirm, role: .destructive) {
                onHome()
            }
            Button(GuidedCopy.cancel, role: .cancel) {
                showLeaveConfirm = false
            }
        } message: {
            Text(GuidedCopy.leaveMessage)
        }
    }

    @ViewBuilder
    private var instructionHeader: some View {
        if case .placePrompt(let prompt) = step {
            MascotPromptView(
                mascot: prompt.mascot,
                text: prompt.bubbleText,
                mascotHeight: prompt.mascotHeight
            )
        } else if case .retry(let reason) = step {
            MascotPromptView(
                mascot: reason.mascot,
                text: reason.bubbleText,
                mascotHeight: reason.mascotHeight
            )
        }
    }

    @ViewBuilder
    private var footer: some View {
        Group {
            if isShowingInstruction {
                CapsuleActionButton(title: "Continue", action: onDismissInstruction)
            } else {
                switch step {
                case .placePrompt(let prompt):
                    if !isCoachingActive {
                        HintCapsule(text: prompt.footerHint)
                            .allowsHitTesting(false)
                    }

                case .retry(let reason):
                    CapsuleActionButton(title: reason.actionTitle, action: onRetry)

                case .feedback:
                    CapsuleActionButton(title: GuidedCopy.continueTitle, action: onContinue)

                case .finale:
                    CapsuleActionButton(title: GuidedCopy.exploreTitle, action: onFinish)
                }
            }
        }
        .padding(.bottom, 32)
        .transition(.opacity)
    }
}

#Preview() {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        GuidedOverlayView(
            step: .placePrompt(.findFlat),
            isShowingInstruction: true,
            isCoachingActive: false,
            onDismissInstruction: {},
            onHome: {},
            onHowItWorks: {},
            onContinue: {},
            onRetry: {},
            onFinish: {}
        )
    }
}
