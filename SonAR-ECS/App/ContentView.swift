//
//  ContentView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var currentAppState: AppState = .splash
    
    var body: some View {
        Group {
            switch currentAppState {
            case .splash:
                SplashScreenView(appState: $currentAppState)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

            case .home:
                HomeSelectionView(appState: $currentAppState)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

            case .guidedWalkthrough:
                ARContentView(initialMode: .guided, appState: $currentAppState)
                    .transition(.opacity)

            case .freeExplore:
                ARContentView(initialMode: .freeExplore, appState: $currentAppState)
                    .transition(.opacity)

            case .sensorIntro:
                HomeSelectionView(appState: $currentAppState)
            }
        }
        .animation(.spring(response: 0.65, dampingFraction: 0.8), value: currentAppState)
        .preferredColorScheme(.light)
    }
}

#Preview() {
    ContentView()
}
