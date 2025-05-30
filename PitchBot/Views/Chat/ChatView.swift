//
//  ChatView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI
import Foundation
import AVFoundation

struct ChatView: View {
    @EnvironmentObject private var llmServiceManager: LLMServiceManager
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var speechService = MinimaxTTSService()
    @FocusState private var isInputFocused: Bool
    @State private var isVoiceInputActive: Bool = false
    @State private var isRecording: Bool = false
    @State private var voiceInputText: String = ""
    @State private var dragOffset: CGSize = .zero
    @State private var showTextInput: Bool = true
    @State private var showLLMSettings: Bool = false
    @State private var showTaskInfoAlert: Bool = false
    
    init() {
        // for @StateObject initializer
        _viewModel = StateObject(wrappedValue: ChatViewModel())
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // navigation bar
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea(edges: .top)
                    
                    // middle title
                    Text("PitchBot")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    
                    // left button
                    HStack {
                        // settings button
                        Button(action: {
                            showLLMSettings = true
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // right button
                    HStack {
                        Spacer()
                        
                        // Mute/Unmute按钮
                        Button(action: {
                            let isMuted = speechService.toggleMute()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            Image(systemName: speechService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(8)
                        }
                        
                        // New Chat button
                        Button(action: {
                            isVoiceInputActive = false
                            showTextInput = true
                            viewModel.restartConversation()

                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .frame(height: 44)
                
                // Chat Messages List
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            // Chat Messages Data
                            ForEach(viewModel.messages) { message in
                                MessageRow(message: message, speechService: speechService)
                            }
                            
                            // System Messages Data
                            ForEach(viewModel.systemMessages) { systemMessage in
                                SystemMessageRow(message: systemMessage)
                                    .environmentObject(viewModel)
                            }
                            
                            // Input indicator
                            if viewModel.isTyping {
                                HStack {
                                    AvatarView(isUser: false)
                                    TypingIndicator()
                                        .padding(.leading, 8)
                                    Spacer()
                                }
                                .id("typingIndicator")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        // add view for bottom anchor
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(width: 0, height: 0)
                                .id("bottomAnchor")
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // hide keyboard when dragging
                                UIApplication.shared.endEditing()
                            }
                    )
                    .onChange(of: viewModel.messages) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.systemMessages) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
                
                // Input View
                if viewModel.isConversationEnded {
                    // Conversation Ended Indicator
                    HStack {
                        Spacer()
                        Text("Conversation ended. Tap + in top-right for a new chat")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.vertical, 16)
                        Spacer()
                    }
                    .background(Color(.systemBackground))
                } else if showTextInput {
                    TextInputView(
                        inputText: $viewModel.inputText,
                        isFocused: isInputFocused,
                        onSendMessage: viewModel.sendMessage,
                        onVoiceButtonTap: {
                            UIApplication.shared.endEditing()

                            isVoiceInputActive = true
                            showTextInput = false
                        }
                    )
                }
                
                // voice input view
                if isVoiceInputActive && !viewModel.isConversationEnded {
                    VoiceInputView(
                        isVoiceInputActive: $isVoiceInputActive,
                        isRecording: $isRecording,
                        voiceInputText: $voiceInputText,
                        dragOffset: $dragOffset,
                        onSendVoiceMessage: { text in
                            viewModel.inputText = text
                            viewModel.sendMessage()
                        }
                    )
                    .frame(height: 300) // 限制整体高度
                    .zIndex(2)
                    .onDisappear() {
                        showTextInput = true
                    }
                }
            }
            .background(Color(.systemGray6))
            
            // evaluation view
            if viewModel.showEvaluation {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                    }
                
                EvaluationView(
                    conversation: viewModel.chatMessages,
                    onRestart: {
                        viewModel.restartConversation()
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
                .onAppear() {
                    UIApplication.shared.endEditing()

                }
            }
            
            // Task Info Alert View
            if showTaskInfoAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                    }
                
                TaskInfoAlertView(onDismiss: {
                    showTaskInfoAlert = false
                })
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            
            showTaskInfoAlert = true
            
            viewModel.updateLLMService(llmServiceManager.currentService)
        }
        .onChange(of: llmServiceManager.currentServiceType) { _ in
            // change llm service when switching
            viewModel.updateLLMService(llmServiceManager.currentService)
        }
        .sheet(isPresented: $showLLMSettings) {
            LLMServiceSettingsView(serviceManager: llmServiceManager)
        }
    }
}




extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



#Preview {
    ChatView()
}
