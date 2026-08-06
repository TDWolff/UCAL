//
//  RootTabView.swift
//  UCAL
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query private var classes: [ClassSchedule]

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
            NotificationManager.shared.syncNotifications(for: classes)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
