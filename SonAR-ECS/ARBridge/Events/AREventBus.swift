//
//  AREventBus.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 16/08/26.
//

import Foundation
import Combine

final class AREventBus {
    static let shared = AREventBus()
    private init() {}
    
    let pulseCompleted = PassthroughSubject<PulseReport, Never>()
}
