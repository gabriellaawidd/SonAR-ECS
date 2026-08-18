//
//  HintCapsule.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

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

#Preview {
    VStack(spacing: 20) {
        HintCapsule(text: "Ketuk untuk mulai memindai")
        HintCapsule(text: "Geser untuk memutar", systemImage: "arrow.left.and.right")
    }
    .padding()
}
