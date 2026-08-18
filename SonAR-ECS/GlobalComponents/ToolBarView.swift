//
//  ToolBarView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//


import SwiftUI

struct ToolBarView: View {
    var onHome: () -> Void
    var onHowItWorks: () -> Void

    var body: some View {
        HStack {
            CircleIconButton(
                systemName: "house.fill",
                accessibilityTitle: "Back to menu",
                action: onHome
            )

            Spacer()

            CircleIconButton(
                systemName: "questionmark",
                accessibilityTitle: "How it works",
                action: onHowItWorks
            )
        }
        .padding(.top, 8)
    }
}

#Preview("Toolbar") {
    ToolBarView(onHome: {}, onHowItWorks: {})
        .padding()
        .background(Color.gray.opacity(0.2))
}
