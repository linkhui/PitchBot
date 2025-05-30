//
//  CharacterProfileView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/27.
//

import SwiftUI

struct CharacterProfileView: View {
    let profile: CharacterProfile
    var onDismiss: () -> Void
    
    var body: some View {

        VStack(alignment: .leading, spacing: 20) {
            // avatar
            HStack {
                
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 80, height: 80)
                    
                    Text("T")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
            }
            .padding(.vertical, 10)
            
            // description
            VStack(alignment: .leading, spacing: 15) {
                Text("Description")
                    .font(.headline)
                
                Text(profile.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Greeting")
                    .font(.headline)
                    .padding(.top, 5)
                
                Text(profile.greeting)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        
        CharacterProfileView(
            profile: CharacterProfile.pitchBot,
            onDismiss: {}
        )
    }
}
