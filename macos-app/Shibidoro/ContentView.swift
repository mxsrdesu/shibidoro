import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 20) {
            if timerManager.isLoading {
                ProgressView("Loading...")
                    .frame(width: 300, height: 200)
            } else {
                VStack(spacing: 15) {
                    // Session type indicator
                    Text(timerManager.sessionTypeDisplayName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(sessionTypeColor)

                    // Timer display
                    Text(timerManager.displayTime)
                        .font(.system(size: 48, design: .monospaced))
                        .fontWeight(.light)
                        .foregroundColor(.primary)

                    // Session counter
                    if let sessionCount = timerManager.currentState?.sessionCount {
                        Text("Session \(sessionCount + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer().frame(height: 10)

                    // Control buttons
                    HStack(spacing: 15) {
                        if timerManager.canStart {
                            Button(action: {
                                Task { await timerManager.startTimer() }
                            }) {
                                Label("Start", systemImage: "play.fill")
                                    .frame(width: 80)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if timerManager.canPause {
                            Button(action: {
                                Task { await timerManager.pauseTimer() }
                            }) {
                                Label("Pause", systemImage: "pause.fill")
                                    .frame(width: 80)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button(action: {
                            Task { await timerManager.skipSession() }
                        }) {
                            Label("Skip", systemImage: "forward.fill")
                                .frame(width: 80)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(width: 300, height: 200)
            }

            // Bottom toolbar
            HStack {
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.link)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 340, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(timerManager)
        }
        .alert("Error", isPresented: .constant(timerManager.error != nil)) {
            Button("OK") {
                timerManager.error = nil
            }
        } message: {
            Text(timerManager.error?.localizedDescription ?? "Unknown error")
        }
    }

    private var sessionTypeColor: Color {
        guard let sessionType = timerManager.currentState?.currentSessionType else {
            return .primary
        }

        switch sessionType {
        case .focus:
            return .green
        case .shortBreak, .longBreak:
            return .orange
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerManager())
}