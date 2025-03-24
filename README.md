# Interview Assistant

A discreet technical interview assistant that helps with answering questions during interviews. The application captures audio from your interview, transcribes it, identifies technical questions, and provides high-quality answers.

## Features

- **Audio Capture & Processing**: Captures and transcribes speech from interview conversations
- **Question Analysis**: Determines if a question is technical or coding-related
- **Response Generation**: Creates comprehensive answers to technical questions
- **Screen Sharing Protection**: Automatically detects and adjusts when screen is being shared
- **Window Management**: Floating assistant window that's easily togglable
- **Cursor IDE Integration**: Send generated code directly to Cursor

## Components

The project consists of two main components:

1. **InterviewAssistant**: macOS GUI application built with SwiftUI
2. **InterviewAssistantCLI**: Command-line interface for quick access during interviews

## Requirements

- macOS 12.0 or later
- OpenAI API Key (for Whisper and GPT API access)
- Xcode 14.0+ (for building)

## Setup

### GUI Application

1. Open the `InterviewAssistant` directory in Xcode
2. Build and run the application
3. On first launch, you'll be prompted to enter your OpenAI API key
4. Grant microphone permissions when requested

### CLI Application

1. Navigate to the `InterviewAssistantCLI` directory
2. Build using Swift Package Manager:
   ```bash
   swift build
   ```
3. Configure with your API key:
   ```bash
   ./.build/debug/InterviewAssistantCLI configure --api-key YOUR_API_KEY
   ```

## Usage

### GUI Application

1. Launch the application
2. Click the microphone button to start capturing audio
3. Questions will be automatically detected and transcribed
4. Answers will be generated and displayed in the assistant window
5. Use the Copy or "Send to Cursor" buttons to use the answers

### CLI Application

Listen to audio and generate responses:
```bash
InterviewAssistantCLI listen --auto-answer
```

Generate an answer for a specific question:
```bash
InterviewAssistantCLI answer "How would you implement a binary search tree in Swift?"
```

Get quick help during an interview:
```bash
InterviewAssistantCLI quick binary search
```

## Audio Capture Setup

For optimal results, install the BlackHole virtual audio driver to capture system audio:
1. Install BlackHole from https://existential.audio/blackhole/
2. Configure macOS Sound settings to route meeting audio through BlackHole
3. Select BlackHole as the input source in the Interview Assistant preferences

## Screen Sharing Protection

When screen sharing is detected, the application automatically:
1. Minimizes the assistant window
2. Makes UI elements more discreet
3. Renames window titles to appear as standard development tools

## Hotkeys

- `Cmd+Opt+A`: Show Assistant window
- `Cmd+Opt+H`: Hide Assistant window
- `Cmd+Opt+R`: Start/Stop Recording

## Notes

This application is intended to be used as a learning aid and support tool, not for misrepresenting technical skills. Users should use it primarily:

1. To reduce interview anxiety
2. To learn from the AI-generated explanations
3. As a supplement to their own knowledge

## License

This software is provided for educational purposes only. Use at your own discretion. 