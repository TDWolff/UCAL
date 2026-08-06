//
//  SemesterSettingsView.swift
//  UCAL
//

import SwiftUI
import SwiftData

struct SemesterSettingsView: View {
    @Bindable var semester: Semester
    @Query private var classes: [ClassSchedule]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Starts", selection: $semester.startDate, displayedComponents: .date)
                    DatePicker("Ends", selection: $semester.endDate, displayedComponents: .date)
                    if semester.endDate < semester.startDate {
                        Text("End date must be after the start date.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Semester Dates")
                } footer: {
                    Text("This applies to all of your classes, so you only need to set it once per semester.")
                }
            }
            .navigationTitle("Semester")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        NotificationManager.shared.syncNotifications(for: classes, semester: semester)
                        dismiss()
                    }
                    .disabled(semester.endDate < semester.startDate)
                }
            }
        }
    }
}

#Preview {
    SemesterSettingsView(semester: Semester(startDate: .now, endDate: .now))
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
