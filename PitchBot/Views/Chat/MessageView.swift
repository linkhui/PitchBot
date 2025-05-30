//
//  ChatView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/29.
//
import SwiftUI
import Foundation

struct MessageRow: View {
    let message: Message
    @ObservedObject var speechService: MinimaxTTSService
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
                MessageBubble(text: message.text, isUser: true, speechService: speechService)
                    .padding(.leading, 60)
                AvatarView(isUser: true)
            } else {
                AvatarView(isUser: false)
                MessageBubble(text: message.text, isUser: false, speechService: speechService)
                    .padding(.trailing, 60)
                Spacer()
            }
        }
    }
}

struct SystemMessageRow: View {
    let message: SystemMessage
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        SystemMessageBubble(message: message)
            .onTapGesture {
                viewModel.showEvaluationForSystemMessage(message)
            }
    }
}

struct AvatarView: View {
    let isUser: Bool
    @State private var showProfile: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isUser ? Color.green : Color.purple)
                .frame(width: 36, height: 36)
            
            Text(isUser ? "U" : "T")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .onTapGesture {
            if !isUser {
                showProfile = true
            }
        }
        .sheet(isPresented: $showProfile) {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                    }
                
                CharacterProfileView(
                    profile: CharacterProfile.pitchBot,
                    onDismiss: { showProfile = false }
                )
            }
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }
}

struct MessageBubble: View {
    let text: String
    let isUser: Bool
    @ObservedObject var speechService: MinimaxTTSService
    
    init(text: String, isUser: Bool, speechService: MinimaxTTSService) {
        self.text = text
        self.isUser = isUser
        self.speechService = speechService
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isUser ? .white : .black)
                .cornerRadius(18)
                .overlay(
                    isUser ?
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.blue, lineWidth: 1) :
                        RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            
            // Play/Pause Button for AI messages
            if !isUser {
                Button(action: {
                    if speechService.isMuted {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                    } else {
                        if speechService.isSpeaking {
                            speechService.stop()
                        } else {
                            _ = speechService.speak(text: text)
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: speechService.isSpeaking && speechService.text == text ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                        Text(speechService.isSpeaking && speechService.text == text ? "Stop" : "Play")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .foregroundColor(speechService.isMuted ? .gray : .primary)
                    .cornerRadius(12)
                }
                .padding(.leading, 16)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playLatestAIMessage)) { notification in
            if !isUser, let messageText = notification.object as? String, messageText == text, !speechService.isMuted {
                _ = speechService.speak(text: text)
            }
        }
    }
}

struct SystemMessageBubble: View {
    let message: SystemMessage
    
    var body: some View {
        HStack {
            Spacer()
            Text(message.text)
                .font(.system(size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange, lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .offset(x: 8, y: -8)
                }
            Spacer()
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 7, height: 7)
                    .offset(y: animationOffset - (CGFloat(index) * 1.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = 5
            }
        }
    }
}