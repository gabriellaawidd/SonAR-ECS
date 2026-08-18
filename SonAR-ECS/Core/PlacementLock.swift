//
//  PlacementLock.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import Foundation
import simd

struct PlacementLock: Identifiable {
    let id: UUID
    let sensorPosition: simd_float3
    let sensorOrientation: simd_quatf
    let facingDirection: simd_float3
    let hit: RaycastHit?
    let timestamp: TimeInterval

    var incidenceAngleDegrees: Float? {
        hit?.incidenceAngleDegrees(incoming: facingDirection)
    }
}
