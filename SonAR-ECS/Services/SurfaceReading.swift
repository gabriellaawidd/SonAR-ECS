import simd

struct SurfaceReading {
    let normal: SIMD3<Float>
    let angleDegrees: Float?
    let angleCategory: AngleCategory
    let materialCategory: MaterialCategory
    let materialConfidence: Float
    
    init(normal: SIMD3<Float>, angleDegrees: Float?, angleCategory: AngleCategory, materialCategory: MaterialCategory, materialConfidence: Float) {
        self.normal = normal
        self.angleDegrees = angleDegrees
        self.angleCategory = angleCategory
        self.materialCategory = materialCategory
        self.materialConfidence = materialConfidence
    }
}