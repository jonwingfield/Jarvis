//
//  ChatViewModelProtocol.swift
//  Jarvis
//
//  Created by Jon Wingfield on 5/6/23.
//

import Foundation

protocol ChatViewModelProtocol: ObservableObject {
    func fetchResponse(prompt: String)
}
