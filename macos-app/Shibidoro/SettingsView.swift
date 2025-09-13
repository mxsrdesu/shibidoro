import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) private var dismiss

    @State private var focusDurationMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var sessionsBeforeLongBreak: Double = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                Section("Timer Durations") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Focus Session:")
                                .frame(width: 130, alignment: .leading)
                            Slider(value: $focusDurationMinutes, in: 1...60, step: 1)
                            Text("\(Int(focusDurationMinutes)) min")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }

                        HStack {
                            Text("Short Break:")
                                .frame(width: 130, alignment: .leading)
                            Slider(value: $shortBreakMinutes, in: 1...30, step: 1)
                            Text("\(Int(shortBreakMinutes)) min")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }

                        HStack {
                            Text("Long Break:")
                                .frame(width: 130, alignment: .leading)
                            Slider(value: $longBreakMinutes, in: 5...60, step: 1)
                            Text("\(Int(longBreakMinutes)) min")
                                .frame(width: 50, alignment: .trailing)
                                .monospacedDigit()
                        }
                    }
                }

                Section("Session Configuration") {
                    HStack {
                        Text("Sessions before long break:")
                            .frame(width: 180, alignment: .leading)
                        Slider(value: $sessionsBeforeLongBreak, in: 2...8, step: 1)
                        Text("\(Int(sessionsBeforeLongBreak))")
                            .frame(width: 30, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)

            Spacer()

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    Task {
                        await saveSettings()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(timerManager.isLoading)
            }
        }
        .padding()
        .frame(width: 450, height: 350)
        .onAppear {
            loadCurrentSettings()
        }
    }

    private func loadCurrentSettings() {
        guard let settings = timerManager.settings else { return }

        focusDurationMinutes = Double(settings.focusDuration / 60)
        shortBreakMinutes = Double(settings.shortBreakDuration / 60)
        longBreakMinutes = Double(settings.longBreakDuration / 60)
        sessionsBeforeLongBreak = Double(settings.sessionsBeforeLongBreak)
    }

    private func saveSettings() async {
        let newSettings = Settings(
            focusDuration: Int(focusDurationMinutes) * 60,
            shortBreakDuration: Int(shortBreakMinutes) * 60,
            longBreakDuration: Int(longBreakMinutes) * 60,
            sessionsBeforeLongBreak: Int(sessionsBeforeLongBreak)
        )

        await timerManager.updateSettings(newSettings)

        if timerManager.error == nil {
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TimerManager())
}