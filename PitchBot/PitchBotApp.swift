//
//  PitchBotApp.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI
import Combine

@main
struct PitchBotApp: App {
    // LLMServiceManager as a singleton EnvironmentObject
    @StateObject private var llmServiceManager = LLMServiceManager(serviceType: .openai)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(llmServiceManager)
        }
    }
}
