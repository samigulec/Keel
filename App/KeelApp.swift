import SwiftUI

@main
struct KeelApp: App {
    static let mainWindowID = "main"

    @State private var status: SystemStatus
    @State private var cleanup: CleanupModel
    @State private var performance: PerformanceModel
    @State private var applications: ApplicationsModel
    @State private var largeFiles: LargeFilesModel
    @State private var smartCare: SmartCareModel
    @State private var assistant: AssistantModel

    init() {
        let status = SystemStatus()
        let cleanup = CleanupModel(status: status)
        let performance = PerformanceModel()
        let applications = ApplicationsModel(status: status)
        _status = State(initialValue: status)
        _cleanup = State(initialValue: cleanup)
        _performance = State(initialValue: performance)
        _applications = State(initialValue: applications)
        let largeFiles = LargeFilesModel(status: status)
        _largeFiles = State(initialValue: largeFiles)
        _smartCare = State(initialValue: SmartCareModel(
            status: status, cleanup: cleanup, applications: applications, largeFiles: largeFiles, performance: performance
        ))
        _assistant = State(initialValue: AssistantModel(
            status: status, cleanup: cleanup, performance: performance, applications: applications, largeFiles: largeFiles
        ))
    }

    var body: some Scene {
        Window("Keel", id: Self.mainWindowID) {
            RootView()
                .environment(status)
                .environment(cleanup)
                .environment(performance)
                .environment(applications)
                .environment(largeFiles)
                .environment(smartCare)
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
