import SwiftUI

/// Started by `KeelMain`.
struct KeelApp: App {
    static let mainWindowID = "main"

    @State private var status: SystemStatus
    @State private var cleanup: CleanupModel
    @State private var performance: PerformanceModel
    @State private var applications: ApplicationsModel
    @State private var largeFiles: LargeFilesModel
    @State private var smartCare: SmartCareModel
    @State private var navigation = AppNavigation()
    @AppStorage(Preference.menuBarVisible) private var menuBarVisible = true
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
                .environment(navigation)
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandMenu("Git") {
                ForEach(Array(AppSection.allCases.enumerated()), id: \.element) { index, section in
                    Button(section.title) { navigation.selection = section }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
        }

        Settings {
            SettingsView()
                .environment(assistant)
        }

        // One way only: with a two-way binding the system can write the
        // setting back on each update and rebuild the app's scenes again.
        MenuBarExtra("Keel", systemImage: "gauge.with.dots.needle.33percent", isInserted: .constant(menuBarVisible)) {
            MenuBarContent()
                .environment(status)
        }
        .menuBarExtraStyle(.window)
    }
}
