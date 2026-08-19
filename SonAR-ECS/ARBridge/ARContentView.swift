//
//  InitialARMode.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

//
//  ARContentView.swift
//  SonAR-ECS
//

import SwiftUI

enum InitialARMode {
    case guided
    case freeExplore
}

struct ARContentView: View {
    let initialMode: InitialARMode
    @Binding var appState: AppState

    @State private var mode: ARSessionMode
    @State private var placementService: PlacementService?
    @State private var showHowItWorks = false

    init(initialMode: InitialARMode, appState: Binding<AppState>) {
        self.initialMode = initialMode
        self._appState = appState

        switch initialMode {
        case .guided:
            let guidedVM = GuidedWalkthroughViewModel()
            self._mode = State(initialValue: .guided(guidedVM))
        case .freeExplore:
            let freeVM = FreeExploreViewModel()
            self._mode = State(initialValue: .freeExplore(freeVM))
        }
    }

    var body: some View {
        ZStack {
            ARViewContainer(mode: $mode) { service in
                self.placementService = service
            }
            .ignoresSafeArea()
            .onTapGesture { location in
                Task {
                    guard let placementService else { return }
                    let markerHandled = await placementService.handleMarkerTap(at: location)
                    if !markerHandled {
                        await placementService.handleTap(at: location)
                    }
                }
            }

            switch mode {
            case .guided(let guidedVM):
                GuidedOverlayView(
                    step: guidedVM.step,
                    isShowingInstruction: guidedVM.isShowingInstruction,
                    onDismissInstruction: { guidedVM.dismissInstruction() },
                    onHome: { appState = .home },
                    onHowItWorks: { showHowItWorks = true },
                    onContinue: { guidedVM.continueTapped() },
                    onRetry: { guidedVM.retryTapped() },
                    onFinish: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            let freeVM = FreeExploreViewModel()
                            self.mode = .freeExplore(freeVM)
                        }
                    }
                )
                .transition(.opacity)

            case .freeExplore(let freeVM):
                FreeExploreOverlayView(
                    showIntro: freeVM.showIntro,
                    isPlaced: freeVM.isPlaced,
                    onDismissIntro: { freeVM.dismissIntro() },
                    onHome: { appState = .home },
                    onHowItWorks: { showHowItWorks = true },
                    onReposition: { freeVM.placeAgain() }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksSheetView()
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview("AR Content View") {
    ARContentView(initialMode: .guided, appState: .constant(.guidedWalkthrough))
}
