//
//  BobbingSystem.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import RealityKit

struct BobbingSystem: System {
    private static let query = EntityQuery(where: .has(BobbingComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var bobbing = entity.components[BobbingComponent.self] else {
                continue
            }
            bobbing.elapsedInLeg += context.deltaTime
            if bobbing.elapsedInLeg >= bobbing.legDuration {
                bobbing.elapsedInLeg = 0
                bobbing.goingUp.toggle()
            }
            
            let t = Float (bobbing.elapsedInLeg / bobbing.legDuration)
            let eased = Self.easeInOut(t)
            
            let offset = bobbing.goingUp ? bobbing.bobHeight * eased : bobbing.bobHeight * (1 - eased)
            
            var transform = entity.transform
            transform.translation.y = bobbing.baseLocalY + offset
            entity.transform = transform
            
            entity.components[BobbingComponent.self] = bobbing
        }
    }
    
    private static func easeInOut(_ t: Float) -> Float {
        (1 - cos(t * .pi)) / 2
    }
}
