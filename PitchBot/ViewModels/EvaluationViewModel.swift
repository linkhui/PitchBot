//
//  EvaluationViewModel.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation
import Combine

struct EvaluationResult: Codable {
    let objectionHandlingScore: Int
    let nextStepScore: Int
    let feedback: String
    let summaryPoints: [String]
}

class EvaluationViewModel: ObservableObject {
    @Published var evaluationResult: EvaluationResult?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    let llmService: LLMServiceProtocol
    
    var hasAPIKey: Bool {
        return llmService.hasAPIKey
    }
    
    init(llmService: LLMServiceProtocol = LLMServiceFactory.createService(type: .minimax, apiKey: LLMServiceManager().getAPIKey(for: .minimax))) {
        self.llmService = llmService
    }
    
    func generateEvaluation(conversation: [ChatMessage]) {

        if !hasAPIKey {
            generateMockEvaluation()
            return
        }
        
        isLoading = true
        error = nil
        
        let systemPrompt = ChatMessage(
            role: "system",
            content: """
                    You are a conversation evaluator reviewing a cold outreach chat between a m
                    arketing service provider and a potential client named Taylor.
                    Your job is to give feedback on how well the user handled the conversation.
                    Specifically, review two things:
                    1. Did the user respond well to the objection: "I'm not really looking for anythin
                    g right now"?
                    2. Did the user successfully establish a clear next step (like suggesting or sec
                    uring a follow-up call or email)?
                    Give a score from 1 to 5 for each:
                    - Objection handling (1 = poor, 5 = excellent)
                    - Next step (1 = no clear step, 5 = strong close)
                    Then provide 1–2 short sentences of feedback.
                    ---
                    Must reply in JSON format with the following structure:
                    {
                        "objectionHandlingScore": 1-5,
                        "nextStepScore": 1-5, 
                        "feedback": "Your feedback here"
                        "summaryPoints": ["Your summary points here"]
                    }
                    """
        )
        
        var evaluationMessages = [systemPrompt]
        
        // remove the first message (system prompt) from the conversation
        evaluationMessages.append(contentsOf: Array(conversation.dropFirst()))
        
        llmService.sendMessage(messages: evaluationMessages)
            .receive(on: DispatchQueue.main)
            .tryMap { jsonMarkdownString -> EvaluationResult in
                // remove ```json and ```

                // 提取 JSON 部分 (假设 JSON 部分在 ```json 和 ``` 之间) ，使用正则表达式
                let jsonRegex = try NSRegularExpression(pattern: "```json(.*?)```", options: .dotMatchesLineSeparators)
                let matches = jsonRegex.matches(in: jsonMarkdownString, range: NSRange(location: 0, length: jsonMarkdownString.utf16.count))
                if let match = matches.first {
                    let range = Range(match.range(at: 1), in: jsonMarkdownString)
                    if let jsonString = range.map({ String(jsonMarkdownString[$0]) }) {
                        return try JSONDecoder().decode(EvaluationResult.self, from: Data(jsonString.utf8))
                    }
                }

                throw LLMServiceError.unknownError
            }
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error
                    print("Evaluation Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] result in
                self?.evaluationResult = result
            })
            .store(in: &cancellables)
    }
    
    func generateMockEvaluation() {
        isLoading = true
        error = nil
        
        // Simulate a delay for the mock evaluation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate evaluation results
            let objectionScore = Int.random(in: 3...5)
            let nextStepScore = Int.random(in: 2...5)
            
            let feedback = "Great job handling the customer's initial concerns! You showed empathy and provided relevant solutions. However, your next steps could be more specific - try suggesting concrete dates and follow-up actions."
            
            let summaryPoints = [
                "You effectively addressed the customer's concerns about pricing by highlighting the value proposition.",
                "Your explanation of product features was clear and focused on benefits rather than just specifications.",
                "You maintained a professional tone throughout the conversation.",
                "Area for improvement: Be more specific when setting up next steps - include timeline and clear action items."
            ]
            
            self.evaluationResult = EvaluationResult(
                objectionHandlingScore: objectionScore,
                nextStepScore: nextStepScore,
                feedback: feedback,
                summaryPoints: summaryPoints
            )
            
            self.isLoading = false
        }
    }
    
    func reset() {
        evaluationResult = nil
        error = nil
        isLoading = false
    }
}
