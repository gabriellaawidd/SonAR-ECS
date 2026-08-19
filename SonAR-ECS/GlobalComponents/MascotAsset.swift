//
//  MascotAsset.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//


import SwiftUI

enum MascotAsset {
    static let neutral = "mascot2"
}

struct MascotImage: View {
    let name: String
    var height: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
