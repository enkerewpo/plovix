//
//  PlovixApp.swift
//  Plovix
//
//  Created by Mr wheatfox on 2025/3/26.
//

import SwiftUI
import SwiftData

@main
struct PlovixApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MailingList.self,
            Message.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
