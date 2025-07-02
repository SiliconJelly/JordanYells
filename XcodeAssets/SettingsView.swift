import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gemini API Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API Key")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                isKeyVisible.toggle()
                            }) {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if isKeyVisible {
                            TextField("Enter your Gemini API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Enter your Gemini API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        if !apiKey.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key is set")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Instructions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Get your API key from Google AI Studio")
                        Text("2. Enter it above to enable AI shot analysis")
                        Text("3. Your key is stored securely in Keychain")
                        Text("4. Never share your API key with others")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(apiKey.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(apiKey.isEmpty)
                }
                
                Section {
                    Button("Clear API Key") {
                        clearAPIKey()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Section(header: Text("Development")) {
                    NavigationLink("Pose Detection Test") {
                        PoseTestView()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAPIKey()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadAPIKey() {
        apiKey = APIConfig.shared.geminiAPIKey ?? ""
    }
    
    private func saveAPIKey() {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a valid API key"
            showingAlert = true
            return
        }
        
        APIConfig.shared.geminiAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        alertMessage = "API key saved successfully!"
        showingAlert = true
    }
    
    private func clearAPIKey() {
        APIConfig.shared.geminiAPIKey = nil
        apiKey = ""
        alertMessage = "API key cleared"
        showingAlert = true
    }
} 