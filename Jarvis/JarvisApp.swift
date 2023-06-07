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
    
    let openAI = OpenAI(apiToken: Tokens.OpenAI)

    var body: some Scene {
        WindowGroup {
            ContentView(chatModel: ChatModel(openAI: openAI))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
