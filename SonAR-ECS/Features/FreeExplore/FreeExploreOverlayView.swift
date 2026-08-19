//
//  FreeExploreCopy.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

enum FreeExploreCopy {
    static let placePrompt = "Place your sensor to begin exploring."
    static let tapHint = "Tap anywhere to place"
    static let reposition = "Reposition Sensor"
    static let leaveTitle = "Back to Menu?"
    static let leaveMessage = "Do you want to stop exploring and go back home?"
    static let leaveConfirm = "Go Home"
    static let cancel = "Cancel"
}

struct FreeExploreOverlayView: View {
    let showIntro: Bool
    let isPlaced: Bool
    let onDismissIntro: () -> Void
    let onHome: () -> Void
    let onHowItWorks: () -> Void
    let onReposition: () -> Void

    @State private var showLeaveConfirm = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ToolBarView(
                    onHome: { showLeaveConfirm = true },
                    onHowItWorks: onHowItWorks
                )

                if !isPlaced {
                    MascotPromptView(
                        mascot: MascotAsset.neutral,
                        text: FreeExploreCopy.placePrompt,
                        mascotHeight: 120
                    )
                    .padding(.top, 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer(minLength: 0)

                Group {
                    if !isPlaced {
                        HintCapsule(text: FreeExploreCopy.tapHint)
                            .allowsHitTesting(false)
                    } else {
                        CapsuleActionButton(title: FreeExploreCopy.reposition, action: onReposition)
                    }
                }
                .padding(.bottom, 32)
                .transition(.opacity)
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.28), value: isPlaced)
        .alert(
            FreeExploreCopy.leaveTitle,
            isPresented: $showLeaveConfirm
        ) {
            Button(FreeExploreCopy.leaveConfirm, role: .destructive) {
                onHome()
            }
            Button(FreeExploreCopy.cancel, role: .cancel) {
                showLeaveConfirm = false
            }
        } message: {
            Text(FreeExploreCopy.leaveMessage)
        }
    }
}

#Preview("Free Explore Overlay") {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        FreeExploreOverlayView(
            showIntro: true,
            isPlaced: false,
            onDismissIntro: {},
            onHome: {},
            onHowItWorks: {},
            onReposition: {}
        )
    }
}
