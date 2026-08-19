//
//  GuidedLesson.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import SwiftUI

enum GuidedLesson: String, CaseIterable, Equatable {
    case bounceBack
    case bounceAway
    case absorbed

    var reportsDistance: Bool {
        switch self {
        case .bounceBack: return true
        case .bounceAway, .absorbed: return false
        }
    }

    var badge: String {
        switch self {
        case .bounceBack: return "WAVE RETURNED!"
        case .bounceAway: return "WAVE LOST"
        case .absorbed: return "WEAK SOUNDWAVE"
        }
    }

    var badgeColor: Color {
        switch self {
        case .bounceBack: return AppPalette.statusGreen
        case .bounceAway: return AppPalette.statusRed
        case .absorbed: return AppPalette.statusOrange
        }
    }

    var feedbackMessage: String {
        switch self {
        case .bounceBack:
            return "The sound wave bounced off the wall and returned to the sensor"
        case .bounceAway:
            return "The sensor can't detect anything because there is no returning wave"
        case .absorbed:
            return "Soft material absorbs soundwave and limits detection range"
        }
    }
}
