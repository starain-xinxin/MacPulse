//
//  MacPulseApp.swift
//  MacPulse
//
//  Created by 袁新宇 on 2026/6/8.
//

import SwiftUI
import CoreData

@main
struct MacPulseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
