//
//  Semester.swift
//  UCAL
//

import Foundation
import SwiftData

@Model
final class Semester {
    var startDate: Date
    var endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    var formattedRange: String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(startDate.formatted(style)) – \(endDate.formatted(style.year()))"
    }

    static func fetchOrCreate(existing: [Semester], context: ModelContext) -> Semester {
        if let semester = existing.first { return semester }
        let semester = Semester(
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .weekOfYear, value: 16, to: Date()) ?? Date()
        )
        context.insert(semester)
        return semester
    }
}
