//
//  SensorPreviewComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import simd

struct SensorPreviewComponent: Component {
    var followDistance: Float = PlacementSolver.previewDistance
    var smoothing: Float = 0.06
    var lastTargetPosition: SIMD3<Float>?
    var lastTargetOrientation: simd_quatf?
}
