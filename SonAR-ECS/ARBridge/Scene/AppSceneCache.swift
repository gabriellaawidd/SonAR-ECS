//
//  AppSceneCache.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 19/08/26.
//

import RealityKit
import SonARAssets

@MainActor
enum AppSceneCache {
    private(set) static var mainSceneTemplate: Entity?
    private static var isPreloading = false

    static func preload() async {
        guard mainSceneTemplate == nil, !isPreloading else { return }
        isPreloading = true
        defer { isPreloading = false }

        if let scene = try? await Entity(named: "Models/MainScene", in: SonARAssets.sonARAssetsBundle) {
            mainSceneTemplate = scene
        } else if let scene = try? await Entity(named: "MainScene", in: SonARAssets.sonARAssetsBundle) {
            mainSceneTemplate = scene
        }
    }

    static func getScene() async -> Entity? {
        if let cached = mainSceneTemplate {
            return cached.clone(recursive: true)
        }
        await preload()
        return mainSceneTemplate?.clone(recursive: true)
    }
}
