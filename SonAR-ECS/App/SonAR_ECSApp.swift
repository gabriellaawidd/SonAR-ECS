//
//  SonAR_ECSApp.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 13/08/26.
//

import SwiftUI

@main
struct SonAR_ECSApp: App {
    init() {
        RealityKitRegistry.registerAll()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
//            FreeExploreOverlayView()
        }
    }
}
