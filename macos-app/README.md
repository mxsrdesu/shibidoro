# Shibidoro macOS App

Native SwiftUI macOS application for the Shibidoro Pomodoro timer.

## Features

- **Native Tray Icon**: Shows countdown timer and session status in menu bar
- **Dynamic Status Display**:
  - 🎯 Green background during focus sessions
  - ☕️ Orange background during breaks
  - ⏸ Yellow background when paused
- **Tray Interactions**:
  - Left-click: Show/hide main window
  - Right-click: Play/pause timer
- **Main Window**: Timer display with start/pause/skip controls
- **Settings**: Configurable timer durations
- **Notifications**: System notifications for session transitions
- **Background Operation**: Runs as menu bar app (hidden from dock)

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Open `Shibidoro.xcodeproj` in Xcode
2. Build and run the project
3. Ensure the backend is running on `http://localhost:5000`

## Architecture

### Key Components

- **ShibidoroApp**: Main app entry point, configures tray-only operation
- **TimerManager**: Core timer logic and backend synchronization
- **APIClient**: HTTP client for backend communication
- **TrayIconManager**: Native menu bar icon management
- **ContentView**: Main timer interface
- **SettingsView**: Timer configuration interface

### Data Models

- **TimerState**: Current timer status and session info
- **Settings**: Timer duration configuration
- **SessionStats**: Statistics and session history

## Backend Integration

The app communicates with the Flask backend via REST API:
- Timer operations (start/pause/skip)
- Settings management
- Session statistics
- Automatic session completion

## Permissions

The app requests:
- Network access (for backend communication)
- Notification permissions (for session alerts)