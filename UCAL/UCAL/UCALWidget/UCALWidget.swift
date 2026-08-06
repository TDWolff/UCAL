//
//  UCALWidget.swift
//  UCALWidget
//

import WidgetKit
import SwiftUI
import SwiftData

struct UpcomingClass {
    let name: String
    let location: String
    let timeRange: String
    let color: ClassColor
}

struct ClassEntry: TimelineEntry {
    let date: Date
    let upcoming: UpcomingClass?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ClassEntry {
        ClassEntry(
            date: Date(),
            upcoming: UpcomingClass(name: "CS 301", location: "Room 204", timeRange: "9:05 AM - 9:55 AM PDT", color: .blue)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassEntry) -> Void) {
        completion(ClassEntry(date: Date(), upcoming: fetchNextClass()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassEntry>) -> Void) {
        let entry = ClassEntry(date: Date(), upcoming: fetchNextClass())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func fetchNextClass() -> UpcomingClass? {
        let context = ModelContext(SharedModelContainer.shared)
        guard let allClasses = try? context.fetch(FetchDescriptor<ClassSchedule>()) else { return nil }

        let upcoming = allClasses
            .compactMap { classSchedule -> (ClassSchedule, Date)? in
                guard let next = classSchedule.nextOccurrence() else { return nil }
                return (classSchedule, next)
            }
            .min { $0.1 < $1.1 }

        guard let (classSchedule, _) = upcoming else { return nil }
        return UpcomingClass(
            name: classSchedule.name,
            location: classSchedule.location,
            timeRange: classSchedule.formattedTimeRange,
            color: classSchedule.colorTag
        )
    }
}

struct UCALWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let upcoming = entry.upcoming {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(upcoming.color.color)
                        .frame(width: 8, height: 8)
                    Text("NEXT CLASS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(upcoming.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(upcoming.timeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !upcoming.location.isEmpty {
                    Text(upcoming.location)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No upcoming classes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct UCALWidget: Widget {
    let kind: String = "UCALWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UCALWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Class")
        .description("Shows your next upcoming class.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    UCALWidget()
} timeline: {
    ClassEntry(
        date: .now,
        upcoming: UpcomingClass(name: "CS 301", location: "Room 204", timeRange: "9:05 AM - 9:55 AM PDT", color: .blue)
    )
    ClassEntry(date: .now, upcoming: nil)
}
