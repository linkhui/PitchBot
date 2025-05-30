//
//  VoiceInputView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI
import AVFoundation
import Speech

struct VoiceInputView: View {
    @Binding var isVoiceInputActive: Bool
    @Binding var isRecording: Bool
    @Binding var voiceInputText: String
    @Binding var dragOffset: CGSize
    var onSendVoiceMessage: (String) -> Void
    
    // Audio Recorder and Speech Recognition
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @State private var showMicPermissionAlert = false
    @State private var showSpeechPermissionAlert = false
    @State private var isProcessingSpeech = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Waveform View
            VStack(spacing: 15) {
                if !voiceInputText.isEmpty {
                    // text
                    Text(voiceInputText)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                } else if isProcessingSpeech {
                    // processing audio to text
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text("Audio to text...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    // waveform
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    // hint
                    Text(isRecording ? "Recording in progress..." : "Release to finish recording, swipe up to cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, -30) // 添加负的顶部内边距，减少顶部空白
            
            // Spacer()
            
            // bottom buttons
            HStack(spacing: 50) {
                if !voiceInputText.isEmpty || isProcessingSpeech {
                    // cancel button
                    VStack(spacing: 5) {
                        Text("Cancel")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 20)
                        
                        Button(action: {
                            resetState()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                // record/send button
                ZStack {
                    if !voiceInputText.isEmpty {
                        // convert to text and send button
                        VStack(spacing: 5) {
                            Text("Convert to text\nSend")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(height: 20)
                            
                            Button(action: {
                                // send voice message
                                onSendVoiceMessage(voiceInputText)
                                
                                // reset state
                                resetState()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    } else if isProcessingSpeech {
                        // processing audio to text
                        ZStack {
                            Capsule()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 180, height: 60)
                            
                            Text("Processing...")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    } else {
                        // record
                        VStack(spacing: 5) {
                            Text("")
                                .font(.caption)
                                .frame(height: 20)
                                
                            ZStack {
                                Capsule()
                                    .fill(Color.black)
                                    .frame(height: 60)
                                    .padding(.horizontal, 10)
                                
                                Text("Press and hold to speak")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isRecording {                                    
                                        startRecording()
                                    }
                                    // save drag offset to determine swipe cancellation
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    stopRecording()
                                    
                                    // if drag offset is greater than 50, cancel recording
                                    if dragOffset.height < -50 {
                                        cancelRecording()
                                    } else {
                                        // audio to text
                                        processRecording()
                                    }
                                    dragOffset = .zero
                                }
                        )
                    }
                }
                
                // Keyboard button
                VStack(spacing: 5) {
                    Text("")
                        .font(.caption)
                        .frame(height: 20)
                    
                    Button(action: {
                        // change to keyboard input
                        resetState()
                        closeVoiceInput()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "keyboard")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if isRecording {
                        dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    if dragOffset.height < -50 && isRecording {
                        // swipe to cancel
                        cancelRecording()
                    }
                    dragOffset = .zero
                }
        )
        .alert(isPresented: $showMicPermissionAlert) {
            Alert(
                title: Text("Microphone Permission"),
                message: Text("Need to grant microphone permission to use voice input."),
                primaryButton: .default(Text("OK")),
                secondaryButton: .cancel()
            )
        }
        .onChange(of: audioRecorder.isRecording) { newValue in
            isRecording = newValue
        }
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() {
        audioRecorder.checkMicrophonePermission { granted in
            if granted {
                audioRecorder.startRecording()
            } else {
                showMicPermissionAlert = true
            }
        }
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
    }
    
    private func cancelRecording() {
        audioRecorder.cancelRecording()
        isRecording = false
        voiceInputText = ""
    }
    
    private func processRecording() {
        guard let audioURL = audioRecorder.getRecordingURL() else {
            return
        }
        
        isProcessingSpeech = true
        
        // check speech recognition permission
        speechRecognizer.checkSpeechRecognitionPermission { granted in
            if granted {
                // record audio to text
                speechRecognizer.recognizeText(from: audioURL) { result in
                    DispatchQueue.main.async {
                        isProcessingSpeech = false
                        
                        switch result {
                        case .success(let text):
                            voiceInputText = text
                        case .failure(let error):
                            print("asr error: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // use simulated speech recognition
                speechRecognizer.simulateRecognition { result in
                    DispatchQueue.main.async {
                        isProcessingSpeech = false
                        if case .success(let text) = result {
                            voiceInputText = text
                        }
                    }
                }
            }
        }
    }
    
    private func closeVoiceInput() {
        isVoiceInputActive = false
    }

    private func resetState() {
        isRecording = false
        voiceInputText = ""
        dragOffset = .zero
        isProcessingSpeech = false
        audioRecorder.cancelRecording()
        speechRecognizer.cancelRecognition()
    }
}

#Preview {
    @State var isVoiceInputActive = true
    @State var isRecording = false
    @State var voiceInputText = ""
    @State var dragOffset: CGSize = .zero
    
    return VoiceInputView(
        isVoiceInputActive: $isVoiceInputActive,
        isRecording: $isRecording,
        voiceInputText: $voiceInputText,
        dragOffset: $dragOffset,
        onSendVoiceMessage: { _ in }
    )
}
