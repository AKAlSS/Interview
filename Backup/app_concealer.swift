import Cocoa

class AppConcealer {
    private var isHidden = false
    private var eventMonitor: Any?
    
    func setupConcealment() {
        // Monitor for Cmd+Tab key presses
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Command+Tab detection
            if event.modifierFlags.contains(.command) && event.keyCode == 48 {
                self?.hideApp()
            }
            
            // Our custom shortcut to show/hide (Cmd+Option+H)
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 4 {
                self?.toggleVisibility()
            }
        }
        
        // Also monitor for application switching
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    func cleanup() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidChange(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier?.contains("zoom") == true {
            // If Zoom is in focus, ensure we're in the correct mode
            hideApp()
        }
    }
    
    private func hideApp() {
        guard !isHidden else { return }
        
        // Hide from application switcher
        makeAppInvisibleInAppSwitcher(true)
        
        // Hide all application windows
        NSApplication.shared.windows.forEach { window in
            window.orderOut(nil)
        }
        
        isHidden = true
    }
    
    private func showApp() {
        guard isHidden else { return }
        
        // Show in application switcher again
        makeAppInvisibleInAppSwitcher(false)
        
        // Show application windows
        NSApplication.shared.windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
        
        isHidden = false
    }
    
    private func toggleVisibility() {
        if isHidden {
            showApp()
        } else {
            hideApp()
        }
    }
    
    private func makeAppInvisibleInAppSwitcher(_ invisible: Bool) {
        // This uses a private API attribute to hide the app from Cmd+Tab
        // In a real implementation, this would require more careful handling
        
        // Approach 1: Using LSUIElement (requires relaunch)
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = [
            "write", 
            Bundle.main.bundleIdentifier ?? "", 
            "LSUIElement", 
            invisible ? "1" : "0"
        ]
        try? task.run()
        
        // Approach 2: For immediate effect, we'd use a private API
        // Note: This is simplified and would need actual implementation
        if let appDelegate = NSApp.delegate {
            // This would use Objective-C runtime to modify properties
            // that hide the app from the app switcher
            // Actual implementation would be more complex
        }
    }
} 