//
//  MinimaxTTSService.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation
import AVFoundation

class MinimaxTTSService: NSObject, ObservableObject {
    // 发布属性，用于UI绑定
    @Published var isSpeaking: Bool = false
    @Published var isMuted: Bool = false
    
    // 当前文本
    public var text = ""
    
    // Minimax API配置
    private var groupId: String = ""
    private var apiKey: String = ""
    private let baseURL: String = "https://api.minimax.chat/v1/t2a_v2"
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    private var audioData: Data?
    
    // 音频设置
    private let voiceId = "English_ReservedYoungMan"
    private let audioFormat = "mp3"
    
    // 任务管理
    private var currentTask: URLSessionDataTask?
    
    override init() {
        super.init()
        setupAudioSession()
        
        // 从LLMServiceManager获取API密钥和GroupID
        let serviceManager = LLMServiceManager()
        self.groupId = serviceManager.getGroupID(for: .minimax)
        self.apiKey = serviceManager.getAPIKey(for: .minimax)
        
        // 从UesrDefaults中获取静音状态
        isMuted = UserDefaults.standard.bool(forKey:"isMuted")
        
        // 添加停止语音播放的通知监听
        NotificationCenter.default.addObserver(forName: .stopSpeech, object: nil, queue: .main) { [weak self] _ in
            self?.stop()
        }
    }
    
    /// 更新GroupID
    /// - Parameter groupID: 新的GroupID
    func updateGroupID(_ groupID: String) {
        self.groupId = groupID
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } catch {
            print("无法设置音频会话: \(error.localizedDescription)")
        }
    }
    
    func speak(text: String) -> Bool {
        // 如果处于静音状态，不播放语音
        if isMuted {
            print("语音已静音，不播放")
            return false
        }
        
        // 确保API密钥已设置
        guard !groupId.isEmpty && !apiKey.isEmpty else {
            print("Minimax API密钥未设置")
            return false
        }
        
        // 每次播放前重新设置音频会话
        setupAudioSession()
        
        // 停止当前正在播放的语音
        stop()
        
        // 保存当前文本
        self.text = text
        
        // 创建URL请求
        guard let url = URL(string: "\(baseURL)?GroupId=\(groupId)") else {
            print("无效的URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 创建请求体
        let requestBody: [String: Any] = [
            "model": "speech-02-turbo",
            "text": text,
            "stream": false,  // 非流式请求，获取完整音频
            "voice_setting": [
                "voice_id": voiceId,
                "speed": 1.0,
                "vol": 1.0,
                "pitch": 0
            ],
            "audio_setting": [
                "sample_rate": 32000,
                "bitrate": 128000,
                "format": audioFormat,
                "channel": 1
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("创建请求体失败: \(error.localizedDescription)")
            return false
        }
        
        // 设置为正在说话状态
        isSpeaking = true
        print("开始请求Minimax TTS: \(text)")
        
        // 发送请求
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 在主线程更新UI状态
            DispatchQueue.main.async {
                if let error = error {
                    print("Minimax TTS请求失败: \(error.localizedDescription)")
                    self.isSpeaking = false
                    return
                }
                
                guard let data = data else {
                    print("Minimax TTS返回空数据")
                    self.isSpeaking = false
                    return
                }
                
                // 解析响应
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseData = json["data"] as? [String: Any],
                       let audioBase64 = responseData["audio"] as? String {
                        
                        if let audioData = Data(hexString: audioBase64) {
                            self.playAudio(data: audioData)
                        } else {
                            print("无法解码音频数据")
                            self.isSpeaking = false
                        }
                    } else {
                        print("无法解析Minimax TTS响应")
                        self.isSpeaking = false
                    }
                } catch {
                    print("解析Minimax TTS响应失败: \(error.localizedDescription)")
                    self.isSpeaking = false
                }
            }
        }
        
        currentTask?.resume()
        return true
    }
    
    private func playAudio(data: Data) {
        self.audioData = data
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0  // 设置音量为最大
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("开始播放Minimax TTS音频，音量：\(audioPlayer?.volume ?? 0)")
        } catch {
            print("创建音频播放器失败: \(error.localizedDescription)")
            isSpeaking = false
        }
    }
    
    func stop() {
        // 取消当前网络请求
        currentTask?.cancel()
        currentTask = nil
        
        // 停止音频播放
        if let player = audioPlayer, player.isPlaying {
            print("停止Minimax TTS音频播放")
            player.stop()
        }
        
        // 更新状态
        isSpeaking = false
    }
    
    func toggleMute() -> Bool {
        isMuted.toggle()
        
        // 如果切换到静音状态，停止当前播放
        if isMuted && (audioPlayer?.isPlaying == true) {
            stop()
        }
        
        // 保存静音状态到UserDefaults
        UserDefaults.standard.set(isMuted, forKey:"isMuted")

        return isMuted
    }
    
    deinit {
        // 清理音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("MinimaxTTSService 已释放，音频会话已停用")
        } catch {
            print("无法停用音频会话: \(error.localizedDescription)")
        }
    }
}

extension MinimaxTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Minimax TTS音频播放完成: \(flag ? "成功" : "失败")")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            // 重置音频播放器，确保下次播放时重新创建
            self?.audioPlayer = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Minimax TTS音频解码错误: \(error.localizedDescription)")
        }
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            // 重置音频播放器，确保下次播放时重新创建
            self?.audioPlayer = nil
        }
    }
}

// 用于将十六进制字符串转换为Data的扩展 -
extension Data {
    init?(hexString: String) {
        // 确保字符串长度是偶数
        guard hexString.count % 2 == 0 else { return nil }
        
        // 预分配内存空间
        let byteCount = hexString.count / 2
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        // 使用Scanner快速解析十六进制字符串
        var hexStringBytes = [UInt8](hexString.utf8)
        
        // 批量处理，避免字符串索引操作
        for i in 0..<byteCount {
            let index = i * 2
            
            // 获取两个字符并转换为十六进制值
            let firstChar = hexStringBytes[index]
            let secondChar = hexStringBytes[index + 1]
            
            // 转换第一个字符
            let firstValue: UInt8
            if firstChar >= 48 && firstChar <= 57 { // 0-9
                firstValue = firstChar - 48
            } else if firstChar >= 65 && firstChar <= 70 { // A-F
                firstValue = firstChar - 55
            } else if firstChar >= 97 && firstChar <= 102 { // a-f
                firstValue = firstChar - 87
            } else {
                return nil
            }
            
            // 转换第二个字符
            let secondValue: UInt8
            if secondChar >= 48 && secondChar <= 57 { // 0-9
                secondValue = secondChar - 48
            } else if secondChar >= 65 && secondChar <= 70 { // A-F
                secondValue = secondChar - 55
            } else if secondChar >= 97 && secondChar <= 102 { // a-f
                secondValue = secondChar - 87
            } else {
                return nil
            }
            
            // 组合两个字符的值
            bytes[i] = firstValue * 16 + secondValue
        }
        
        // 一次性创建Data对象
        self = Data(bytes)
    }
}
