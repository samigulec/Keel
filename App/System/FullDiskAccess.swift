import AppKit

/// Full Disk Access lets Keel read the Trash and other protected folders.
/// macOS has no API to ask for it, so we probe a protected folder and send
/// the user to the right pane in System Settings.
@MainActor
enum FullDiskAccess {
    static var isGranted: Bool {
        let probe = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari", isDirectory: true)
        // stat works without access, listing does not. No Safari folder: nothing to tell.
        guard FileManager.default.fileExists(atPath: probe.path) else { return true }
        return (try? FileManager.default.contentsOfDirectory(atPath: probe.path)) != nil
    }

    static func openSettings() {
        let pane = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: pane) {
            NSWorkspace.shared.open(url)
        }
    }
}
