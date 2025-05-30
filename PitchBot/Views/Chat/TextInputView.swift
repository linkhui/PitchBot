//
//  ChatView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/29.
//
import SwiftUI
import Foundation

struct TextInputView: View {
    @Binding var inputText: String
    @FocusState private var focusField: Bool  
    let isFocused: Bool  
    var onSendMessage: () -> Void
    var onVoiceButtonTap: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            InputTextField(
                text: $inputText,
                focusField: $focusField,
                onSendMessage: onSendMessage
            )
            
            VoiceButton(onTap: onVoiceButtonTap)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .onChange(of: isFocused) { newValue in
            focusField = newValue  
        }
    }
}

private struct InputTextField: View {
    @Binding var text: String
    @FocusState.Binding var focusField: Bool
    var onSendMessage: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField("Type your message here...", text: $text, axis: .vertical)
                .padding(8)
                .background(Color(.systemGray6).opacity(0.6))
                .cornerRadius(25)
                .focused($focusField)  
                .submitLabel(.send)
                .onChange(of: text) { newValue in
                    if newValue.last == "\n" {
                        text.removeLast()
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSendMessage()
                        }
                    }
                }
        }
        .background(Color(.systemGray6).opacity(0.6))
        .cornerRadius(25)
        .onTapGesture {
            focusField = true
        }
    }
}

private struct VoiceButton: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
    }
}