//
//  BobbingComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import Foundation

struct BobbingComponent: Component {
    let baseLocalY: Float
    var bobHeight: Float
    var legDuration: TimeInterval
    var goingUp: Bool = true
    var elapsedInLeg: TimeInterval = 0 
}
