import SwiftUI

@main
struct KeelApp: App {
    static let mainWindowID = "main"

    @State private var status: SystemStatus
    @State private var cleanup: CleanupModel
    @State private var performance = PerformanceModel()

    init() {
        let status = SystemStatus()
        _status = State(initialValue: status)
        _cleanup = State(initialValue: CleanupModel(status: status))
    }

    var body: some Scene {
        Window("Keel", id: Self.mainWindowID) {
            RootView()
                .environment(status)
                .environment(cleanup)
                .environment(performance)
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)

        MenuBarExtra("Keel", systemImage: "gauge.with.dots.needle.33percent") {
            MenuBarContent()
                .environment(status)
        }
        .menuBarExtraStyle(.window)
    }
}
