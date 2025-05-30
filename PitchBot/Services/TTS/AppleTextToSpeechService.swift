//
//  AppleTextToSpeechService.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import Foundation
import AVFoundation

class AppleTextToSpeechService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    @Published var isMuted: Bool = false
    
    public var text = ""

    override init() {
        super.init()
        setupAudioSession()

        // 从UesrDefaults中获取静音状态
        isMuted = UserDefaults.standard.bool(forKey:"isMuted")
        
        // 添加停止语音播放的通知监听
        NotificationCenter.default.addObserver(forName: .stopSpeech, object: nil, queue: .main) { [weak self] _ in
            self?.stop()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
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
        
        // 确保音频会话处于活跃状态
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("无法激活音频会话: \(error.localizedDescription)")
            return false
        }
        
        // 停止当前正在播放的语音
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: text)
        
        // 尝试获取更高质量的声音
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
            print("使用语音: \(voice.name), 质量: \(voice.quality.rawValue)")
        } else {
            print("无法获取en-US语音")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 设置代理以跟踪语音状态
        synthesizer.delegate = self
        
        // 开始播放
        isSpeaking = true
        self.text = text
        print("开始播放语音: \(text)")
        synthesizer.speak(utterance)
        return true
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            print("停止语音播放")
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    func toggleMute() -> Bool {
        isMuted.toggle()
        
        // 如果切换到静音状态，停止当前播放
        if isMuted && synthesizer.isSpeaking {
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
            print("TextToSpeechService 已释放，音频会话已停用")
        } catch {
            print("无法停用音频会话: \(error.localizedDescription)")
        }
    }
}

extension AppleTextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("语音合成已开始: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("语音合成已完成: \(utterance.speechString)")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("语音合成已取消: \(utterance.speechString)")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("语音合成已暂停: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("语音合成已继续: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 这个方法在每个单词或短语被朗读前调用
        let text = utterance.speechString
        let index = characterRange.location
        if index % 10 == 0 { // 只打印部分日志，避免日志过多
            print("正在朗读位置: \(index)/\(text.count)")
        }
    }
}
