//
//  ARGuidedBridge.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import Combine
import Foundation

final class ARGuidedBridge {
    private weak var scene: RealityKit.Scene?
    private var mode: ARSessionMode
    private var cancellable: AnyCancellable?
    private var hasEvaluatedCurrentPlacement = false
    private var materialWaitCount = 0
    private static let maxMaterialWaits = 5

    init(scene: RealityKit.Scene, mode: ARSessionMode) {
        self.scene = scene
        self.mode = mode
        
        if case .guided(let vm) = mode {
            vm.bridge = self
        }
        if case .freeExplore(let vm) = mode {
            vm.bridge = self
        }
        
        subscribe()
    }

    func updateMode(_ newMode: ARSessionMode) {
        self.mode = newMode
        if case .guided(let vm) = newMode {
            vm.bridge = self
        }
        if case .freeExplore(let vm) = newMode {
            vm.bridge = self
        }
    }

    func switchToFreeExplore(_ viewModel: FreeExploreViewModel) {
        self.mode = .freeExplore(viewModel)
        viewModel.bridge = self
        placeAgain()
    }

    private func subscribe() {
        cancellable = AREventBus.shared.pulseCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                self?.handlePulse(report)
            }
    }

    func beginMeasurement() {
        hasEvaluatedCurrentPlacement = false
        materialWaitCount = 0
        if case .freeExplore(let vm) = mode {
            vm.isPlaced = true
            vm.showIntro = false
        }
    }

    private func handlePulse(_ report: PulseReport) {
        guard !hasEvaluatedCurrentPlacement else { return }

        guard let scene,
              let sensor = scene.anchors.compactMap({ $0.findEntity(named: "SensorContainer") ?? $0.findEntity(named: SceneEntityNames.sensorNode) }).first,
              let state = sensor.components[SensorStateComponent.self],
              state.phase == .placed,
              let surface = sensor.components[ReconstructedSurfaceComponent.self] else {
            return
        }

        if case .guided(let vm) = mode,
           vm.progress.usesMaterialDetection,
           surface.materialCategory == .unknown,
           materialWaitCount < Self.maxMaterialWaits {
            materialWaitCount += 1
            return
        }
        materialWaitCount = 0

        hasEvaluatedCurrentPlacement = true

        let outcome: PlacementOutcome
        switch mode {
        case .guided(let vm):
            if vm.progress.usesMaterialDetection {
                outcome = (surface.materialCategory == .soft) ? .absorbed : .bounceBack
            } else {
                outcome = report.isBounceBack ? .bounceBack : .bounceAway
            }
            
            let resolution = vm.recordOutcome(outcome)
            switch resolution {
            case .lesson(let lesson):
                let presentation = (lesson == .absorbed)
                    ? FeedbackPresentation.soft(report: report)
                    : FeedbackPresentation(lesson: lesson, report: report)
                vm.applyLesson(lesson, presentation: presentation)
                sendMascotFeedback(presentation)
                
            case .retry(let reason):
                vm.applyRetry(reason)
            }

        case .freeExplore:
            outcome = surface.materialCategory == .soft ? .absorbed
                : (report.isBounceBack ? .bounceBack : .bounceAway)
            let presentation = (outcome == .absorbed)
                ? FeedbackPresentation.soft(report: report)
                : FeedbackPresentation(lesson: outcome.lesson, report: report)
            let sensorWorldPos = sensor.position(relativeTo: nil)
            let sensorForward = sensor.orientation(relativeTo: nil).act(SIMD3<Float>(0, 0, -1))
            let fallbackPos = sensorWorldPos + sensorForward * 0.5
            let hitPos = surface.hits.compactMap({ $0 }).first?.worldPosition ?? fallbackPos
            sensor.components.set(NeedsAnnotationDisplay(hitPosition: hitPos, content: presentation))
        }
    }

    func placeAgain() {
        guard let scene,
              let sensor = scene.anchors.compactMap({ $0.findEntity(named: "SensorContainer") ?? $0.findEntity(named: SceneEntityNames.sensorNode) }).first else {
            return
        }
        
        var state = sensor.components[SensorStateComponent.self] ?? SensorStateComponent()
        state.phase = .carrying
        state.currentLockID = nil
        sensor.components[SensorStateComponent.self] = state

        sensor.components.remove(PlacementAnimationComponent.self)
        sensor.components.remove(ReconstructedSurfaceComponent.self)

        var preview = sensor.components[SensorPreviewComponent.self] ?? SensorPreviewComponent()
        preview.lastTargetPosition = sensor.position(relativeTo: nil)
        preview.lastTargetOrientation = sensor.orientation(relativeTo: nil)
        sensor.components[SensorPreviewComponent.self] = preview

        SensorMaterialManager.applyHologram(to: sensor)

        sensor.components.set(WaveEmitterComponent(pulseInterval: 1.0, elapsedSinceLastPulse: 1.0))

        removeExistingSurfacePlane()
        removeExistingAnnotationMarkers()
        dismissFeedbackRobot()
        hasEvaluatedCurrentPlacement = false
        materialWaitCount = 0
        if case .freeExplore(let vm) = mode {
            vm.isPlaced = false
        }
    }

    func dismissFeedbackRobot() {
        guard let scene,
              let mascotNode = scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.mascotNode) ?? $0.findEntity(named: "MascotNode") }).first,
              let robotMascot = mascotNode.findEntity(named: SceneEntityNames.robotMascot) ?? mascotNode.findEntity(named: "robot_mascot") else { return }

        robotMascot.components.remove(NeedsMascotFeedback.self)

        if var anim = robotMascot.components[MascotAnimationComponent.self], robotMascot.isEnabled {
            anim.stage = .leaving
            anim.elapsed = 0
            robotMascot.components[MascotAnimationComponent.self] = anim
            return
        }

        robotMascot.isEnabled = false
        robotMascot.components.remove(MascotAnimationComponent.self)
        if let textAnchor = mascotNode.findEntity(named: SceneEntityNames.textAnchor) ?? mascotNode.findEntity(named: "TextAnchor") {
            textAnchor.children.filter { $0.name == "robotHintCard" }.forEach { $0.removeFromParent() }
        }
    }

    private func removeExistingAnnotationMarkers() {
        guard let scene else { return }
        let query = EntityQuery(where: .has(AnnotationMarkerComponent.self))
        for marker in Array(scene.performQuery(query)) {
            marker.removeFromParent()
        }
    }

    private func removeExistingSurfacePlane() {
        guard let scene else { return }
        let query = EntityQuery(where: .has(SurfacePlaneInstanceComponent.self))
        for plane in Array(scene.performQuery(query)) {
            plane.removeFromParent()
        }
    }

    private func sendMascotFeedback(_ content: FeedbackPresentation) {
        guard let scene,
              let mascotNode = scene.anchors.compactMap({ $0.findEntity(named: SceneEntityNames.mascotNode) ?? $0.findEntity(named: "MascotNode") }).first,
              let robotMascot = mascotNode.findEntity(named: SceneEntityNames.robotMascot) ?? mascotNode.findEntity(named: "robot_mascot") else {
            return
        }

        robotMascot.components.set(NeedsMascotFeedback(content: content))
    }
}
