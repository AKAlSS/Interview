import AppKit

class AppConcealer {
    private var isHidden = false
    private var eventMonitor: Any?
    
    init() {
        setupShortcutMonitor()
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupShortcutMonitor() {
        // Monitor for global keyboard shortcuts
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌘⌥H shortcut for hiding/showing
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 4 { // H key
                self?.toggleVisibility()
            }
            
            // ⌘⇥ (Command+Tab) detection for automatic hiding
            if event.modifierFlags.contains([.command]) && event.keyCode == 48 { // Tab key
                self?.hideApp()
            }
        }
    }
    
    func hideApp() {
        guard !isHidden else { return }
        
        // Hide all application windows
        NSApplication.shared.windows.forEach { window in
            window.orderOut(nil)
        }
        
        // Make app invisible in app switcher
        makeInvisibleInAppSwitcher(true)
        
        isHidden = true
    }
    
    func showApp() {
        guard isHidden else { return }
        
        // Make app visible in app switcher
        makeInvisibleInAppSwitcher(false)
        
        // Show all application windows
        NSApplication.shared.windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
        
        isHidden = false
    }
    
    func toggleVisibility() {
        if isHidden {
            showApp()
        } else {
            hideApp()
        }
    }
    
    private func makeInvisibleInAppSwitcher(_ invisible: Bool) {
        // This requires LSUIElement in Info.plist for permanent setting
        // For runtime toggling, we use a different approach:
        
        // Using NSApplication.shared.hide() for temporary hiding
        if invisible {
            NSApplication.shared.hide(nil)
        } else {
            NSApplication.shared.unhide(nil)
        }
        
        // In a full implementation, we would modify the Info.plist dynamically
        // or use a lower-level API to hide from the application switcher
        // NSWorkspace.shared.launchApplication(withProgramRelativeToPath...)
    }
} 