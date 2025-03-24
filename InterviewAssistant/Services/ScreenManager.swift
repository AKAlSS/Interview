import SwiftUI
import AppKit
import Combine

class ScreenManager: ObservableObject {
    private var assistantWindow: NSWindow?
    private var originalMainWindowFrame: NSRect?
    private var screenSharingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isScreenSharingActive: Bool = false
    
    // Singleton for shared access
    static let shared = ScreenManager()
    
    private init() {
        // Start monitoring for screen sharing
        startMonitoringScreenSharing()
    }
    
    // MARK: - Screen Sharing Detection
    
    func startMonitoringScreenSharing() {
        // Check initially
        checkForScreenSharing()
        
        // Set up a timer to check periodically
        screenSharingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForScreenSharing()
        }
        
        // Also monitor for specific screen capture notifications
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.checkForScreenSharing()
            }
            .store(in: &cancellables)
    }
    
    func stopMonitoringScreenSharing() {
        screenSharingTimer?.invalidate()
        screenSharingTimer = nil
        cancellables.removeAll()
    }
    
    private func checkForScreenSharing() {
        // Method 1: Check for screen recording status
        let screenSharingService = CGSServiceForDisplayNumber(CGMainDisplayID()).takeRetainedValue()
        let screenIsSharing = screenSharingService != 0
        
        // Method 2: Check for specific window types that might indicate screen sharing
        var sharingWindowFound = false
        NSApplication.shared.windows.forEach { window in
            // Check window title or properties that might indicate it's a screen sharing app
            let title = window.title.lowercased()
            if title.contains("screen sharing") || 
               title.contains("zoom") || 
               title.contains("teams") || 
               title.contains("webex") ||
               title.contains("meet") {
                sharingWindowFound = true
            }
        }
        
        // Method 3: Look for screen recording processes
        let sharingProcesses = ["screencapture", "ScreensharingD", "Zoom", "Microsoft Teams", "Webex", "Google Meet"]
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/bin/ps"
        task.arguments = ["-ax"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for process in sharingProcesses {
                    if output.contains(process) {
                        sharingWindowFound = true
                        break
                    }
                }
            }
        } catch {
            print("Error checking for screen sharing processes: \(error)")
        }
        
        // Update state if changed
        let isSharing = screenIsSharing || sharingWindowFound
        if isSharing != isScreenSharingActive {
            DispatchQueue.main.async {
                self.isScreenSharingActive = isSharing
                
                // Post notification for other components to react
                NotificationCenter.default.post(
                    name: isSharing ? NSNotification.Name("ScreenSharingStarted") : NSNotification.Name("ScreenSharingEnded"),
                    object: nil
                )
                
                // Take appropriate action
                if isSharing {
                    self.handleScreenSharingStarted()
                } else {
                    self.handleScreenSharingEnded()
                }
            }
        }
    }
    
    private func handleScreenSharingStarted() {
        // Hide or minimize assistant window
        self.assistantWindow?.miniaturize(nil)
        
        // Make main app look more professional/innocent
        if let mainWindow = NSApplication.shared.mainWindow {
            mainWindow.title = "Code Editor"
        }
    }
    
    private func handleScreenSharingEnded() {
        // Restore assistant window if it was hidden
        if let assistantWindow = self.assistantWindow, assistantWindow.isMiniaturized {
            assistantWindow.deminiaturize(nil)
        }
        
        // Restore main app title
        if let mainWindow = NSApplication.shared.mainWindow {
            mainWindow.title = "Interview Assistant"
        }
    }
    
    // MARK: - Window Management
    
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
        
        // Host the SwiftUI AssistantView
        let viewModel = MainViewModel()
        let assistantView = AssistantView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: assistantView)
        
        assistantWindow?.contentView = hostingController.view
        
        // Configure window behavior
        assistantWindow?.level = .floating // Stay on top
        assistantWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Add global hotkey to hide/show the window
        setupGlobalHotkeys()
        
        // Show the window
        assistantWindow?.orderFront(nil)
    }
    
    private func setupGlobalHotkeys() {
        // In a real implementation, this would register system-wide hotkeys
        // For macOS, this typically requires special permissions or using a library
        // like HotKey (https://github.com/soffes/HotKey)
        
        // For this implementation, we'll rely on the app-level keyboard shortcuts
        // defined in InterviewAssistantApp.swift
    }
    
    // Method to register the assistant window from the main app
    func registerAssistantWindow(_ window: NSWindow) {
        self.assistantWindow = window
    }
    
    // Method to update assistant window content with answer/code information
    func updateAssistantContent(answer: String? = nil, code: String? = nil, explanation: String? = nil) {
        guard let assistantWindow = self.assistantWindow else { return }
        
        // Since we're now using a proper SwiftUI view, we need to update the view model instead
        if let hostingView = assistantWindow.contentView,
           let hostingController = hostingView.nextResponder as? NSHostingController<AssistantView>,
           let assistantView = hostingController.rootView as? AssistantView {
            
            // Update the view model that's bound to the view
            DispatchQueue.main.async {
                if let answer = answer {
                    assistantView.viewModel.currentAnswer = answer
                }
                
                // In a full implementation, we'd also update code and explanation
                // through dedicated properties in the view model
            }
        }
    }
}

// Extension to support screen sharing detection
extension ScreenManager {
    private func CGSServiceForDisplayNumber(_ displayNumber: CGDirectDisplayID) -> CFTypeRef {
        let CGSDefaultConnection: () -> Void = unsafeBitCast(
            dlsym(dlopen(nil, RTLD_GLOBAL), "CGSDefaultConnection"),
            to: (() -> Void).self
        )
        
        typealias CGSServiceForDisplayNumberFunction = @convention(c) (Void, CGDirectDisplayID) -> CFTypeRef
        let CGSServiceForDisplayNumberSymbol = dlsym(dlopen(nil, RTLD_GLOBAL), "CGSServiceForDisplayNumber")
        let CGSServiceForDisplayNumber = unsafeBitCast(
            CGSServiceForDisplayNumberSymbol,
            to: CGSServiceForDisplayNumberFunction.self
        )
        
        return CGSServiceForDisplayNumber(CGSDefaultConnection(), displayNumber)
    }
} 