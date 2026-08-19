//
//  SensorFeedbackService.swift
//  SonAR-ECS
//

import AVFoundation
import UIKit

final class SensorFeedbackService {
    static let shared = SensorFeedbackService()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private var buffer: AVAudioPCMBuffer?
    
    private init() {
        hapticGenerator.prepare()
        setupAudio()
    }
    
    private func setupAudio() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        
        let sampleRate = Float(format.sampleRate)
        let duration: Float = 0.1 // 100ms
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount
        
        let channels = pcmBuffer.floatChannelData![0]
        let frequency: Float = 440.0 // 440 Hz (Low-Mid pitch beep)
        
        for i in 0..<Int(frameCount) {
            let time = Float(i) / sampleRate
            // Sine wave with linear fade-out to avoid clicking sounds
            let amplitude = 1.0 - (Float(i) / Float(frameCount))
            channels[i] = sin(2.0 * .pi * frequency * time) * amplitude * 0.3
        }
        
        self.buffer = pcmBuffer
        
        do {
            // Configure audio session to mix with others
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("[SensorFeedbackService] Failed to start audio engine: \(error)")
        }
    }
    
    func playTransmitFeedback() {
        hapticGenerator.impactOccurred(intensity: 0.8)
        
        if let buffer = buffer {
            playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }
    }
}
