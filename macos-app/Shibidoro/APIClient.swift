import Foundation

enum SessionType: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "short_break"
    case longBreak = "long_break"

    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

enum TimerStatus: String, Codable {
    case stopped = "stopped"
    case running = "running"
    case paused = "paused"
}

struct TimerState: Codable {
    let status: TimerStatus
    let currentSessionType: SessionType
    let remainingTime: Int
    let sessionCount: Int
    let startTime: String?

    enum CodingKeys: String, CodingKey {
        case status
        case currentSessionType = "current_session_type"
        case remainingTime = "remaining_time"
        case sessionCount = "session_count"
        case startTime = "start_time"
    }
}

struct Settings: Codable {
    let focusDuration: Int
    let shortBreakDuration: Int
    let longBreakDuration: Int
    let sessionsBeforeLongBreak: Int

    enum CodingKeys: String, CodingKey {
        case focusDuration = "focus_duration"
        case shortBreakDuration = "short_break_duration"
        case longBreakDuration = "long_break_duration"
        case sessionsBeforeLongBreak = "sessions_before_long_break"
    }
}

struct SessionStats: Codable {
    let sessions: [SessionRecord]
    let summary: StatsSummary
}

struct SessionRecord: Codable {
    let id: Int
    let sessionType: SessionType
    let duration: Int
    let startedAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionType = "session_type"
        case duration
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct StatsSummary: Codable {
    let totalSessions: Int
    let focusSessions: Int
    let totalFocusTimeSeconds: Int
    let totalFocusTimeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case focusSessions = "focus_sessions"
        case totalFocusTimeSeconds = "total_focus_time_seconds"
        case totalFocusTimeMinutes = "total_focus_time_minutes"
    }
}

struct TodayStats: Codable {
    let date: String
    let totalSessions: Int
    let focusSessions: Int
    let totalFocusTimeSeconds: Int
    let totalFocusTimeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalSessions = "total_sessions"
        case focusSessions = "focus_sessions"
        case totalFocusTimeSeconds = "total_focus_time_seconds"
        case totalFocusTimeMinutes = "total_focus_time_minutes"
    }
}

@MainActor
class APIClient: ObservableObject {
    private let baseURL = "http://localhost:5001"
    private let session = URLSession.shared

    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(responseType, from: data)
    }

    func getTimerStatus() async throws -> TimerState {
        return try await makeRequest(
            endpoint: "/timer/status",
            responseType: TimerState.self
        )
    }

    func startTimer() async throws -> TimerState {
        return try await makeRequest(
            endpoint: "/timer/start",
            method: "POST",
            responseType: TimerState.self
        )
    }

    func pauseTimer() async throws -> TimerState {
        return try await makeRequest(
            endpoint: "/timer/pause",
            method: "POST",
            responseType: TimerState.self
        )
    }

    func skipSession() async throws -> TimerState {
        return try await makeRequest(
            endpoint: "/timer/skip",
            method: "POST",
            responseType: TimerState.self
        )
    }

    func completeSession() async throws -> TimerState {
        return try await makeRequest(
            endpoint: "/timer/complete",
            method: "POST",
            responseType: TimerState.self
        )
    }

    func getSettings() async throws -> Settings {
        return try await makeRequest(
            endpoint: "/settings",
            responseType: Settings.self
        )
    }

    func updateSettings(_ settings: Settings) async throws -> Settings {
        let encoder = JSONEncoder()
        let body = try encoder.encode(settings)

        return try await makeRequest(
            endpoint: "/settings",
            method: "PUT",
            body: body,
            responseType: Settings.self
        )
    }

    func getSessionStats(
        startDate: String? = nil,
        endDate: String? = nil,
        sessionType: SessionType? = nil
    ) async throws -> SessionStats {
        var endpoint = "/stats/sessions"
        var queryItems: [String] = []

        if let startDate = startDate {
            queryItems.append("start_date=\(startDate)")
        }
        if let endDate = endDate {
            queryItems.append("end_date=\(endDate)")
        }
        if let sessionType = sessionType {
            queryItems.append("type=\(sessionType.rawValue)")
        }

        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }

        return try await makeRequest(
            endpoint: endpoint,
            responseType: SessionStats.self
        )
    }

    func getTodayStats() async throws -> TodayStats {
        return try await makeRequest(
            endpoint: "/stats/today",
            responseType: TodayStats.self
        )
    }
}