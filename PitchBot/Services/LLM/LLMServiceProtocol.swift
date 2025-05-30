//
//  LLMServiceProtocol.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation
import Combine

/// 定义LLM服务的错误类型
enum LLMServiceError: Error {
    case invalidAPIKey
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknownError
}

/// LLM服务类型枚举
enum LLMServiceType: String, CaseIterable {
    case minimax = "MiniMax"
    case openai = "OpenAI Compatible"
}

/// LLM服务协议，定义所有LLM服务必须实现的方法
protocol LLMServiceProtocol {
    /// 检查是否有有效的API密钥
    var hasAPIKey: Bool { get }

    /// 获取LLM服务的类型
    var serviceType: LLMServiceType { get }
    
    /// 发送消息并获取回复
    /// - Parameter messages: 聊天消息数组
    /// - Returns: 包含响应字符串的Publisher
    func sendMessage(messages: [ChatMessage]) -> AnyPublisher<String, Error>
    
    /// 生成对话评估结果
    /// - Parameter conversation: 聊天消息数组
    /// - Returns: 包含评估结果的Publisher
    func generateEvaluation(conversation: [ChatMessage]) -> AnyPublisher<EvaluationResult, Error>

    /// update API key
    /// - Parameter apiKey: API key
    func updateAPIKey(_ apiKey: String)
}

/// 为LLMServiceProtocol提供默认实现
extension LLMServiceProtocol {
    /// 默认的评估生成实现，使用sendMessage并解析结果
    func generateEvaluation(conversation: [ChatMessage]) -> AnyPublisher<EvaluationResult, Error> {
        // 创建评估系统提示
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
                    Please provide your evaluation in JSON format with the following structure:
                    {
                        "objectionHandlingScore": 1-5,
                        "nextStepScore": 1-5, 
                        "feedback": "Your feedback here"
                        "summaryPoints": ["Your summary points here"]
                    }
                    """
        )
        
        var evaluationMessages = [systemPrompt]
        // 移除conversation中的第一个系统提示，只添加后续对话内容
        evaluationMessages.append(contentsOf: Array(conversation.dropFirst()))
        
        // 使用sendMessage获取AI回复，然后解析为EvaluationResult
        return sendMessage(messages: evaluationMessages)
            .tryMap { jsonMarkdownString -> EvaluationResult in
                // 移除JSON字符串前后的```json和```标记
                let jsonString = jsonMarkdownString
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let jsonData = Data(jsonString.utf8)
                return try JSONDecoder().decode(EvaluationResult.self, from: jsonData)
            }
            .eraseToAnyPublisher()
    }
}