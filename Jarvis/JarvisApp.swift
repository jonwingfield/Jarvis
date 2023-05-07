//
//  JarvisApp.swift
//  Jarvis
//
//  Created by Jon Wingfield on 5/6/23.
//

import SwiftUI

@main
struct JarvisApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
