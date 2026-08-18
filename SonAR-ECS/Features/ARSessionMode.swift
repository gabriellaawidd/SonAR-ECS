//
//  ARSessionMode.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//


import Foundation

enum ARSessionMode {
    case guided(GuidedWalkthroughViewModel)
    case freeExplore(FreeExploreViewModel)
}
