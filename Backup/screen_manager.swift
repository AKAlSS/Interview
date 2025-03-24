import SwiftUI
import Cocoa

class ScreenManager: ObservableObject {
    @Published var isInSplitMode: Bool = false
    private var originalWindowFrame: NSRect?
    private var assistantWindowController: NSWindowController?
    
    // Set up 2/3 + 1/3 split screen mode
    func setupSplitMode() {
        guard let mainScreen = NSScreen.main else { return }
        let screenFrame = mainScreen.visibleFrame
        
        // Save current window state if not already in split mode
        if !isInSplitMode, let window = NSApplication.shared.mainWindow {
            originalWindowFrame = window.frame
        }
        
        // Calculate frames for main app (left 2/3) and assistant (right 1/3)
        let mainFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: screenFrame.width * (2/3),
            height: screenFrame.height
        )
        
        let assistantFrame = NSRect(
            x: screenFrame.origin.x + screenFrame.width * (2/3),
            y: screenFrame.origin.y,
            width: screenFrame.width * (1/3),
            height: screenFrame.height
        )
        
        // Position main app window
        if let window = NSApplication.shared.mainWindow {
            window.setFrame(mainFrame, display: true, animate: true)
        }
        
        // Create or update assistant window
        if assistantWindowController == nil {
            createAssistantWindow(frame: assistantFrame)
        } else {
            assistantWindowController?.window?.setFrame(assistantFrame, display: true, animate: true)
        }
        
        isInSplitMode = true
    }
    
    // Restore to normal screen mode
    func exitSplitMode() {
        if let window = NSApplication.shared.mainWindow, let originalFrame = originalWindowFrame {
            window.setFrame(originalFrame, display: true, animate: true)
        }
        
        assistantWindowController?.window?.close()
        isInSplitMode = false
    }
    
    private func createAssistantWindow(frame: NSRect) {
        // Create a window for the assistant view
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Interview Assistant"
        window.isReleasedWhenClosed = false
        
        // Create the assistant view
        let assistantView = AssistantView()
        window.contentView = NSHostingView(rootView: assistantView)
        
        assistantWindowController = NSWindowController(window: window)
        assistantWindowController?.showWindow(nil)
        
        // Ensure assistant window stays on top but doesn't activate
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    // Setup for screen sharing - ensures only the main window area is shared
    func prepareForScreenSharing() {
        // This would integrate with macOS screen sharing APIs
        // For now, we ensure the windows are correctly positioned
        if !isInSplitMode {
            setupSplitMode()
        }
        
        // TODO: Implement more advanced screen sharing limitation
        // This would typically involve creating a virtual display or
        // using macOS screen sharing APIs to limit shared content
    }
}

// The assistant view that appears in the right 1/3 of the screen
struct AssistantView: View {
    @EnvironmentObject var viewModel: InterviewAssistantViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Interview Assistant")
                .font(.headline)
                .padding(.bottom, 8)
            
            if !viewModel.answer.isEmpty {
                VStack(alignment: .leading) {
                    Text("Answer:")
                        .font(.subheadline)
                        .bold()
                    
                    ScrollView {
                        Text(viewModel.answer)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            if !viewModel.code.isEmpty {
                VStack(alignment: .leading) {
                    Text("Code Solution:")
                        .font(.subheadline)
                        .bold()
                    
                    ScrollView {
                        Text(viewModel.code)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    if !viewModel.explanation.isEmpty {
                        Text("Explanation:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 8)
                        
                        Text(viewModel.explanation)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Quick-hide button
            Button("Hide Assistant (⌘H)") {
                // This will be handled through keyboard shortcuts
            }
            .keyboardShortcut("h", modifiers: .command)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 