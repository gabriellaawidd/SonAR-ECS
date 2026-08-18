//
//  WavePropertiesComponent.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//


import RealityKit

// Ensure you register this component in your app’s delegate using:
// WavePropertiesComponent.registerComponent()
public struct WavePropertiesComponent: Component, Codable {
    // This is an example of adding a variable to the component.
    var maxRange: Float = 2.0
    var travelSpeed: Float = 0.7
    var minLegDuration: Double = 0.15
    var echoReturnAngleLimit: Float = 10.0

    public init() {
    }
}
