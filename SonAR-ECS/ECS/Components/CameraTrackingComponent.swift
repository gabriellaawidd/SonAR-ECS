//
//  CameraTrackingComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit
import simd

struct CameraTrackingComponent: Component {
    var worldTransform: simd_float4x4 = matrix_identity_float4x4
}
