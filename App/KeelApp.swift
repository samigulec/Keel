import SwiftUI

@main
struct KeelApp: App {
    static let mainWindowID = "main"

    @State private var status: SystemStatus
    @State private var cleanup: CleanupModel
    @State private var performance: PerformanceModel
    @State private var assistant: AssistantModel

    init() {
        let status = SystemStatus()
        let cleanup = CleanupModel(status: status)
        let performance = PerformanceModel()
        _status = State(initialValue: status)
        _cleanup = State(initialValue: cleanup)
        _performance = State(initialValue: performance)
        _assistant = State(initialValue: AssistantModel(status: status, cleanup: cleanup, performance: performance))
    }

    var body: some Scene {
        Window("Keel", id: Self.mainWindowID) {
            RootView()
                .environment(status)
                .environment(cleanup)
                .environment(performance)
                .environment(assistant)
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
