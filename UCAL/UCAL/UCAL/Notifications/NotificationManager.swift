//
//  NotificationManager.swift
//  UCAL
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleNotifications(for classSchedule: ClassSchedule) {
        cancelNotifications(for: classSchedule)

        var calendar = Calendar.current
        calendar.timeZone = classSchedule.timeZone
        let center = UNUserNotificationCenter.current()

        let hour = Calendar.current.component(.hour, from: classSchedule.startTime)
        let minute = Calendar.current.component(.minute, from: classSchedule.startTime)
        let searchStart = max(Date(), calendar.startOfDay(for: classSchedule.termStartDate))

        for day in classSchedule.weekdays {
            var matchComponents = DateComponents()
            matchComponents.timeZone = classSchedule.timeZone
            matchComponents.weekday = day.rawValue
            matchComponents.hour = hour
            matchComponents.minute = minute

            guard let nextClassDate = calendar.nextDate(
                after: searchStart,
                matching: matchComponents,
                matchingPolicy: .nextTime
            ), nextClassDate <= classSchedule.termEndDate else { continue }

            let notifyDate = calendar.date(
                byAdding: .minute,
                value: -classSchedule.reminderMinutesBefore,
                to: nextClassDate
            ) ?? nextClassDate

            var triggerComponents = calendar.dateComponents([.weekday, .hour, .minute], from: notifyDate)
            triggerComponents.timeZone = classSchedule.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = classSchedule.name
            content.body = classSchedule.location.isEmpty
                ? "Starts in \(classSchedule.reminderMinutesBefore) min"
                : "\(classSchedule.location) • starts in \(classSchedule.reminderMinutesBefore) min"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifier(for: classSchedule, day: day),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func syncNotifications(for classes: [ClassSchedule]) {
        for classSchedule in classes {
            scheduleNotifications(for: classSchedule)
        }
    }

    func cancelNotifications(for classSchedule: ClassSchedule) {
        let identifiers = Weekday.allCases.map { identifier(for: classSchedule, day: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func identifier(for classSchedule: ClassSchedule, day: Weekday) -> String {
        "\(classSchedule.id.uuidString)-\(day.rawValue)"
    }
}
