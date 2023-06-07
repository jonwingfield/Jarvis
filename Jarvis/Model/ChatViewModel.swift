//
//  ChatViewModel.swift
//  Jarvis
//
//  Created by Jon Wingfield on 5/6/23.
//

import Foundation
import OpenAI
import AVFoundation

@MainActor class ChatViewModel: NSObject, ObservableObject {
    @Published var messages: [Chat] = []
    @Published var isSpeaking: Bool = false
    var openAI: OpenAI
    var finalUtterance: AVSpeechUtterance?
    private var speechSynthesizer = AVSpeechSynthesizer()
    
    init(openAI: OpenAI) {
        self.openAI = openAI
        super.init()
        self.speechSynthesizer.delegate = self
    }
    
    func fetchResponse(prompt: String) async throws {
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let userChat = Chat(role: .user, content: prompt)
        messages.append(userChat)
        let query = ChatQuery(model: .gpt3_5Turbo, messages: messages)
        
        var message = ""
        var delta = ""
        isSpeaking = true
        
        messages.append(Chat(role: .system, content: ""))
        
        for try await result in openAI.chatsStream(query: query) {
            if !isSpeaking { return }
            
            if let choice = result.choices.first {
                if let content = choice.delta.content {
                    delta += content
                    message += content
                    _ = messages.popLast()
                    messages.append(Chat(role: .system, content: message))
                    if delta.count > 30 && !speechSynthesizer.isSpeaking {
                        print(delta)
                        let utterance = AVSpeechUtterance(string: delta)
                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        speechSynthesizer.speak(utterance)
                        delta = ""
                    }
                }
            }
        }
        
        if !isSpeaking {
            return
        }

        if delta.count > 0 {
            if speechSynthesizer.isSpeaking {
                try await Task.sleep(for: .milliseconds(100))
            }

            let utterance = AVSpeechUtterance(string: delta)
            finalUtterance = utterance
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        isSpeaking = false
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

extension ChatViewModel : AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }
        
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        self.isSpeaking = false
        print("didCancel speaking")

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance == finalUtterance {
            print("didFinish speaking")
            self.isSpeaking = false
            finalUtterance = Optional.none
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
