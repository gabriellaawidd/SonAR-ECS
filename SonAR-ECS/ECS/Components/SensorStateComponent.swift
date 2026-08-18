//
//  SensorStateComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import Foundation

struct SensorStateComponent: Component {
    enum Phase: Equatable {
        case carrying
        case placed
    }
    
    var phase: Phase = .carrying
    var currentLockID: UUID?
}
