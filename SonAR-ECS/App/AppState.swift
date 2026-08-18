//
//  AppState.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import Foundation

enum AppState: Equatable {
    case splash
    case home
    case sensorIntro(isGuided: Bool)
    case guidedWalkthrough
    case freeExplore
}
