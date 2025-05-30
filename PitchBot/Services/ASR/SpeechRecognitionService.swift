//
//  SpeechRecognitionService.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation
import Speech
import Combine

class SpeechRecognitionService: ObservableObject {
    // 发布识别状态和结果
    @Published var isRecognizing = false
    @Published var recognizedText = ""
    @Published var errorMessage: String? = nil
    
    // 语音识别器
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        // 初始化语音识别器，使用设备当前语言
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    }
    
    // 检查语音识别权限
    func checkSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    // 从音频文件识别文本
    func recognizeText(from audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // 重置状态
        isRecognizing = true
        recognizedText = ""
        errorMessage = nil
        
        // 检查权限
        checkSpeechRecognitionPermission { [weak self] granted in
            guard let self = self else { return }
            
            if !granted {
                self.errorMessage = "需要语音识别权限"
                self.isRecognizing = false
                completion(.failure(NSError(domain: "SpeechRecognitionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "需要语音识别权限"])))
                return
            }
            
            // 确保语音识别器可用
            guard let speechRecognizer = self.speechRecognizer, speechRecognizer.isAvailable else {
                self.errorMessage = "语音识别器不可用"
                self.isRecognizing = false
                completion(.failure(NSError(domain: "SpeechRecognitionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "语音识别器不可用"])))
                return
            }
            
            // 创建识别请求
            let recognitionRequest = SFSpeechURLRecognitionRequest(url: audioURL)
            recognitionRequest.shouldReportPartialResults = true
            
            // 开始识别任务
            self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "识别错误: \(error.localizedDescription)"
                    self.isRecognizing = false
                    completion(.failure(error))
                    return
                }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self.isRecognizing = false
                        completion(.success(self.recognizedText))
                    }
                }
            }
        }
    }
    
    // 取消识别任务
    func cancelRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecognizing = false
    }
    
    // 模拟识别（用于开发测试）
    func simulateRecognition(completion: @escaping (Result<String, Error>) -> Void) {
        // 模拟处理延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.recognizedText = "I have many cavities in my teeth, how can I prevent them?"
            completion(.success(self.recognizedText))
        }
    }
}
