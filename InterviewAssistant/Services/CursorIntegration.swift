import AppKit

class CursorIntegration {
    private var clipboardTimer: Timer?
    private var lastClipboardContent: String = ""
    private let markerPrefix = "/*!TIAS-GENERATED*/"
    
    func start() {
        // Monitor clipboard every 200ms as specified in the requirements
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stop() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }
    
    func sendToCursor(_ text: String) {
        // Copy to clipboard
        copyToClipboard(text)
        
        // Simulate paste keystroke in Cursor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.simulatePaste()
        }
    }
    
    private func checkClipboard() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string) else { return }
        
        // If clipboard has changed and it's from our app
        if clipboardString != lastClipboardContent && clipboardString.contains(markerPrefix) {
            // Process clipboard content for Cursor
            let processedContent = clipboardString.replacingOccurrences(of: markerPrefix, with: "")
            
            // Keep track of the processed content
            lastClipboardContent = processedContent
            
            // Now paste to Cursor with human-like typing simulation if needed
            // Can be uncommented for production use
            // typeHumanLike(processedContent)
        }
    }
    
    private func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markerPrefix + string, forType: .string)
    }
    
    private func simulatePaste() {
        // Simulate Cmd+V keystroke
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down for command
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        
        // Key down for V
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        
        // Key up for V
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Key up for command
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // Post the events
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    // Human-like typing simulation
    func typeHumanLike(_ text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let source = CGEventSource(stateID: .hidSystemState)
            
            for char in text {
                // Get key code for character (simplified implementation)
                guard let charStr = String(char).utf16.first,
                      let keyCode = self.keyCodeForChar(charStr) else {
                    continue
                }
                
                // Create key down event
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
                
                // Create key up event
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
                
                // Post events
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                
                // Random delay between 75ms and 150ms as specified in requirements
                let randomDelay = Double.random(in: 0.075...0.15)
                Thread.sleep(forTimeInterval: randomDelay)
            }
        }
    }
    
    // Very basic key code mapping - would need to be expanded in a real implementation
    private func keyCodeForChar(_ char: UInt16) -> UInt16? {
        // This is an extremely simplified mapping - only includes some common keys
        let keyMap: [UInt16: UInt16] = [
            0x61: 0x00, // a
            0x73: 0x01, // s
            0x64: 0x02, // d
            0x66: 0x03, // f
            0x68: 0x04, // h
            0x67: 0x05, // g
            0x7A: 0x06, // z
            0x78: 0x07, // x
            0x63: 0x08, // c
            0x76: 0x09, // v
            0x20: 0x31  // space
        ]
        
        return keyMap[char]
    }
} 