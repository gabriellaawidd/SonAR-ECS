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
}

struct FreeExploreOverlayView: View {
    let onHome: () -> Void
    let onHowItWorks: () -> Void
    let onReposition: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ToolBarView(
                onHome: onHome,
                onHowItWorks: onHowItWorks
            )

            MascotPromptView(
                mascot: MascotAsset.neutral,
                text: FreeExploreCopy.placePrompt,
                mascotHeight: 120
            )
            .padding(.top, 12)
            .allowsHitTesting(false)

            Spacer(minLength: 0)

            CapsuleActionButton(title: FreeExploreCopy.reposition, action: onReposition)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
    }
}

#Preview("Free Explore Overlay") {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        FreeExploreOverlayView(onHome: {}, onHowItWorks: {}, onReposition: {})
    }
}
