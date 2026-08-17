//
//  PlacementOutcome.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import Foundation

enum PlacementOutcome {
    case bounceBack
    case bounceAway
    case absorbed
    
    var lesson: GuidedLesson {
        switch self {
        case .bounceBack: return .bounceBack
        case .bounceAway: return .bounceAway
        case .absorbed: return .absorbed
        }
    }
}
