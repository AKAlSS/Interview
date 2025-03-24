import SwiftUI
import Combine

struct AssistantView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isExpanded = true
    @State private var opacity: Double = 1.0
    @State private var isCodeView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Expand or collapse the assistant panel")
                
                Text("Interview Assistant")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Screen sharing indicator
                if viewModel.isScreenSharingActive {
                    Label("Sharing", systemImage: "record.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Button(action: {
                    WindowManagementService.shared.hideAssistantWindow()
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close assistant panel")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            
            if isExpanded {
                Divider()
                
                // Question area
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Question:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !viewModel.currentTranscription.isEmpty {
                            Button(action: {
                                viewModel.processTranscription { _ in }
                            }) {
                                Label("Process", systemImage: "play.fill")
                                    .font(.caption)
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Text(viewModel.currentTranscription.isEmpty ? "No question detected" : viewModel.currentTranscription)
                        .font(.body)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                // Answer area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Response:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("View", selection: $isCodeView) {
                            Text("Text").tag(false)
                            Text("Code").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    if isCodeView {
                        // Code view with monospaced font and syntax highlighting
                        ScrollView {
                            if let codeBlock = extractCodeBlock(from: viewModel.currentAnswer) {
                                Text(codeBlock)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(6)
                            } else {
                                Text("No code found in response")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .frame(maxHeight: 250)
                    } else {
                        // Regular text view
                        ScrollView {
                            Text(viewModel.currentAnswer.isEmpty ? "No response yet" : viewModel.currentAnswer)
                                .font(.body)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .frame(maxHeight: 250)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                // Actions
                HStack {
                    Button(action: {
                        copyToClipboard(viewModel.currentAnswer)
                    }) {
                        Label("Copy All", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.currentAnswer.isEmpty)
                    
                    Spacer()
                    
                    Button(action: {
                        if let code = extractCodeBlock(from: viewModel.currentAnswer) {
                            copyToClipboard(code)
                        }
                    }) {
                        Label("Copy Code", systemImage: "curlybraces")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(extractCodeBlock(from: viewModel.currentAnswer) == nil)
                    
                    Button(action: {
                        viewModel.sendToCursor()
                    }) {
                        Label("Send to Cursor", systemImage: "arrow.right.doc.on.clipboard")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.currentAnswer.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(opacity)
        .onReceive(viewModel.$isScreenSharingActive) { isScreenSharing in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Make window more transparent during screen sharing
                opacity = isScreenSharing ? 0.7 : 1.0
            }
        }
    }
    
    // Helper function to extract code blocks from response
    private func extractCodeBlock(from text: String) -> String? {
        let codePattern = try? NSRegularExpression(pattern: "```(?:swift)?\\s*([\\s\\S]*?)```", options: [])
        
        if let matches = codePattern?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           !matches.isEmpty,
           let firstMatch = matches.first,
           firstMatch.numberOfRanges > 1,
           let range = Range(firstMatch.range(at: 1), in: text) {
            return String(text[range])
        }
        
        return nil
    }
    
    // Helper function to copy text to clipboard
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Preview
struct AssistantView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AssistantView(viewModel: MainViewModel())
                .previewDisplayName("Standard")
            
            AssistantView(viewModel: {
                let vm = MainViewModel()
                vm.currentTranscription = "How would you implement a binary search tree in Swift?"
                vm.currentAnswer = "A binary search tree (BST) is a data structure where each node has at most two children. Here's how you can implement it in Swift:\n\n```swift\nclass Node<T: Comparable> {\n    var value: T\n    var left: Node?\n    var right: Node?\n    \n    init(value: T) {\n        self.value = value\n    }\n}\n\nclass BinarySearchTree<T: Comparable> {\n    var root: Node<T>?\n    \n    func insert(_ value: T) {\n        root = insert(root, value)\n    }\n    \n    private func insert(_ node: Node<T>?, _ value: T) -> Node<T> {\n        guard let node = node else {\n            return Node(value: value)\n        }\n        \n        if value < node.value {\n            node.left = insert(node.left, value)\n        } else if value > node.value {\n            node.right = insert(node.right, value)\n        }\n        \n        return node\n    }\n}\n```"
                return vm
            }())
                .previewDisplayName("With Content")
        }
    }
} 