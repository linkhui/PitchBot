//
//  OpenAIService.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation
import Combine

class OpenAIService: LLMServiceProtocol {
    var apiKey: String
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    private let model = "deepseek-ai/DeepSeek-V3"
    
    init(apiKey: String = "") {
        if apiKey.isEmpty {
            self.apiKey = ""
        } else {
            self.apiKey = apiKey
        }
    }
    
    var hasAPIKey: Bool {
        return !apiKey.isEmpty
    }

    func updateAPIKey(_ apiKey: String) {
        self.apiKey = apiKey
    }

    var serviceType: LLMServiceType {
        return .openai
    }
    
    func sendMessage(messages: [ChatMessage]) -> AnyPublisher<String, Error> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: LLMServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        guard hasAPIKey else {
            return Fail(error: LLMServiceError.invalidAPIKey).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 将ChatMessage转换为OpenAI格式的消息
        let openAIMessages = messages.map { message in
            return OpenAIMessage(role: message.role, content: message.content)
        }
        
        let requestBody = OpenAIRequest(
            model: model,
            messages: openAIMessages,
            temperature: 0.7
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return Fail(error: LLMServiceError.unknownError).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMServiceError.networkError(URLError(.badServerResponse))
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw LLMServiceError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "Unknown error")
                }
                return data
            }
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    return LLMServiceError.decodingError(decodingError)
                } else {
                    return error
                }
            }
            .map { $0.choices.first?.message.content ?? "" }
            .eraseToAnyPublisher()
    }
}

// OpenAI API 请求和响应模型
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Codable {
        let index: Int
        let message: OpenAIMessage
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
