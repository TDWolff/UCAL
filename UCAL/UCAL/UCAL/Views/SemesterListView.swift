//
//  SemesterListView.swift
//  UCAL
//

import SwiftUI
import SwiftData
import WidgetKit

struct SemesterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Semester.startDate, order: .reverse) private var semesters: [Semester]
    @Query private var classes: [ClassSchedule]
    @State private var showAddSemester = false
    @State private var editingSemester: Semester?

    var body: some View {
        NavigationStack {
            List {
                ForEach(semesters) { semester in
                    Button {
                        editingSemester = semester
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(semester.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(semester.formattedRange)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if semester.isActive {
                                Text("Active")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor, in: Capsule())
                                    .foregroundStyle(.white)
                            } else {
                                Button("Activate") {
                                    activate(semester)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSemesters)
            }
            .navigationTitle("Semesters")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSemester = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSemester) {
                SemesterEditView(existingSemester: nil)
            }
            .sheet(item: $editingSemester) { semester in
                SemesterEditView(existingSemester: semester)
            }
        }
    }

    private func activate(_ semester: Semester) {
        Semester.activate(semester, among: semesters)
        NotificationManager.shared.syncNotifications(for: classes)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteSemesters(at offsets: IndexSet) {
        for index in offsets {
            let semester = semesters[index]
            for classSchedule in semester.classes {
                NotificationManager.shared.cancelNotifications(for: classSchedule)
            }
            modelContext.delete(semester)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct SemesterEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allSemesters: [Semester]

    let existingSemester: Semester?

    @State private var name: String
    @State private var startDate: Date
    @State private var endDate: Date

    init(existingSemester: Semester?) {
        self.existingSemester = existingSemester
        _name = State(initialValue: existingSemester?.name ?? "")
        _startDate = State(initialValue: existingSemester?.startDate ?? Date())
        _endDate = State(
            initialValue: existingSemester?.endDate
                ?? Calendar.current.date(byAdding: .weekOfYear, value: 16, to: Date())
                ?? Date()
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Fall 2026)", text: $name)
                    DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                    DatePicker("Ends", selection: $endDate, displayedComponents: .date)
                    if endDate < startDate {
                        Text("End date must be after the start date.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(existingSemester == nil ? "New Semester" : "Edit Semester")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || endDate < startDate)
                }
            }
        }
    }

    private func save() {
        if let existingSemester {
            existingSemester.name = name
            existingSemester.startDate = startDate
            existingSemester.endDate = endDate
            NotificationManager.shared.syncNotifications(for: existingSemester.classes)
        } else {
            let semester = Semester(
                name: name,
                startDate: startDate,
                endDate: endDate,
                isActive: allSemesters.isEmpty
            )
            modelContext.insert(semester)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

#Preview {
    SemesterListView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
