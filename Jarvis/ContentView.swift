//
//  ContentView.swift
//  Jarvis
//
//  Created by Jon Wingfield on 5/6/23.
//

import SwiftUI
import CoreData
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject private var chatViewModel: ChatViewModel

    
    init(chatViewModel: ChatViewModel) {
        self.chatViewModel = chatViewModel
    }
    
    @State private var prompt: String = ""
    @State private var disabled: Bool = false
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State private var transcribing = false
    @State private var timer: Timer?
    
    
    func submitPrompt(_ prompt: String) async throws {
        disabled = true
        defer {
            disabled = false
        }
        try await self.chatViewModel.fetchResponse(prompt: prompt)
        self.prompt = ""
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { value in
                    VStack {
                        ForEach(chatViewModel.messages, id: \.content) { message in
                            ZStack {
                                message.role == .user ? Color.white : Color(red: 0.9, green: 0.9, blue: 0.9)
                                Text(message.content).padding().frame(
                                    minWidth: 0,
                                    maxWidth: .infinity,
                                    alignment: .topLeading
                                )
                            }
                        }
                        Text("").id("_bottom_")
                    }
                    .onChange(of: chatViewModel.messages) { _ in
                        value.scrollTo("_bottom_", anchor: .bottom)
                    }
                    .onChange(of: chatViewModel.isSpeaking) {_ in
                        value.scrollTo("_bottom_", anchor: .bottom)
                    }
                }
            }

            
            ZStack {
                Color.white
                if transcribing {
                    LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                        .mask(Image(systemName: "mic.fill").resizable().scaledToFit().frame(maxWidth: 40))
                } else {
                    if disabled {
                        Section {
                            ProgressView().background(Color.white).frame(width: 40, height: 40)
                                .scaleEffect(2)
                        }
                    } else {
                        Image(systemName: "mic.fill").resizable().scaledToFit().frame(maxWidth: 40)
                    }
                }
                    
            }.frame(maxHeight:40)
            .onTapGesture {
                chatViewModel.stopSpeaking()
                
                if !transcribing {
                    speechRecognizer.startTranscribing()
                    transcribing = true
                    
                    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                        stopTranscribing()
                    }

                } else {
                    stopTranscribing()
                }
            }
            .onChange(of: chatViewModel.isSpeaking) { _ in
                if !chatViewModel.isSpeaking {
                    speechRecognizer.startTranscribing()
                    transcribing = true
                }
            }
            .onChange(of: speechRecognizer.transcript) { _ in
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    stopTranscribing()
                }
            }

            
            HStack(alignment: .center) {
                TextField("Prompt", text: $prompt).disabled(disabled).onSubmit {
                    Task { try await submitPrompt(prompt) }
                }.onChange(of: speechRecognizer.transcript) { _ in
                    prompt = speechRecognizer.transcript
                }
                
                Button("Submit") {
                    Task { try await submitPrompt(prompt) }
                }.disabled(disabled)
            }.frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                .background(Color.white)
                .padding()
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        
    }
    
    func stopTranscribing() {
        timer?.invalidate()
        timer = Optional.none
        speechRecognizer.stopTranscribing()
        let prompt = speechRecognizer.transcript
        transcribing = false
        
        if !prompt.isEmpty {
            Task {
                try await submitPrompt(prompt)
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(chatViewModel: ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
