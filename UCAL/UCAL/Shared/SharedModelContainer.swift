//
//  SharedModelContainer.swift
//  UCAL
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.torinwolff.UCAL"

    static let shared: ModelContainer = {
        let schema = Schema([ClassSchedule.self, Semester.self])

        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Could not resolve App Group container for \(appGroupIdentifier)")
        }

        let storeURL = groupURL.appendingPathComponent("UCAL.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
