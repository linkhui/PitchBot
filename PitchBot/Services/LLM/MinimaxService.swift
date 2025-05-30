//
//  MinimaxService.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation
import Combine

class MinimaxService: LLMServiceProtocol {
    var apiKey: String
    private let baseURL = "https://api.minimax.chat/v1/text/chatcompletion_v2"
    
    init(apiKey: String = ProcessInfo.processInfo.environment["MINIMAX_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    func updateAPIKey(_ apiKey: String) {
        self.apiKey = apiKey
    }

    var hasAPIKey: Bool {
        return !apiKey.isEmpty
    }

    var serviceType: LLMServiceType {
        return .minimax
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
        
        let requestBody = MinimaxRequest(
            model: "abab6.5s-chat",
            messages: messages,
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
            .decode(type: MinimaxResponse.self, decoder: JSONDecoder())
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

// 请求和响应模型
struct MinimaxRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct MinimaxResponse: Codable {
    let id: String
    let choices: [Choice]
    let created: Int
    let model: String
    let object: String
    let usage: Usage
    let inputSensitive: Bool
    let outputSensitive: Bool
    let inputSensitiveType: Int
    let outputSensitiveType: Int
    let outputSensitiveInt: Int
    let baseResp: BaseResp
    
    enum CodingKeys: String, CodingKey {
        case id, choices, created, model, object, usage
        case inputSensitive = "input_sensitive"
        case outputSensitive = "output_sensitive"
        case inputSensitiveType = "input_sensitive_type"
        case outputSensitiveType = "output_sensitive_type"
        case outputSensitiveInt = "output_sensitive_int"
        case baseResp = "base_resp"
    }
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let content: String
        let role: String
        let name: String
        let audioContent: String
        
        enum CodingKeys: String, CodingKey {
            case content, role, name
            case audioContent = "audio_content"
        }
    }
    
    struct Usage: Codable {
        let totalTokens: Int
        let totalCharacters: Int
        let promptTokens: Int
        let completionTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case totalTokens = "total_tokens"
            case totalCharacters = "total_characters"
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
        }
    }
    
    struct BaseResp: Codable {
        let statusCode: Int
        let statusMsg: String
        
        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case statusMsg = "status_msg"
        }
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
