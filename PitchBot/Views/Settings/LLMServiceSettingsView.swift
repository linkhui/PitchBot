//
//  LLMServiceSettingsView.swift
//  PitchBot
//
//  Created by Li Hui on 2025/5/28.
//

import SwiftUI

/// LLM Service Settings View
struct LLMServiceSettingsView: View {
    @ObservedObject var serviceManager: LLMServiceManager

    // minimax configuration
    // api key for MiniMax chat and TTS
    @State private var minimaxAPIKey: String = ""
    // group id used for MiniMax TTS
    @State private var minimaxGroupID: String = ""

    // openai configuration
    @State private var openaiAPIKey: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LLM Service")) {
                    Picker("Select service", selection: $serviceManager.currentServiceType) {
                        ForEach(LLMServiceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: serviceManager.currentServiceType) { newValue in
                        serviceManager.switchService(to: newValue)
                    }
                }
                
                Section(header: Text("MiniMax Settings")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("MiniMax API Key", text: $minimaxAPIKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: minimaxAPIKey) { newValue in
                                serviceManager.updateAPIKey(for: .minimax, apiKey: newValue)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Group ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("MiniMax Group ID", text: $minimaxGroupID)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: minimaxGroupID) { newValue in
                                serviceManager.updateGroupID(for: .minimax, groupID: newValue)
                            }
                    }
                }
                
                Section(header: Text("OpenAI Compatible Settings")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("OpenAI Compatible API Key", text: $openaiAPIKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: openaiAPIKey) { newValue in
                                serviceManager.updateAPIKey(for: .openai, apiKey: newValue)
                            }
                    }
                }
                
                Section {
                    Button("Save") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // load initial values
                minimaxAPIKey = serviceManager.getAPIKey(for: .minimax)
                minimaxGroupID = serviceManager.getGroupID(for: .minimax)
                openaiAPIKey = serviceManager.getAPIKey(for: .openai)
            }
        }
    }
}

#Preview {
    LLMServiceSettingsView(serviceManager: LLMServiceManager())
}
