//
//  FeedbackPresentation.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import SwiftUI
import UIKit

struct FeedbackPresentation: Equatable {
    let badge: String
    let message: String
    let distanceText: String?
    let badgeColor: UIColor

    static let defaultBadgeColor = UIColor.black

    static func distanceText(from report: PulseReport?, reportsDistance: Bool) -> String? {
        guard reportsDistance, let centimeters = report?.distanceCentimeters else {
            return nil
        }
        return "Distance: \(centimeters) cm"
    }

    init(lesson: GuidedLesson, report: PulseReport?) {
        badge = lesson.badge
        message = lesson.feedbackMessage
        distanceText = Self.distanceText(from: report, reportsDistance: lesson.reportsDistance)
        badgeColor = UIColor(lesson.badgeColor)
    }

    init(badge: String, message: String, distanceText: String?, badgeColor: UIColor = defaultBadgeColor) {
        self.badge = badge
        self.message = message
        self.distanceText = distanceText
        self.badgeColor = badgeColor
    }

    static func soft(report: PulseReport?) -> FeedbackPresentation {
        FeedbackPresentation(
            badge: GuidedLesson.absorbed.badge,
            message: "Soft material absorbs soundwave and limits detection range",
            distanceText: Self.distanceText(from: report, reportsDistance: true),
            badgeColor: UIColor(GuidedLesson.absorbed.badgeColor)
        )
    }

    static func retry(reason: GuidedRetryReason, report: PulseReport?) -> FeedbackPresentation {
        let badge: String
        let color: UIColor
        switch reason {
        case .notSoft:
            badge = "HARD SURFACE"
            color = UIColor(AppPalette.statusOrange)
        case .tooSteep, .notSteepEnough:
            badge = GuidedLesson.bounceAway.badge
            color = UIColor(GuidedLesson.bounceAway.badgeColor)
        }
        return FeedbackPresentation(
            badge: badge,
            message: reason.bubbleText,
            distanceText: nil,
            badgeColor: color
        )
    }
}
