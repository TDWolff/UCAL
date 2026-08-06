//
//  ContentView.swift
//  UCAL
//
//  Created by Torin Wolff on 8/6/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClassSchedule.startTime) private var allClasses: [ClassSchedule]
    @State private var showAddClass = false
    @State private var showSemesterList = false
    @State private var editingClass: ClassSchedule?

    private var classes: [ClassSchedule] {
        allClasses.filter { $0.semester?.isActive == true }
    }

    var body: some View {
        NavigationStack {
            List {
                if classes.isEmpty {
                    ContentUnavailableView(
                        "No Classes Yet",
                        systemImage: "calendar.badge.clock",
                        description: Text("Tap + to add your first class.")
                    )
                } else {
                    ForEach(classes) { classSchedule in
                        Button {
                            editingClass = classSchedule
                        } label: {
                            ClassRow(classSchedule: classSchedule)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteClasses)
                }
            }
            .navigationTitle("My Classes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSemesterList = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddClass = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClass) {
                ClassFormView()
            }
            .sheet(item: $editingClass) { classSchedule in
                ClassFormView(existingClass: classSchedule)
            }
            .sheet(isPresented: $showSemesterList) {
                SemesterListView()
            }
        }
    }

    private func deleteClasses(at offsets: IndexSet) {
        for index in offsets {
            let classSchedule = classes[index]
            NotificationManager.shared.cancelNotifications(for: classSchedule)
            modelContext.delete(classSchedule)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct ClassRow: View {
    let classSchedule: ClassSchedule

    private var daysSummary: String {
        let days = Weekday.allCases
            .filter { classSchedule.weekdays.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
        guard let semester = classSchedule.semester else { return days }
        return "\(days) • \(semester.formattedRange)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(classSchedule.colorTag.color)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(classSchedule.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(classSchedule.formattedTimeRange)
                    if !classSchedule.location.isEmpty {
                        Text("• \(classSchedule.location)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Text(daysSummary)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
