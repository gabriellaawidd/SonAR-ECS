//
//  CapsuleControls.swift
//  SonAR-ECS
//

import SwiftUI

struct CapsuleActionButton: View {
    let title: String
    var background: Color = Color("buttonCyan")
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(foreground)
                .padding(.vertical, 16)
                .padding(.horizontal, 44)
                .background(
                    Capsule()
                        .fill(background)
                        .shadow(color: background.opacity(0.5), radius: 15, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct HintCapsule: View {
    let text: String
    var systemImage: String? = "hand.tap.fill"

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black)
            }
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.black)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(Color("bgMain").opacity(0.94), in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Capsule Controls") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        VStack(spacing: 24) {
            HintCapsule(text: "Tap anywhere to place")
            CapsuleActionButton(title: "Try again") {}
        }
    }
}