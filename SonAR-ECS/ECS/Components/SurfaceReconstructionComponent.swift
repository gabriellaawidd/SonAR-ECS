//
//  SurfaceReconstructionComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 14/08/26.
//

import RealityKit
import simd
import Foundation

struct NeedsSurfaceReconstruction: Component {
    let lockID: UUID
    let hits: [RaycastHit?]
    let directions: [SIMD3<Float>]
}

struct ReconstructedSurfaceComponent: Component {
    let lockID: UUID
    let hits: [RaycastHit?]
    let directions: [SIMD3<Float>]

    let centerAngleDegrees: Float?
    let centerAngleCategory: AngleCategory

    var materialCategory: MaterialCategory = .unknown
    var materialConfidence: Float = 0
}

struct SurfacePlaneInstanceComponent: Component {}
