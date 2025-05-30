//
//  LLMServiceManager.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation
import SwiftUI
import Combine

/// LLM服务管理器，用于管理和切换不同的LLM服务
class LLMServiceManager: ObservableObject {
    /// 当前选择的服务类型
    @Published var currentServiceType: LLMServiceType
    
    /// 存储MiniMax API密钥
    @AppStorage("minimax_api_key") private var minimaxAPIKey: String = ""
    
    /// 存储MiniMax Group ID
    @AppStorage("minimax_group_id") private var minimaxGroupID: String = ""
    
    /// 存储OpenAI API密钥
    @AppStorage("openai_api_key") private var openaiAPIKey: String = ""
    
    /// 当前使用的LLM服务实例
    private(set) var currentService: LLMServiceProtocol
    
    // 用于存储Combine订阅
    var cancellables = Set<AnyCancellable>()
    
    init() {
        self.currentService = LLMServiceFactory.createService(type: .minimax)
        self.currentServiceType = .minimax
    }
    
    /// 初始化服务管理器
    /// - Parameter serviceType: 初始服务类型，默认为MiniMax
    convenience init(serviceType: LLMServiceType = .minimax) {
        self.init()
        self.currentService = LLMServiceFactory.createService(
            type: serviceType,
            apiKey: serviceType == .minimax ? minimaxAPIKey : openaiAPIKey
        )
        self.currentServiceType = serviceType
    }
    
    /// 切换到指定类型的LLM服务
    /// - Parameter type: 目标服务类型
    func switchService(to type: LLMServiceType) {
        currentService = LLMServiceFactory.createService(
            type: type,
            apiKey: type == .minimax ? minimaxAPIKey : openaiAPIKey
        )
        currentServiceType = type
        
        NotificationCenter.default.post(name: .changeLLMService, object: currentService)

    }
    
    /// 更新指定服务类型的API密钥
    /// - Parameters:
    ///   - type: 服务类型
    ///   - apiKey: 新的API密钥
    func updateAPIKey(for type: LLMServiceType, apiKey: String) {
        switch type {
        case .minimax:
            minimaxAPIKey = apiKey
        case .openai:
            openaiAPIKey = apiKey
        }
        
        // 如果更新的是当前使用的服务类型，则重新创建服务实例
        if type == currentServiceType {
//            currentService = LLMServiceFactory.createService(type: type, apiKey: apiKey)
            currentService.updateAPIKey(apiKey)
        }
    }
    
    /// 更新MiniMax的Group ID
    /// - Parameters:
    ///   - type: 服务类型
    ///   - groupID: 新的Group ID
    func updateGroupID(for type: LLMServiceType, groupID: String) {
        if type == .minimax {
            minimaxGroupID = groupID
        }
    }
    
    /// 获取指定服务类型的Group ID
    /// - Parameter type: 服务类型
    /// - Returns: Group ID
    func getGroupID(for type: LLMServiceType) -> String {
        if type == .minimax {
            return minimaxGroupID
        }
        return ""
    }
    
    /// 获取指定服务类型的API密钥
    /// - Parameter type: 服务类型
    /// - Returns: API密钥
    func getAPIKey(for type: LLMServiceType) -> String {
        switch type {
        case .minimax:
            return minimaxAPIKey
        case .openai:
            return openaiAPIKey
        }
    }
}
