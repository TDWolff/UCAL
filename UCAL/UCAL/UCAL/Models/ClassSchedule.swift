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

    init(
        name: String,
        location: String,
        startTime: Date,
        endTime: Date,
        weekdays: Set<Weekday>,
        reminderMinutesBefore: Int
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.repeatDayValues = weekdays.map(\.rawValue).sorted()
        self.reminderMinutesBefore = reminderMinutesBefore
    }

    var weekdays: Set<Weekday> {
        get { Set(repeatDayValues.compactMap(Weekday.init(rawValue:))) }
        set { repeatDayValues = newValue.map(\.rawValue).sorted() }
    }
}
