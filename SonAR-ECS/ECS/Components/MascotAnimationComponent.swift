//
//  MascotAnimationComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import Foundation

struct MascotAnimationComponent: Component {
    enum Stage: Equatable {
        case appearing
        case hovering
        case leaving
    }
    
    var stage: Stage = .appearing
    var elapsed: TimeInterval = 0
    var currentContent: FeedbackPresentation
    var targetScale: Float = 1.0
}
