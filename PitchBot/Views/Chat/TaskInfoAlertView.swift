//
//  TaskInfoAlertView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI

struct TaskInfoAlertView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // title
            Text("Sales Conversation Challenge")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Content
            VStack(alignment: .leading, spacing: 15) {
                infoSection(title: "Scenario", content: "You're offering marketing services to a potential client named Taylor.")
                
                infoSection(title: "Rules", content: "You have up to 5 messages to respond, ask good questions, and engage with Taylor.")
                
                infoSection(title: "Goal", content: "Try to move Taylor toward a next step — like agreeing to a follow-up call.")
                
                infoSection(title: "Evaluation", content: "At the end of the chat, you will get a score and feedback on your performance.")
            }
            .padding(.horizontal, 32)
            
            Button(action: onDismiss) {
                Text("Got it!")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 25)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 32)
    }
    
    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
    }
}

struct TaskInfoAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            TaskInfoAlertView(onDismiss: {})
        }
    }
}
