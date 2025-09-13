import SwiftUI

@main
struct ShibidoroApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var trayIconManager = TrayIconManager()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(timerManager)
                .onAppear {
                    trayIconManager.setup(timerManager: timerManager)
                    // Hide the app from dock
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 340, height: 280)
    }
}