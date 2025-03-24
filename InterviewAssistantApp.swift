import SwiftUI

@main
struct InterviewAssistantApp: App {
    @StateObject private var viewModel = InterviewAssistantViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }  // Remove new document menu item
            
            CommandMenu("Interview Assistant") {
                Button("Start Listening") {
                    viewModel.startListening()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button("Stop Listening") {
                    viewModel.stopListening()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Enter Split Mode") {
                    viewModel.setupSplitMode()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("Hide Application") {
                    viewModel.hideApp()
                }
                .keyboardShortcut("h", modifiers: [.command, .option])
            }
        }
    }
} 