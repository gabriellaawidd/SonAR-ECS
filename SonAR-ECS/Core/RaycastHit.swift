//
//  RaycastHit.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import Foundation
import simd
import CoreVideo

struct RaycastHit {
    let worldPosition: simd_float3
    let normal: simd_float3
    let distance: Float
    let screenPoint: CGPoint?
    let timestamp: TimeInterval
    let pixelBuffer: CVPixelBuffer?

    func incidenceAngleDegrees(incoming direction: simd_float3) -> Float {
        let incoming = simd_normalize(direction)
        let surfaceNormal = simd_normalize(normal)
        let cosine = simd_clamp(simd_dot(-incoming, surfaceNormal), -1, 1)
        return acos(cosine) * 180 / .pi
    }
}
