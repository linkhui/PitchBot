//
//  LLMServiceFactory.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation

/// LLM服务工厂类，用于创建不同类型的LLM服务实例
class LLMServiceFactory {
    /// 创建LLM服务实例
    /// - Parameters:
    ///   - type: 服务类型
    ///   - apiKey: API密钥，如果为空则使用环境变量或默认值
    /// - Returns: 符合LLMServiceProtocol的服务实例
    static func createService(type: LLMServiceType, apiKey: String = "") -> LLMServiceProtocol {
        switch type {
        case .minimax:
            return MinimaxService(apiKey: apiKey)
        case .openai:
            return OpenAIService(apiKey: apiKey)
        }
    }
}
