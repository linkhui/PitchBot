//
//  AudioRecorder.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    // 发布录音状态变化
    @Published var isRecording = false
    @Published var audioURL: URL?
    
    // 录音会话和录音器
    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    
    // 音频设置
    private let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000.0,           // 16kHz采样率
        AVNumberOfChannelsKey: 1,           // 单声道
        AVLinearPCMBitDepthKey: 16,         // 16位深度
        AVLinearPCMIsFloatKey: false,       // 整数而非浮点
        AVLinearPCMIsBigEndianKey: false,   // 小端序
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("无法设置音频会话: \(error.localizedDescription)")
        }
    }
    
    // 开始录音
    func startRecording() {
        // 确保之前的录音已停止
        if isRecording {
            stopRecording()
        }
        
        // before start recording, reset the audio session, becuase player and recorder will conflict
        setupAudioSession()
        
        // 创建临时文件URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            audioURL = audioFilename
            isRecording = true
        } catch {
            print("录音失败: \(error.localizedDescription)")
        }
    }
    
    // 停止录音
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    // 取消录音
    func cancelRecording() {
        stopRecording()
        
        // 删除录音文件
        if let url = audioURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                audioURL = nil
            } catch {
                print("无法删除录音文件: \(error.localizedDescription)")
            }
        }
    }
    
    // 获取录音文件URL
    func getRecordingURL() -> URL? {
        return audioURL
    }
    
    // 检查麦克风权限
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("录音未成功完成")
            audioURL = nil
        }
        isRecording = false
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("录音编码错误: \(error.localizedDescription)")
        }
        isRecording = false
        audioURL = nil
    }
}
