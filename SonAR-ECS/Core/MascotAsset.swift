import SwiftUI

enum MascotAsset {
    static let neutral = "mascot2"
    static let happy = "mascotGreat"
    static let sad = "mascotTryAgain"
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