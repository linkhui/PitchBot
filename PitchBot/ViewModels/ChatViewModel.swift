//
//  ChatViewModel.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation
import SwiftUI
import Combine

struct ResponseResult: Codable {
    let endConversation: Bool
    let message: String
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var systemMessages: [SystemMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var showEvaluation: Bool = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var isConversationEnded: Bool = false
    
    private let maxChatCount = 4
    private var userMessageCount = 0
    private var cancellables = Set<AnyCancellable>()
    private var llmService: LLMServiceProtocol
    
    init(llmService: LLMServiceProtocol = LLMServiceFactory.createService(type: .openai)) {
        self.llmService = llmService
        
        // 设置系统提示
        let systemPrompt = ChatMessage(
            role: "system",
            content: """
                You are Taylor, a marketing manager at a mid-sized B2B company.
                Someone has just reached out offering marketing services. You're not currently looking for help, so you begin by saying:
                "Hey, I'm not really looking for anything right now — what's this about?"
                You:
                - Don't want to waste time
                - Expect clear, simple explanations
                - Dislike generic or pushy messages
                - Will end the conversation if it's not helpful
                - Will agree to a short next step (call or email) if the person asks good questions and explains their value clearly
                - Respond like a real person. Change your answers based on how the other person performs. End the conversation after 5 replies, or sooner if needed.
                ---
                    Please provide in JSON format with the following structure:
                    {
                        "endConversation": true or false,
                        "message": "Your message here",
                    }
                """
        )
        
        chatMessages.append(systemPrompt)
        
        // Greetings
        let initialMessage = "Hey, I'm not really looking for anything right now — what's this about?"
        addMessage(text: initialMessage, isUser: false)
        
        // add AI's initial message to chatMessages
        chatMessages.append(ChatMessage(role: "assistant", content: initialMessage))
        
        NotificationCenter.default.addObserver(forName: .dismissEvaluation, object: nil, queue: .main) { [weak self] _ in
            self?.showEvaluation = false
        }
        
        NotificationCenter.default.addObserver(forName: .changeLLMService, object: nil, queue: .main) { [weak self] notif in
            if let service = notif.object as? LLMServiceProtocol {
                self?.updateLLMService(service)
            }
        }
    }
    
    // update LLM service
    func updateLLMService(_ service: LLMServiceProtocol) {
        self.llmService = service
        print("ChatViewModel: LLM service updated to \(service)")
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        addMessage(text: userMessage, isUser: true)
        
        // add user's message to chatMessages
        chatMessages.append(ChatMessage(role: "user", content: userMessage))
        
        inputText = ""
        userMessageCount += 1
        
        isTyping = true
        
        getAIResponse()
    }
    
    private func getAIResponse() {
        // Check if the LLM service has an API key
        if llmService.hasAPIKey {
            llmService.sendMessage(messages: chatMessages)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error: \(error.localizedDescription)")
                        self?.handleAPIError()
                    }
                }, receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    var content = response
                    print("AI Response from \(llmService.serviceType): \(response)")
                                        
                    var wantToEnd = false
                    // 提取 JSON 部分
                    let jsonRegex = try? NSRegularExpression(pattern: "```json(.*?)```", options: .dotMatchesLineSeparators)
                    let matches = jsonRegex?.matches(in: response, range: NSRange(location: 0, length: response.utf16.count))
                    if let match = matches?.first {
                        let range = Range(match.range(at: 1), in: response)
                        if let jsonString = range.map({ String(response[$0]) }) {
                            let jsonData = Data(jsonString.utf8)
                            let responseResult = try? JSONDecoder().decode(ResponseResult.self, from: jsonData)
                            content = responseResult?.message ?? "Sorry, There is something wrong."
                            wantToEnd = responseResult?.endConversation ?? false
                        }
                    } else {
                        let jsonData = Data(response.utf8)
                        let responseResult = try? JSONDecoder().decode(ResponseResult.self, from: jsonData)
                        content = responseResult?.message ?? response
                        wantToEnd = responseResult?.endConversation ?? false
                    }

                    self.isTyping = false
                    let newMessage = Message(text: content, isUser: false)
                    self.messages.append(newMessage)
                    self.chatMessages.append(ChatMessage(role: "assistant", content: content))
                    
                    // auto play AI reply's voice
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: .playLatestAIMessage, object: content)
                    }
                    
                    // check if we should end the conversation
                    if wantToEnd {
                        self.endConversation(reason: "Talor wants to end the conversation")
                    } else if self.userMessageCount >= self.maxChatCount {
                        self.endConversation(reason: "Reached the maximum number of messages")
                    }
                })
                .store(in: &cancellables)
        } else {
            simulateAIResponse()
        }
    }
    
    private func handleAPIError() {
        isTyping = false
        let errorMessage = "Sorry, I'm having trouble connecting. Let's try again later."
        addMessage(text: errorMessage, isUser: false)
        chatMessages.append(ChatMessage(role: "assistant", content: errorMessage))
    }
    
    private func simulateAIResponse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double.random(in: 0.5...1.5)) { [weak self] in
            guard let self = self else { return }
            
            self.isTyping = false
            let aiResponse = self.generateMockResponse()
            let newMessage = Message(text: aiResponse, isUser: false)
            self.messages.append(newMessage)
            self.chatMessages.append(ChatMessage(role: "assistant", content: aiResponse))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .playLatestAIMessage, object: aiResponse)
            }
            
            if self.userMessageCount >= maxChatCount {
                self.endConversation(reason: "Reached the maximum number of messages")
            }
        }
    }
    
    private func generateMockResponse() -> String {
        let responses = [
            "That sounds interesting! Tell me more about your target customer.",
            "What's the main problem your product solves?",
            "How do you typically handle price objections?",
            "That's a good approach. What would you say if they said it's too expensive?",
            "I might be interested. Can you send me some more information or schedule a quick call?"
        ]
        
        if userMessageCount <= responses.count {
            return responses[userMessageCount - 1]
        } else {
            return "Thanks for the information. Let me think about it and get back to you."
        }
    }
    
    func addMessage(text: String, isUser: Bool) {
        let newMessage = Message(text: text, isUser: isUser)
        messages.append(newMessage)
    }
    
    func addSystemMessage(text: String, evaluationData: [ChatMessage]? = nil) {
        let systemMessage = SystemMessage(text: text, evaluationData: evaluationData)
        systemMessages.append(systemMessage)
    }
    
    func endConversation(reason: String) {
        // add system message to indicate the conversation has ended
        addSystemMessage(text: "Conversation ended (\(reason)). Click to view evaluation results", evaluationData: chatMessages)

        isConversationEnded = true
    }
    
    func showEvaluationForSystemMessage(_ message: SystemMessage) {
        if message.evaluationData != nil {
            showEvaluation = true
        }
    }
    
    func restartConversation() {
        // Stop any ongoing speech synthesis
        NotificationCenter.default.post(name: .stopSpeech, object: nil)
        
        messages = []
        systemMessages = []
        userMessageCount = 0
        showEvaluation = false
        isConversationEnded = false
        
        // reset chatMessages，keep the prompt system message
        let systemPrompt = chatMessages.first
        chatMessages = []
        if let systemPrompt = systemPrompt {
            chatMessages.append(systemPrompt)
        }
        
        // add AI's initial message to chatMessages
        let initialMessage = "Hey, I'm not really looking for anything right now — what's this about?"
        addMessage(text: initialMessage, isUser: false)
        chatMessages.append(ChatMessage(role: "assistant", content: initialMessage))
    }
}

extension Notification.Name {
    static let playLatestAIMessage = Notification.Name("playLatestAIMessage")
    static let dismissEvaluation = Notification.Name("dismissEvaluation")
    static let stopSpeech = Notification.Name("stopSpeech")
    static let changeLLMService = Notification.Name("changeLLMService")
}
