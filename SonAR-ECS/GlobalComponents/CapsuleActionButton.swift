//
//  CapsuleActionButton.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
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

#Preview {
    CapsuleActionButton(title: "Mulai Scan") {
    }
}
