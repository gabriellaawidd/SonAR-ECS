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
        let isFar = (report?.distanceCentimeters == nil)

        if isFar {
            return FeedbackPresentation(
                badge: GuidedLesson.bounceAway.badge,
                message: "Sound absorbed by soft material. Try to move closer!",
                distanceText: nil,
                badgeColor: UIColor(GuidedLesson.bounceAway.badgeColor)
            )
        } else {
            return FeedbackPresentation(
                badge: GuidedLesson.absorbed.badge,
                message: "Soft material absorbs soundwave and limits detection range",
                distanceText: Self.distanceText(from: report, reportsDistance: true),
                badgeColor: UIColor(GuidedLesson.absorbed.badgeColor)
            )
        }
    }
}
