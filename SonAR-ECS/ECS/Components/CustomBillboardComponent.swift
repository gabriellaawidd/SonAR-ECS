//
//  CustomBillboardComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit

struct CustomBillboardComponent: Component {
    var maxPitchDegrees: Float = 14
    var pitchSofteningFactor: Float = 0.3
    var smoothing: Float = 0.12
    var facesPositiveZ: Bool = true 
}
