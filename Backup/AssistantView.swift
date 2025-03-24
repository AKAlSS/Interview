import SwiftUI

struct AssistantView: View {
    @ObservedObject var viewModel: InterviewAssistantViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Interview Assistant")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Content
            if !viewModel.answer.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Answer:")
                            .font(.subheadline)
                            .bold()
                        
                        Text(viewModel.answer)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }
            }
            
            if !viewModel.code.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Code Solution:")
                            .font(.subheadline)
                            .bold()
                        
                        Text(viewModel.code)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                        
                        if !viewModel.explanation.isEmpty {
                            Text("Explanation:")
                                .font(.subheadline)
                                .bold()
                                .padding(.top, 8)
                            
                            Text(viewModel.explanation)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Quick copy buttons
            if !viewModel.code.isEmpty {
                Button("Copy Code to Cursor") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.code, forType: .string)
                }
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Hide button
            Button("Hide Assistant (⌘⌥H)") {
                // Will be handled by global shortcut
            }
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 