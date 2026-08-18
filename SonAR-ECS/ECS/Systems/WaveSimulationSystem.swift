//
//  WaveSimulationSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import RealityKit
import simd
import UIKit
import Combine

struct WaveSimulationSystem: System {
    private static let query = EntityQuery(
        where: .has(WaveEmitterComponent.self) && .has(ReconstructedSurfaceComponent.self)
    )

    private static let minReturningRays = 3
    private static let softMaxEchoes = 2
    private static let arrowScale: Float = 0.35

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let properties = context.scene.anchors
            .compactMap { $0.findEntity(named: SceneEntityNames.arrowTemplate)?.components[WavePropertiesComponent.self] }
            .first ?? WavePropertiesComponent()

        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var emitter = entity.components[WaveEmitterComponent.self],
                  let surface = entity.components[ReconstructedSurfaceComponent.self] else { continue }

            emitter.elapsedSinceLastPulse += TimeInterval(context.deltaTime)

            if emitter.elapsedSinceLastPulse >= emitter.pulseInterval {
                emitter.elapsedSinceLastPulse = 0
                fire(from: entity, surface: surface, properties: properties, scene: context.scene)
            }

            entity.components[WaveEmitterComponent.self] = emitter
        }
    }

    private func fire(from sensor: Entity, surface: ReconstructedSurfaceComponent, properties: WavePropertiesComponent, scene: RealityKit.Scene) {
        var current: Entity? = sensor
        while let c = current, !(c is AnchorEntity) {
            current = c.parent
        }
        guard let anchor = (current as? AnchorEntity) ?? (scene.anchors.first as? AnchorEntity) else {
            return
        }

        let transmitter = sensor.findEntity(named: SceneEntityNames.transmitter) ?? sensor
        let receiver = sensor.findEntity(named: SceneEntityNames.receiver) ?? sensor

        let origin = transmitter.position(relativeTo: nil)
        let absorbent = (surface.materialCategory == .soft)
        var returnedCount = 0

        let hits = surface.hits
        let directions = surface.directions

        let centerHit = hits.first ?? nil
        let centerDirection = directions.first ?? SIMD3<Float>(0, 0, -1)
        let centerAngle = centerHit?.incidenceAngleDegrees(incoming: centerDirection)

        for (originalHit, forward) in zip(hits, directions) {
            let hit = originalHit.flatMap { $0.distance <= properties.maxRange ? $0 : nil }

            let distance = hit?.distance ?? properties.maxRange
            let hitPoint = hit?.worldPosition ?? origin + forward * distance

            let outDuration = legDuration(distance, properties: properties)
            WaveRenderer.spawnPulse(color: .cyan, from: origin, to: hitPoint, anchor: anchor, duration: outDuration, scale: Self.arrowScale)

            if let hit = hit {
                DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                    WaveRenderer.spawnHitDecal(at: hit.worldPosition, normal: hit.normal, anchor: anchor)
                }

                if hit.incidenceAngleDegrees(incoming: forward) <= properties.echoReturnAngleLimit,
                   !absorbent || returnedCount < Self.softMaxEchoes {
                    returnedCount += 1
                    let receiverPosition = receiver.position(relativeTo: nil)
                    let fullDist = simd_distance(hitPoint, receiverPosition)

                    let remainingDistance = max(properties.maxRange - distance, 0)
                    let maxBounceDist = surface.materialCategory == .soft ? min(remainingDistance, 0.5) : remainingDistance
                    let bounceDistance = min(fullDist, maxBounceDist)

                    let backDuration = legDuration(bounceDistance, properties: properties)
                    let targetPos = hitPoint + simd_normalize(receiverPosition - hitPoint) * bounceDistance
                    let scale: Float = surface.materialCategory == .soft ? 0.15 : Self.arrowScale

                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        WaveRenderer.spawnPulse(color: .green, from: hitPoint, to: targetPos, anchor: anchor, duration: backDuration, scale: scale)
                    }
                } else if !absorbent {
                    let reflectedDirection = simd_reflect(simd_normalize(forward), simd_normalize(hit.normal))
                    let remainingDistance = max(properties.maxRange - distance, 0)
                    let bounceDistance = surface.materialCategory == .soft ? min(remainingDistance, 0.5) : remainingDistance

                    let bounceTarget = hit.worldPosition + reflectedDirection * bounceDistance
                    let bounceDuration = legDuration(bounceDistance, properties: properties)
                    let scale: Float = surface.materialCategory == .soft ? 0.15 : Self.arrowScale

                    DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
                        WaveRenderer.spawnPulse(color: .red, from: hitPoint, to: bounceTarget, anchor: anchor, duration: bounceDuration, scale: scale)
                    }
                }
            }
        }

        let measurable = returnedCount >= Self.minReturningRays
        let report = PulseReport(
            returned: returnedCount,
            total: directions.count,
            centerDistance: measurable ? centerHit?.distance : nil,
            centerAngle: centerAngle
        )
        AREventBus.shared.pulseCompleted.send(report)
    }

    private func legDuration(_ distance: Float, properties: WavePropertiesComponent) -> TimeInterval {
        max(TimeInterval(distance / properties.travelSpeed), properties.minLegDuration)
    }
}
