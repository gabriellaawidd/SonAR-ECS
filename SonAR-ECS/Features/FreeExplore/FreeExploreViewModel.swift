//
//  FreeExploreViewModel.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import Foundation

@MainActor
@Observable
final class FreeExploreViewModel {
    @ObservationIgnored weak var bridge: ARGuidedBridge?
    
    var showIntro: Bool = true
    var isPlaced: Bool = false
    
    func dismissIntro() {
        showIntro = false
    }
    
    func placeAgain() {
        isPlaced = false
        bridge?.placeAgain()
    }
    
    func homeTapped(onExit: () -> Void) {
        onExit()
    }
}
