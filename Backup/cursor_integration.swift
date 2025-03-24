import Foundation
import Cocoa

class CursorIntegration {
    private var clipboardTimer: Timer?
    private var lastClipboardContent: String = ""
    
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
        simulatePaste()
    }
    
    private func checkClipboard() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string) else { return }
        
        // If clipboard has changed and it's from our app
        if clipboardString != lastClipboardContent && clipboardString.contains("/*!TIAS-GENERATED*/") {
            // Process clipboard content for Cursor
            let processedContent = clipboardString.replacingOccurrences(of: "/*!TIAS-GENERATED*/", with: "")
            
            // Keep track of the processed content
            lastClipboardContent = processedContent
            
            // Now paste to Cursor with human-like typing simulation if needed
            // typeHumanLike(processedContent)
        }
    }
    
    private func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("/*!TIAS-GENERATED*/" + string, forType: .string)
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
    
    // Optional: Human-like typing simulation
    func typeHumanLike(_ text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let source = CGEventSource(stateID: .hidSystemState)
            
            for char in text {
                // Get key code for character
                let keyCode = self.keyCodeForChar(String(char))
                if keyCode == nil {
                    continue // Skip unsupported characters
                }
                
                // Create key down event
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode!, keyDown: true)
                
                // Create key up event
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode!, keyDown: false)
                
                // Post key events
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                
                // Random delay between 75ms and 150ms as specified in the requirements
                let randomDelay = Double.random(in: 0.075...0.15)
                Thread.sleep(forTimeInterval: randomDelay)
            }
        }
    }
    
    private func keyCodeForChar(_ char: String) -> CGKeyCode? {
        // Simplified mapping - in a real implementation, this would be more comprehensive
        let keyMap: [String: CGKeyCode] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05,
            "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C,
            "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10, "t": 0x11, "1": 0x12,
            "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
            "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E,
            "o": 0x1F, "u": 0x20, "[": 0x21, "i": 0x22, "p": 0x23, "l": 0x25,
            "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29, "\\": 0x2A, ",": 0x2B,
            "/": 0x2C, "n": 0x2D, "m": 0x2E, ".": 0x2F, " ": 0x31
        ]
        
        return keyMap[char.lowercased()]
    }
} 