import SwiftUI

struct SettingsView: View {
    @Binding var apiKey: String
    @State private var tempAPIKey: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccessAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("OpenAI API Key")
                    .font(.headline)
                
                Text("Your API key is used to analyze questions and generate responses. It's stored securely on your device only.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your OpenAI API key", text: $tempAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                
                Button("Save API Key") {
                    apiKey = tempAPIKey
                    showingSuccessAlert = true
                }
                .disabled(tempAPIKey.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(.headline)
                
                Text("Technical Interview Assistant System v1.0")
                    .font(.body)
                
                Text("This application helps you answer technical questions during interviews by listening to questions, analyzing them, and generating appropriate responses.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: 400, height: 450)
        .onAppear {
            tempAPIKey = apiKey
        }
        .alert("API Key Saved", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your API key has been saved successfully.")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(apiKey: .constant(""))
    }
} 