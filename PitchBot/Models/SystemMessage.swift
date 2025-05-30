//
//  Message.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/29.
//

import Foundation

struct SystemMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let evaluationData: [ChatMessage]?
    
    // message id
    var idString: String {
        id.uuidString
    }
    
    init(text: String, evaluationData: [ChatMessage]? = nil, timestamp: Date = Date()) {
        self.text = text
        self.timestamp = timestamp
        self.evaluationData = evaluationData
    }
    
    static func == (lhs: SystemMessage, rhs: SystemMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.timestamp == rhs.timestamp
    }
}
