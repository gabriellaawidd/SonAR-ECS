//
//  RealityKitRegistry.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 13/08/26.
//

import RealityKit

enum RealityKitRegistry {
    static func registerAll() {
        registerComponents()
        registerSystem()
    }
    
    private static func registerComponents() {
        BobbingComponent.registerComponent()
        CustomBillboardComponent.registerComponent()
        MascotAnimationComponent.registerComponent()
        NeedsMascotFeedback.registerComponent()
        PlacementAnimationComponent.registerComponent()
        SensorPreviewComponent.registerComponent()
        SensorStateComponent.registerComponent()
        NeedsSurfaceReconstruction.registerComponent()
        ReconstructedSurfaceComponent.registerComponent()
        WaveEmitterComponent.registerComponent()
        WavePropertiesComponent.registerComponent()
        NeedsAnnotationDisplay.registerComponent()
        AnnotationMarkerComponent.registerComponent()
        SurfacePlaneInstanceComponent.registerComponent()
    }
    
    private static func registerSystem() {
        BillboardSystem.registerSystem()
        BobbingSystem.registerSystem()
        MascotAnimationSystem.registerSystem()
        PlacementAnimationSystem.registerSystem()
        PreviewFollowSystem.registerSystem()
        SurfaceReconstructionSystem.registerSystem()
        WaveSimulationSystem.registerSystem()
        AnnotationDisplaySystem.registerSystem()
    }
}
