//
//  RootTabView.swift
//  UCAL
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var classes: [ClassSchedule]
    @Query private var semesters: [Semester]

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Classes", systemImage: "line.3.horizontal")
                }

            WeekCalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
        .task {
            await NotificationManager.shared.requestAuthorization()
            let semester = Semester.fetchOrCreate(existing: semesters, context: modelContext)
            NotificationManager.shared.syncNotifications(for: classes, semester: semester)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
