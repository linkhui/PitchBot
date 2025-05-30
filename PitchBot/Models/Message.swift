//
//  Message.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    // message id
    var idString: String {
        id.uuidString
    }
    
    init(text: String, isUser: Bool, timestamp: Date = Date()) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp
    }
}

