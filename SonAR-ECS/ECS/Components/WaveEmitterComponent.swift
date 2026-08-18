//
//  WaveEmitterComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import Foundation

struct WaveEmitterComponent: Component {
    var pulseInterval: TimeInterval = 1.0
    var elapsedSinceLastPulse: TimeInterval = 0
    let travelSpeed: Float = 0.7
}
