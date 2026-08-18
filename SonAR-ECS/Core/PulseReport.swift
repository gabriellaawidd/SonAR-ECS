//
//  PulseReport.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import Foundation

struct PulseReport: Equatable {
    let returned: Int
    let total: Int
    let centerDistance: Float?
    let centerAngle: Float?
    
    static let minReturn: Int = 3
    
    var isBounceBack: Bool {
        returned >= Self.minReturn
    }
    
    var distanceCentimeters: Int? {
        guard let centerDistance else { return nil }
        return Int((centerDistance * 100).rounded())
    }
}
