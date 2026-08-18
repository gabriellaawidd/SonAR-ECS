//
//  MaterialDetectionManager.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import Foundation
import CoreVideo
import simd

final class MaterialDetectionManager {

    private let geometryClassifier: SurfaceGeometryClassifier
    private let visionClassifier: MaterialVisionClassifier

    init(
        geometryClassifier: SurfaceGeometryClassifier = SurfaceGeometryClassifier(),
        visionClassifier: MaterialVisionClassifier = MaterialVisionClassifier()
    ) {
        self.geometryClassifier = geometryClassifier
        self.visionClassifier = visionClassifier
    }

    func detect(
        pixelBuffer: CVPixelBuffer?,
        hit: RaycastHit,
        facingDirection: SIMD3<Float>,
        completion: @escaping (SurfaceReading) -> Void
    ) {
        let angleDegrees = hit.incidenceAngleDegrees(incoming: facingDirection)
        let geometryResult = geometryClassifier.classify(angleDegrees: angleDegrees)

        guard let pixelBuffer else {
            completion(SurfaceReading(
                normal: hit.normal,
                angleDegrees: geometryResult.angleDegrees,
                angleCategory: geometryResult.category,
                materialCategory: .unknown,
                materialConfidence: 0
            ))
            return
        }

        visionClassifier.classify(pixelBuffer: pixelBuffer) { materialResult in
            completion(SurfaceReading(
                normal: hit.normal,
                angleDegrees: geometryResult.angleDegrees,
                angleCategory: geometryResult.category,
                materialCategory: materialResult.category,
                materialConfidence: materialResult.confidence
            ))
        }
    }
}
