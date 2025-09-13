import SwiftUI
import AppKit

@MainActor
class TrayIconManager: ObservableObject {
    @Published var displayText: String = "00:00"

    private var timerManager: TimerManager?
    private var statusBarItem: NSStatusItem?

    func setup(timerManager: TimerManager) {
        self.timerManager = timerManager

        // Set up status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem?.button {
            // Configure the button appearance
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

            // Set up click handlers
            button.action = #selector(statusBarButtonClicked)
            button.target = self

            // Enable right-click
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Start observing timer state changes
        startObservingTimer()
    }

    private func startObservingTimer() {
        guard timerManager != nil else { return }

        // Update display text whenever timer state changes
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDisplayText()
            }
        }
    }

    private func updateDisplayText() {
        guard let timerManager = timerManager,
              let state = timerManager.currentState else {
            displayText = "00:00"
            updateStatusBarButton()
            return
        }

        let timeString = timerManager.formatTime(state.remainingTime)

        // Add status indicator
        let statusIcon = getStatusIcon(for: state.status, sessionType: state.currentSessionType)
        displayText = "\(statusIcon) \(timeString)"

        updateStatusBarButton()
    }

    private func getStatusIcon(for status: TimerStatus, sessionType: SessionType) -> String {
        switch status {
        case .running:
            switch sessionType {
            case .focus:
                return "🎯"  // Focus indicator
            case .shortBreak, .longBreak:
                return "☕️"  // Break indicator
            }
        case .paused:
            return "⏸"
        case .stopped:
            switch sessionType {
            case .focus:
                return "⭕️"
            case .shortBreak, .longBreak:
                return "⭕️"
            }
        }
    }

    private func updateStatusBarButton() {
        guard let button = statusBarItem?.button else { return }

        // Update button title
        button.title = displayText

        // Update button background color based on session type and status
        if let state = timerManager?.currentState {
            let backgroundColor = getBackgroundColor(for: state.status, sessionType: state.currentSessionType)
            button.layer?.backgroundColor = backgroundColor.cgColor
            button.layer?.cornerRadius = 4
        }
    }

    private func getBackgroundColor(for status: TimerStatus, sessionType: SessionType) -> NSColor {
        switch status {
        case .running:
            switch sessionType {
            case .focus:
                return NSColor.systemGreen.withAlphaComponent(0.3)
            case .shortBreak, .longBreak:
                return NSColor.systemOrange.withAlphaComponent(0.3)
            }
        case .paused:
            return NSColor.systemYellow.withAlphaComponent(0.3)
        case .stopped:
            return NSColor.controlBackgroundColor
        }
    }

    @objc private func statusBarButtonClicked() {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .leftMouseUp:
            handleLeftClick()
        case .rightMouseUp:
            handleRightClick()
        default:
            break
        }
    }

    private func handleLeftClick() {
        // Show/hide main window
        toggleMainWindow()
    }

    private func handleRightClick() {
        // Toggle play/pause
        guard let timerManager = timerManager else { return }

        Task {
            if timerManager.isRunning {
                await timerManager.pauseTimer()
            } else if timerManager.canStart {
                await timerManager.startTimer()
            }
        }
    }

    private func toggleMainWindow() {
        // Find the main window
        let mainWindow = NSApplication.shared.windows.first { window in
            return window.contentViewController is NSHostingController<AnyView> ||
                   window.title.contains("Shibidoro") ||
                   window.contentView?.subviews.first?.className.contains("ContentView") == true
        }

        if let window = mainWindow {
            if window.isVisible && window.isMainWindow {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            // If no window found, activate the app which should create a new window
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    deinit {
        if let statusBarItem = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
        }
    }
}