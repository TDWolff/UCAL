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
    var termStartDate: Date
    var termEndDate: Date

    init(
        name: String,
        location: String,
        startTime: Date,
        endTime: Date,
        weekdays: Set<Weekday>,
        reminderMinutesBefore: Int,
        timeZoneIdentifier: String,
        termStartDate: Date,
        termEndDate: Date
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.repeatDayValues = weekdays.map(\.rawValue).sorted()
        self.reminderMinutesBefore = reminderMinutesBefore
        self.timeZoneIdentifier = timeZoneIdentifier
        self.termStartDate = termStartDate
        self.termEndDate = termEndDate
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

    var formattedTermRange: String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(termStartDate.formatted(style)) – \(termEndDate.formatted(style.year()))"
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)),
              weekdays.contains(weekday)
        else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: termStartDate) && day <= calendar.startOfDay(for: termEndDate)
    }
}
