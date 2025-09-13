# 🍅 Shibidoro - Pomodoro Timer

A native macOS Pomodoro timer app with a Flask backend for session tracking and statistics. Features a beautiful tray icon interface and comprehensive session management.

## ✨ Features

### 🎯 **Native macOS Integration**
- **Menu bar app** - Runs in the system tray (no dock icon)
- **Dynamic tray icon** with real-time countdown display
- **Visual status indicators**:
  - 🎯 Green background during focus sessions
  - ☕️ Orange background during breaks
  - ⏸ Yellow background when paused
  - ⭕️ Neutral when stopped

### 🖱️ **Intuitive Controls**
- **Left-click tray icon**: Show/hide main window
- **Right-click tray icon**: Play/pause timer
- **Main window**: Full timer controls and session info
- **Settings panel**: Configure all timer durations

### 📊 **Session Management**
- **Automatic progression**: Focus → Short Break → Focus → Long Break
- **Session tracking**: Complete statistics with timestamps
- **REST API**: Full backend integration for data persistence
- **Real-time sync**: Timer state synchronized between app and backend

### 🔔 **Smart Notifications**
- System notifications for session transitions
- Contextual messages for different session types
- Native macOS notification center integration

## 🏗️ **Architecture**

```
shibidoro/
├── backend/           # Flask API server
│   ├── app.py        # Main Flask application
│   ├── requirements.txt
│   ├── Dockerfile    # Docker configuration
│   └── docker-compose.yml
└── macos-app/        # SwiftUI macOS application
    └── Shibidoro/    # Xcode project
        ├── ShibidoroApp.swift
        ├── TimerManager.swift
        ├── TrayIconManager.swift
        ├── APIClient.swift
        ├── ContentView.swift
        └── SettingsView.swift
```

## 🚀 **Quick Start**

### **Backend Setup**
```bash
cd backend

# Option 1: Docker (Recommended)
docker-compose up --build

# Option 2: Local Development
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

Backend runs on `http://localhost:5001`

### **macOS App Setup**
1. Open `macos-app/Shibidoro.xcodeproj` in Xcode
2. Build and run (⌘+R)
3. Look for the tray icon in your menu bar showing "⭕️ 00:00"

## 🎮 **Usage**

1. **Start a session**: Click the tray icon → main window → Start button
2. **Monitor progress**: Watch the countdown in the tray icon (🎯 24:59, 24:58...)
3. **Quick controls**: Right-click tray icon to pause/resume
4. **Configure settings**: Access via main window settings button
5. **View statistics**: Session history tracked automatically

## ⚙️ **Default Settings**

- **Focus session**: 25 minutes
- **Short break**: 5 minutes
- **Long break**: 15 minutes
- **Sessions before long break**: 4

All durations are fully configurable via the settings panel.

## 🔌 **API Endpoints**

### Timer Operations
- `GET /timer/status` - Get current timer state
- `POST /timer/start` - Start the timer
- `POST /timer/pause` - Pause the timer
- `POST /timer/skip` - Skip current session
- `POST /timer/complete` - Complete session (auto-called)

### Configuration
- `GET /settings` - Get timer settings
- `PUT /settings` - Update timer settings

### Statistics
- `GET /stats/sessions` - Session history with filters
- `GET /stats/today` - Today's session statistics

## 🗄️ **Database Schema**

**SQLite database with:**
- **Settings**: Timer durations and configuration
- **TimerState**: Current timer state and session info
- **Session**: Historical session records with timestamps

## 🛠️ **Tech Stack**

### Backend
- **Flask** - Web framework
- **SQLAlchemy** - Database ORM
- **SQLite** - Database
- **Docker** - Containerization
- **Flask-CORS** - Cross-origin support

### macOS App
- **SwiftUI** - UI framework
- **AppKit** - Native macOS integration
- **UserNotifications** - System notifications
- **Foundation** - HTTP client and data handling

## 📋 **Requirements**

- **macOS**: 13.0+ (Ventura)
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Python**: 3.9+
- **Docker**: Optional but recommended

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

Inspired by popular Pomodoro timer apps like Flow and Tomito, built with modern native macOS technologies.
