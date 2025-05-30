//
//  EvaluationView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI

struct EvaluationView: View {
    @StateObject private var viewModel = EvaluationViewModel()
    let conversation: [ChatMessage]
    let onRestart: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if let evaluation = viewModel.evaluationResult {
                    evaluationContentView(evaluation: evaluation)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(20)
            .frame(maxWidth: 500)
            
            // close button
            Button(action: {
                // close the view
                NotificationCenter.default.post(name: .dismissEvaluation, object: nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .onAppear {
            if viewModel.llmService.hasAPIKey {
                viewModel.generateEvaluation(conversation: conversation)
            } else {
                viewModel.generateMockEvaluation()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Text("Evaluating Your Performance")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            ProgressView()
                .scaleEffect(1.5)
                .padding(30)
            
            Text("Please wait while we analyze your conversation...")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
        .padding()
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Text("Oops! Something went wrong")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding()
            
            Text("We couldn't evaluate your conversation.")
                .foregroundColor(.secondary)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if viewModel.llmService.hasAPIKey {
                    viewModel.generateEvaluation(conversation: conversation)
                } else {
                    viewModel.generateMockEvaluation()
                }
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(25)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            Button(action: onRestart) {
                Text("Start New Session")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .padding()
    }
    
    private func evaluationContentView(evaluation: EvaluationResult) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Your Performance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    ScoreCard(
                        title: "Objection Handling",
                        score: evaluation.objectionHandlingScore,
                        maxScore: 5
                    )
                    
                    ScoreCard(
                        title: "Next Steps Setup",
                        score: evaluation.nextStepScore,
                        maxScore: 5
                    )
                    
                    FeedbackCard(text: evaluation.feedback)
                    
                    SummarySection(points: evaluation.summaryPoints)
                }
                .padding()
            }
            
            Button(action: onRestart) {
                Text("Start New Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .padding(.top, 10)
        }
    }
}

struct ScoreCard: View {
    let title: String
    let score: Int
    let maxScore: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 5) {
                ForEach(1...maxScore, id: \.self) { index in
                    Image(systemName: index <= score ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 24))
                }
            }
            
            Text("\(score)/\(maxScore) Stars")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeedbackCard: View {
    let text: String
    
    var body: some View {
        Text(text)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(.blue),
                alignment: .leading
            )
    }
}

struct SummarySection: View {
    let points: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Summary")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    
                    Text(point)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    EvaluationView(
        conversation: [
            ChatMessage(role: "system", content: "System prompt"),
            ChatMessage(role: "assistant", content: "Hello"),
            ChatMessage(role: "user", content: "Hi there")
        ],
        onRestart: {}
    )
}
