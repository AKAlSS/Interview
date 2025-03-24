import AppKit
import Foundation

class WindowManagementService {
    // Singleton instance
    static let shared = WindowManagementService()
    
    // References to managed windows
    private weak var mainWindow: NSWindow?
    private weak var assistantWindow: NSWindow?
    
    // Screen sharing detection
    private var isScreenSharingActive = false
    private var screenSharingCheckTimer: Timer?
    
    // Hotkey metadata
    private var hotkeyMonitor: Any?
    
    private init() {
        // Set up timer to check for screen sharing
        startScreenSharingDetection()
        
        // Set up global hotkey monitoring
        setupGlobalHotkeys()
    }
    
    deinit {
        stopScreenSharingDetection()
        removeGlobalHotkeys()
    }
    
    // MARK: - Window Registration
    
    func registerMainWindow(_ window: NSWindow) {
        mainWindow = window
    }
    
    func registerAssistantWindow(_ window: NSWindow) {
        assistantWindow = window
    }
    
    // MARK: - Window Visibility Management
    
    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        mainWindow?.orderFrontRegardless()
    }
    
    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }
    
    func showAssistantWindow() {
        guard !isScreenSharingActive else {
            print("Screen sharing is active - not showing assistant window")
            return
        }
        
        assistantWindow?.makeKeyAndOrderFront(nil)
        assistantWindow?.orderFrontRegardless()
    }
    
    func hideAssistantWindow() {
        assistantWindow?.orderOut(nil)
    }
    
    func toggleAssistantVisibility() {
        if assistantWindow?.isVisible == true {
            hideAssistantWindow()
        } else {
            showAssistantWindow()
        }
    }
    
    // MARK: - Screen Sharing Detection
    
    private func startScreenSharingDetection() {
        // Check initially
        checkForActiveScreenSharing()
        
        // Set up periodic checking
        screenSharingCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForActiveScreenSharing()
        }
    }
    
    private func stopScreenSharingDetection() {
        screenSharingCheckTimer?.invalidate()
        screenSharingCheckTimer = nil
    }
    
    private func checkForActiveScreenSharing() {
        // Using CGWindowListCopyWindowInfo to detect screen sharing apps
        let kCGWindowListOptionAll = CGWindowListOption(rawValue: 0)
        let windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID) as? [[String: Any]] ?? []
        
        let screenSharingAppNames = [
            "zoom.us",
            "Zoom",
            "Microsoft Teams",
            "Google Meet",
            "Skype",
            "Screen Sharing",
            "Slack",
            "Discord",
            "WebexMeetings",
            "WebEx"
        ]
        
        let wasScreenSharingActive = isScreenSharingActive
        
        // Check if any screen sharing app is in the window list
        isScreenSharingActive = windowList.contains { windowInfo in
            if let ownerName = windowInfo["kCGWindowOwnerName"] as? String {
                return screenSharingAppNames.contains { ownerName.contains($0) }
            }
            return false
        }
        
        // If screen sharing state changed
        if wasScreenSharingActive != isScreenSharingActive {
            if isScreenSharingActive {
                // Screen sharing just started
                hideAssistantWindow()
                
                // Notify the app that screen sharing started
                NotificationCenter.default.post(name: NSNotification.Name("ScreenSharingStarted"), object: nil)
            } else {
                // Screen sharing just ended
                NotificationCenter.default.post(name: NSNotification.Name("ScreenSharingEnded"), object: nil)
            }
        }
    }
    
    // MARK: - Global Hotkeys
    
    private func setupGlobalHotkeys() {
        // Monitor for ⌘⌥A to toggle assistant visibility
        let flags: NSEvent.ModifierFlags = [.command, .option]
        let keyCode: UInt16 = 0  // 'A' key
        
        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            if event.modifierFlags.contains(flags) && event.keyCode == keyCode {
                DispatchQueue.main.async {
                    self.toggleAssistantVisibility()
                }
            }
        }
    }
    
    private func removeGlobalHotkeys() {
        if let monitor = hotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyMonitor = nil
        }
    }
} 