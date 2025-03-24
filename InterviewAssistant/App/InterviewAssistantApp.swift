import SwiftUI

@main
struct InterviewAssistantApp: App {
    @StateObject private var viewModel = MainViewModel()
    
    // Keep track of the assistant window
    @State private var assistantWindow: NSWindow?
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .onAppear {
                    setupAssistantWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                // No new item command
            }
            
            CommandMenu("Assistant") {
                Button("Show Assistant") {
                    showAssistantWindow()
                }
                .keyboardShortcut("a", modifiers: [.command, .option])
                
                Button("Hide Assistant") {
                    hideAssistantWindow()
                }
                .keyboardShortcut("h", modifiers: [.command, .option])
            }
        }
    }
    
    private func setupAssistantWindow() {
        // Create the assistant window
        let assistantView = AssistantView(viewModel: viewModel)
        
        let hostingController = NSHostingController(rootView: assistantView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.title = "Assistant"
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("AssistantWindow")
        window.level = .floating // Keep it above other windows
        
        // Position in the upper right corner of the screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = window.frame.size
            
            let x = screenRect.maxX - windowSize.width - 20
            let y = screenRect.maxY - windowSize.height - 20
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Store a reference to the window
        self.assistantWindow = window
        
        // Register with the window management service
        WindowManagementService.shared.registerAssistantWindow(window)
        
        // Hide it initially
        window.orderOut(nil)
    }
    
    private func showAssistantWindow() {
        WindowManagementService.shared.showAssistantWindow()
    }
    
    private func hideAssistantWindow() {
        WindowManagementService.shared.hideAssistantWindow()
    }
} 