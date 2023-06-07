//
//  JarvisApp.swift
//  Jarvis
//
//  Created by Jon Wingfield on 5/6/23.
//

import SwiftUI
import OpenAI

@main
struct JarvisApp: App {
    let persistenceController = PersistenceController.shared
    
    let openAI = OpenAI(apiToken: "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")

    var body: some Scene {
        WindowGroup {
            ContentView(chatViewModel: ChatViewModel(openAI: openAI))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
