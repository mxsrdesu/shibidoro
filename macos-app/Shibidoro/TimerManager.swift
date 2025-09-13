import Foundation
import UserNotifications

@MainActor
class TimerManager: ObservableObject {
    @Published var currentState: TimerState?
    @Published var settings: Settings?
    @Published var isLoading = false
    @Published var error: Error?

    private var updateTimer: Timer?
    private let apiClient = APIClient()

    init() {
        requestNotificationPermission()
        Task {
            await loadInitialData()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func loadInitialData() async {
        isLoading = true
        error = nil

        do {
            async let timerState = apiClient.getTimerStatus()
            async let settingsData = apiClient.getSettings()

            currentState = try await timerState
            settings = try await settingsData

            if currentState?.status == .running {
                startLocalTimer()
            }
        } catch {
            self.error = error
            print("Failed to load initial data: \(error)")
        }

        isLoading = false
    }

    func startTimer() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            currentState = try await apiClient.startTimer()
            startLocalTimer()
        } catch {
            self.error = error
            print("Failed to start timer: \(error)")
        }

        isLoading = false
    }

    func pauseTimer() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            currentState = try await apiClient.pauseTimer()
            stopLocalTimer()
        } catch {
            self.error = error
            print("Failed to pause timer: \(error)")
        }

        isLoading = false
    }

    func skipSession() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            currentState = try await apiClient.skipSession()
            stopLocalTimer()
            await showSessionTransitionNotification()
        } catch {
            self.error = error
            print("Failed to skip session: \(error)")
        }

        isLoading = false
    }

    func completeSession() async {
        isLoading = true
        error = nil

        do {
            currentState = try await apiClient.completeSession()
            stopLocalTimer()
            await showSessionTransitionNotification()
        } catch {
            self.error = error
            print("Failed to complete session: \(error)")
        }

        isLoading = false
    }

    func updateSettings(_ newSettings: Settings) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            settings = try await apiClient.updateSettings(newSettings)
        } catch {
            self.error = error
            print("Failed to update settings: \(error)")
        }

        isLoading = false
    }

    private func startLocalTimer() {
        stopLocalTimer()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateLocalTimer()
            }
        }
    }

    private func stopLocalTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateLocalTimer() async {
        guard let state = currentState,
              state.status == .running,
              state.remainingTime > 0 else {
            return
        }

        let newRemainingTime = max(0, state.remainingTime - 1)
        currentState = TimerState(
            status: state.status,
            currentSessionType: state.currentSessionType,
            remainingTime: newRemainingTime,
            sessionCount: state.sessionCount,
            startTime: state.startTime
        )

        if newRemainingTime == 0 {
            await completeSession()
        }
    }

    private func showSessionTransitionNotification() async {
        guard let state = currentState else { return }

        let content = UNMutableNotificationContent()

        switch state.currentSessionType {
        case .focus:
            content.title = "Focus Session Ready"
            content.body = "Time to focus! 🎯"
        case .shortBreak:
            content.title = "Short Break"
            content.body = "Take a quick break! ☕️"
        case .longBreak:
            content.title = "Long Break"
            content.body = "Time for a longer break! 🌟"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    var isRunning: Bool {
        currentState?.status == .running
    }

    var isPaused: Bool {
        currentState?.status == .paused
    }

    var isStopped: Bool {
        currentState?.status == .stopped
    }

    var canStart: Bool {
        currentState?.status != .running
    }

    var canPause: Bool {
        currentState?.status == .running
    }

    var displayTime: String {
        guard let remainingTime = currentState?.remainingTime else {
            return "00:00"
        }
        return formatTime(remainingTime)
    }

    var sessionTypeDisplayName: String {
        currentState?.currentSessionType.displayName ?? "Focus"
    }

    deinit {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}