//
//  Semester.swift
//  UCAL
//

import Foundation
import SwiftData

@Model
final class Semester {
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \ClassSchedule.semester)
    var classes: [ClassSchedule] = []

    init(name: String, startDate: Date, endDate: Date, isActive: Bool) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }

    var formattedRange: String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(startDate.formatted(style)) – \(endDate.formatted(style.year()))"
    }

    static func activeOrCreate(existing: [Semester], context: ModelContext) -> Semester {
        if let active = existing.first(where: { $0.isActive }) { return active }
        if let first = existing.first {
            first.isActive = true
            return first
        }
        let semester = Semester(
            name: "New Semester",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .weekOfYear, value: 16, to: Date()) ?? Date(),
            isActive: true
        )
        context.insert(semester)
        return semester
    }

    static func activate(_ semester: Semester, among all: [Semester]) {
        for candidate in all {
            candidate.isActive = (candidate === semester)
        }
    }
}
