import Observation

/// The selected section, shared by the window and the menu commands.
@MainActor
@Observable
final class AppNavigation {
    var selection: AppSection = .smartScan
}

/// User preferences kept in UserDefaults; the keys live in one place.
enum Preference {
    static let menuBarVisible = "keel.menuBar.visible"
    static let companionButtonVisible = "keel.companion.buttonVisible"
    static let saveChatHistory = "keel.chat.saveHistory"
}
