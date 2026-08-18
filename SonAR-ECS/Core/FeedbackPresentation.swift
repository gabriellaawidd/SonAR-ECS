//
//  FeedbackPresentation.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 15/08/26.
//

import Foundation

struct FeedbackPresentation: Equatable {
    let badge: String
    let message: String
    let distanceText: String?
    
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
        }

        init(badge: String, message: String, distanceText: String?) {
            self.badge = badge
            self.message = message
            self.distanceText = distanceText
        }
}
