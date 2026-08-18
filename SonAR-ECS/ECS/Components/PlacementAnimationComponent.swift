//
//  PlacementAnimationComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import Foundation

struct PlacementAnimationComponent: Component {
    enum Phase: Equatable {
        case launch
        case settle
        case finished
    }

    let finalPosition: SIMD3<Float>
    let finalOrientation: simd_quatf
    
    var phase: Phase = .launch
    var elapsedInPhase: TimeInterval = 0

    let launchDuration: TimeInterval = PlacementSolver.Settle.launchDuration
    let settleDuration: TimeInterval = PlacementSolver.Settle.settleDuration
}
