//
//  ClassFormView.swift
//  UCAL
//

import SwiftUI
import SwiftData

struct ClassFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var semesters: [Semester]

    private let existingClass: ClassSchedule?

    @State private var name: String
    @State private var location: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedDays: Set<Weekday>
    @State private var reminderMinutesBefore: Int
    @State private var timeZoneIdentifier: String
    @State private var colorTag: ClassColor
    @State private var showDayPicker = false
    @State private var showTimeZonePicker = false

    init(existingClass: ClassSchedule? = nil) {
        self.existingClass = existingClass
        _name = State(initialValue: existingClass?.name ?? "")
        _location = State(initialValue: existingClass?.location ?? "")
        _startTime = State(initialValue: existingClass?.startTime ?? Date())
        _endTime = State(initialValue: existingClass?.endTime ?? Date().addingTimeInterval(3600))
        _selectedDays = State(initialValue: existingClass?.weekdays ?? [])
        _reminderMinutesBefore = State(initialValue: existingClass?.reminderMinutesBefore ?? 10)
        _timeZoneIdentifier = State(initialValue: existingClass?.timeZoneIdentifier ?? TimeZone.current.identifier)
        _colorTag = State(initialValue: existingClass?.colorTag ?? .blue)
    }

    private var daysSummary: String {
        selectedDays.isEmpty
            ? "Select days"
            : Weekday.allCases.filter(selectedDays.contains).map(\.shortName).joined(separator: ", ")
    }

    private var timeZoneSummary: String {
        TimeZonePickerSheet.displayName(for: timeZoneIdentifier)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class name", text: $name)
                    TextField("Location (optional)", text: $location)
                }

                Section("Color") {
                    HStack {
                        ForEach(ClassColor.allCases) { option in
                            Button {
                                colorTag = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        if colorTag == option {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)

                    Button {
                        showTimeZonePicker = true
                    } label: {
                        HStack {
                            Text("Time Zone")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(timeZoneSummary)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Recurrence") {
                    Button {
                        showDayPicker = true
                    } label: {
                        HStack {
                            Text("Repeat on")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(daysSummary)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Stepper(
                        "Remind me \(reminderMinutesBefore) min before",
                        value: $reminderMinutesBefore,
                        in: 0...60,
                        step: 5
                    )
                }
            }
            .navigationTitle(existingClass == nil ? "New Class" : "Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingClass == nil ? "Save" : "Save Changes") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedDays.isEmpty)
                }
            }
            .sheet(isPresented: $showDayPicker) {
                DayPickerSheet(selectedDays: $selectedDays)
            }
            .sheet(isPresented: $showTimeZonePicker) {
                TimeZonePickerSheet(timeZoneIdentifier: $timeZoneIdentifier)
            }
        }
    }

    private func save() {
        if let existingClass {
            existingClass.name = name
            existingClass.location = location
            existingClass.startTime = startTime
            existingClass.endTime = endTime
            existingClass.weekdays = selectedDays
            existingClass.reminderMinutesBefore = reminderMinutesBefore
            existingClass.timeZoneIdentifier = timeZoneIdentifier
            existingClass.colorTag = colorTag
            NotificationManager.shared.scheduleNotifications(for: existingClass)
        } else {
            let newClass = ClassSchedule(
                name: name,
                location: location,
                startTime: startTime,
                endTime: endTime,
                weekdays: selectedDays,
                reminderMinutesBefore: reminderMinutesBefore,
                timeZoneIdentifier: timeZoneIdentifier,
                colorTag: colorTag
            )
            newClass.semester = Semester.activeOrCreate(existing: semesters, context: modelContext)
            modelContext.insert(newClass)
            NotificationManager.shared.scheduleNotifications(for: newClass)
        }
        dismiss()
    }
}

private struct DayPickerSheet: View {
    @Binding var selectedDays: Set<Weekday>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Weekday.allCases) { day in
                Button {
                    toggle(day)
                } label: {
                    HStack {
                        Text(day.fullName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedDays.contains(day) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Repeat On")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func toggle(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

struct TimeZonePickerSheet: View {
    @Binding var timeZoneIdentifier: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredIdentifiers: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.localizedCaseInsensitiveContains(searchText) ||
            (TimeZone(identifier: $0)?.abbreviation()?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredIdentifiers, id: \.self) { identifier in
                Button {
                    timeZoneIdentifier = identifier
                    dismiss()
                } label: {
                    HStack {
                        Text(Self.displayName(for: identifier))
                            .foregroundStyle(.primary)
                        Spacer()
                        if identifier == timeZoneIdentifier {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search city or abbreviation")
            .navigationTitle("Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    static func displayName(for identifier: String) -> String {
        guard let timeZone = TimeZone(identifier: identifier) else { return identifier }
        let abbreviation = timeZone.abbreviation() ?? ""
        let name = identifier.replacingOccurrences(of: "_", with: " ")
        return abbreviation.isEmpty ? name : "\(name) (\(abbreviation))"
    }
}

#Preview {
    ClassFormView()
        .modelContainer(for: [ClassSchedule.self, Semester.self], inMemory: true)
}
