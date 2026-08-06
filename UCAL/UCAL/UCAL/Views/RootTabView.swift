//
//  RootTabView.swift
//  UCAL
//

import SwiftUI

struct RootTabView: View {
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
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: ClassSchedule.self, inMemory: true)
}
