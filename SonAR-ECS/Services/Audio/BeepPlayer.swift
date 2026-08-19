//
//  BeepPlayer.swift
//  SonAR-ECS
//

import AVFoundation

enum BeepPlayer {
    private static let player: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Beep", withExtension: "m4a") else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }()

    static func play() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }
}
