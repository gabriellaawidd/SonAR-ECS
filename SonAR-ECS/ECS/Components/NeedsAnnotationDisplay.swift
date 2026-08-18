//
//  NeedsAnnotationDisplay.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import simd

struct NeedsAnnotationDisplay: Component {
    let hitPosition: SIMD3<Float>
    let content: FeedbackPresentation
}

struct AnnotationMarkerComponent: Component {
    let content: FeedbackPresentation
}

