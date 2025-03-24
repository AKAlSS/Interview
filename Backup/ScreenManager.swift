import SwiftUI
import Cocoa

class ScreenManager: ObservableObject {
    private var assistantWindow: NSWindow?
    private var assistantWindowController: NSWindowController?
    private var originalMainWindowFrame: NSRect?
    
    func setupSplitMode() {
        guard let mainScreen = NSScreen.main else { return }
        let screenFrame = mainScreen.visibleFrame
        
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
        
        // Position main window
        if let mainWindow = NSApplication.shared.mainWindow {
            // Save original frame for restoration later
            originalMainWindowFrame = mainWindow.frame
            
            // Resize and position main window
            mainWindow.setFrame(mainFrame, display: true, animate: true)
        }
        
        // Create assistant window if it doesn't exist
        if assistantWindow == nil {
            createAssistantWindow(frame: assistantFrame)
        } else {
            assistantWindow?.setFrame(assistantFrame, display: true, animate: true)
            assistantWindow?.orderFront(nil)
        }
    }
    
    func exitSplitMode() {
        // Restore main window to original size
        if let mainWindow = NSApplication.shared.mainWindow, 
           let originalFrame = originalMainWindowFrame {
            mainWindow.setFrame(originalFrame, display: true, animate: true)
        }
        
        // Hide assistant window
        assistantWindow?.orderOut(nil)
    }
    
    private func createAssistantWindow(frame: NSRect) {
        // Create a new window for the assistant view
        assistantWindow = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        assistantWindow?.title = "Interview Assistant"
        assistantWindow?.isReleasedWhenClosed = false
        
        // Create the assistant view
        let viewModel = InterviewAssistantViewModel.shared // Access shared instance
        let assistantView = AssistantView(viewModel: viewModel)
        
        // Set the content view
        assistantWindow?.contentView = NSHostingView(rootView: assistantView)
        
        // Configure window behavior
        assistantWindow?.level = .floating // Stay on top
        assistantWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Show the window
        assistantWindow?.orderFront(nil)
    }
} 