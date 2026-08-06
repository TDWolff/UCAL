//
//  ClassSchedule.swift
//  UCAL
//

import Foundation
import SwiftData

@Model
final class ClassSchedule {
    var id: UUID
    var name: String
    var location: String
    var startTime: Date
    var endTime: Date
    var repeatDayValues: [Int]
    var reminderMinutesBefore: Int
    var timeZoneIdentifier: String

    init(
        name: String,
        location: String,
        startTime: Date,
        endTime: Date,
        weekdays: Set<Weekday>,
        reminderMinutesBefore: Int,
        timeZoneIdentifier: String
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.repeatDayValues = weekdays.map(\.rawValue).sorted()
        self.reminderMinutesBefore = reminderMinutesBefore
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    var weekdays: Set<Weekday> {
        get { Set(repeatDayValues.compactMap(Weekday.init(rawValue:))) }
        set { repeatDayValues = newValue.map(\.rawValue).sorted() }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var formattedTimeRange: String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone)
        let abbreviation = timeZone.abbreviation(for: startTime) ?? timeZone.identifier
        return "\(startTime.formatted(style)) - \(endTime.formatted(style)) \(abbreviation)"
    }

    func occurs(on date: Date, semester: Semester, calendar: Calendar = .current) -> Bool {
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)),
              weekdays.contains(weekday)
        else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: semester.startDate) && day <= calendar.startOfDay(for: semester.endDate)
    }
}
