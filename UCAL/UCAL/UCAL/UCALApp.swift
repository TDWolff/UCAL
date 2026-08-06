//
//  UCALApp.swift
//  UCAL
//
//  Created by Torin Wolff on 8/6/26.
//

import SwiftUI
import SwiftData

@main
struct UCALApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ClassSchedule.self)
    }
}
