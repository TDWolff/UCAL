//
//  ContentView.swift
//  UCAL
//
//  Created by Torin Wolff on 8/6/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClassSchedule.startTime) private var classes: [ClassSchedule]
    @State private var showAddClass = false

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
                        ClassRow(classSchedule: classSchedule)
                    }
                    .onDelete(perform: deleteClasses)
                }
            }
            .navigationTitle("My Classes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddClass = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClass) {
                AddClassView()
            }
        }
    }

    private func deleteClasses(at offsets: IndexSet) {
        for index in offsets {
            let classSchedule = classes[index]
            NotificationManager.shared.cancelNotifications(for: classSchedule)
            modelContext.delete(classSchedule)
        }
    }
}

private struct ClassRow: View {
    let classSchedule: ClassSchedule

    private var daysSummary: String {
        Weekday.allCases
            .filter { classSchedule.weekdays.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    var body: some View {
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
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClassSchedule.self, inMemory: true)
}
