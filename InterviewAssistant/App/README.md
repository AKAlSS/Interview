# Technical Interview Assistant System

## Overview

The Technical Interview Assistant System (TIAS) is a macOS application designed to help software engineers during technical interviews. It captures audio from interview questions, transcribes them, and provides AI-generated responses that can be quickly copied to your clipboard or directly to Cursor IDE.

## Features

- **Live Transcription**: Captures and transcribes interview questions in real-time
- **Question Analysis**: Automatically detects if a question is technical, coding-related, or general
- **AI-Powered Responses**: Generates high-quality answers appropriate to the question type
- **Cursor Integration**: Sends responses directly to Cursor IDE with a single click
- **Screen Sharing Protection**: Automatically hides assistant windows when screen sharing is detected
- **Global Hotkeys**: Quick access with ⌘⌥A to show/hide the assistant

## Requirements

- macOS 11.0 or later
- OpenAI API Key (for question analysis and response generation)
- Microphone permissions
- Speech Recognition permissions

## Setup

1. Download and install the application
2. Launch the app
3. Enter your OpenAI API key in the settings
4. Grant necessary permissions when prompted:
   - Microphone access
   - Speech recognition access
   - Accessibility permissions (for global hotkeys)

## Usage

### Basic Workflow

1. Start the recording by clicking the "Start" button
2. Ask or listen to the technical question
3. Review the transcription to ensure accuracy
4. Click "Process" to analyze the question and generate a response
5. Use "Send to Cursor" to send the response to Cursor IDE

### Window Management

- The main window shows the full interface
- The assistant window is a floating panel with the current question and response
- Toggle the assistant window with ⌘⌥A hotkey or from the Assistant menu
- The assistant window automatically hides during screen sharing

### During Interviews

- Start recording at the beginning of the interview
- The app will transcribe what's said
- When a technical question is asked, review the transcription
- Generate an answer and copy it to Cursor IDE
- The assistant window stays hidden during screen sharing

## Tips

- Keep the app running in the background during your entire interview
- Use ⌘⌥A to quickly show/hide the assistant when needed
- For coding questions, the assistant will generate complete, runnable code
- Review and customize the AI responses before using them

## Troubleshooting

- If the assistant doesn't show with the hotkey, check if screen sharing is active
- If transcription doesn't work, verify microphone permissions
- If responses aren't generating, check your internet connection and API key

## Privacy

- All audio processing happens on your device
- Transcribed text and questions are sent to OpenAI for analysis
- No interview data is stored on external servers beyond what's required for API calls

## Support

For issues, questions, or feedback, please open an issue in the GitHub repository or contact support@interviewassistant.example.com.

---

This application is designed to help you succeed in technical interviews by providing quick access to accurate information. Always review the generated responses to ensure they match your understanding and coding style. 