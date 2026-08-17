//
//  ContentView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 13/08/26.
//

import SwiftUI
struct ContentView: View {
    @State private var currentAppState: AppState = .splash
    
    var body: some View {
        Group {
            switch currentAppState {
            case .splash:
                SplashScreenView(appState: $currentAppState)
            case .sensorIntro:
                SensorIntroView(appState: $currentAppState)
            case .modeSelection:
                ModeSelectionView(appState: $currentAppState)
            case .guidedWalkthrough:
                ARContentView(initialMode: .guided, appState: $currentAppState)
            case .freeExplore:
                ARContentView(initialMode: .freeExplore, appState: $currentAppState)
            }
        }
        .animation(.easeInOut, value: currentAppState)
        .preferredColorScheme(.light)
    }
}
#Preview {
    ContentView()
}
