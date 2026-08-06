//
//  WeekCalendarView.swift
//  UCAL
//

import SwiftUI
import SwiftData

struct WeekCalendarView: View {
    @Query private var allClasses: [ClassSchedule]
    @State private var weekOffset = 0

    private let calendar = Calendar.current

    private var classes: [ClassSchedule] {
        allClasses.filter { $0.semester?.isActive == true }
    }

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let shiftedStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfWeek)
        else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: shiftedStart) }
    }

    private var weekRangeText: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(first.formatted(.dateTime.month(.abbreviated).day())) - \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    var body: some View {
        NavigationStack {
            List(weekDates, id: \.self) { date in
                let isToday = calendar.isDateInToday(date)

                Section {
                    let dayClasses = classes(on: date)
                    if dayClasses.isEmpty {
                        Text("No classes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dayClasses) { classSchedule in
                            CalendarClassRow(classSchedule: classSchedule)
                        }
                    }
                } header: {
                    HStack {
                        Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .foregroundStyle(isToday ? Color.accentColor : .secondary)
                            .fontWeight(isToday ? .bold : .regular)
                        if isToday {
                            Text("TODAY")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .listRowBackground(isToday ? Color.accentColor.opacity(0.08) : nil)
            }
            .navigationTitle("Week View")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Button {
                            weekOffset -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(weekRangeText)
                            .font(.headline)
                        Button {
                            weekOffset += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Today") { weekOffset = 0 }
                        .disabled(weekOffset == 0)
                }
            }
        }
    }

    private func classes(on date: Date) -> [ClassSchedule] {
        classes
            .filter { $0.occurs(on: date, calendar: calendar) }
            .sorted { minutesOfDay($0.startTime) < minutesOfDay($1.startTime) }
    }

    private func minutesOfDay(_ date: Date) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }
}

private struct CalendarClassRow: View {
    let classSchedule: ClassSchedule

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(classSchedule.colorTag.color)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(classSchedule.name)
                    .font(.headline)
                Text(classSchedule.formattedTimeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !classSchedule.location.isEmpty {
                    Text(classSchedule.location)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WeekCalendarView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
