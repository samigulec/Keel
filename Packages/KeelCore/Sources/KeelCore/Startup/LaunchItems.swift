import Foundation

/// A launchd job that starts on its own: a LaunchAgent (runs in the user
/// session) or a LaunchDaemon (runs system-wide).
public struct LaunchItem: Identifiable, Equatable, Sendable {
    public enum Scope: String, Sendable {
        /// ~/Library/LaunchAgents, owned by the user.
        case user
        /// /Library/LaunchAgents, every user's session.
        case allUsers
        /// /Library/LaunchDaemons, runs as root.
        case system
    }

    public var id: String { url.path }
    public let url: URL
    public let label: String
    public let program: String?
    public let runsAtLoad: Bool
    public let keepsAlive: Bool
    /// Turned off, by the plist's own Disabled key or by `launchctl disable`
    /// (which wins when both say something).
    public let isDisabled: Bool
    public let scope: Scope

    /// The app the job belongs to when its program lives inside a bundle,
    /// e.g. "Google Updater", otherwise the job label.
    public var displayName: String {
        if let program,
           let appComponent = program.split(separator: "/").last(where: { $0.hasSuffix(".app") }) {
            return String(appComponent.dropLast(4))
        }
        return label
    }
}

public enum LaunchItemScanner {
    /// `sessionOverrides` and `systemOverrides` are what `launchctl
    /// print-disabled` reports for the user's session and for the system.
    public static func scan(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        sessionOverrides: [String: Bool] = [:],
        systemOverrides: [String: Bool] = [:]
    ) -> [LaunchItem] {
        let locations: [(URL, LaunchItem.Scope)] = [
            (home.appendingPathComponent("Library/LaunchAgents", isDirectory: true), .user),
            (URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true), .allUsers),
            (URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true), .system),
        ]
        return locations.flatMap { location in
            items(in: location.0, scope: location.1, overrides: location.1 == .system ? systemOverrides : sessionOverrides)
        }
    }

    static func items(in directory: URL, scope: LaunchItem.Scope, overrides: [String: Bool] = [:]) -> [LaunchItem] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "plist" }
            .compactMap { parse($0, scope: scope, overrides: overrides) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    static func parse(_ url: URL, scope: LaunchItem.Scope, overrides: [String: Bool] = [:]) -> LaunchItem? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let label = plist["Label"] as? String else { return nil }

        let program = (plist["Program"] as? String) ?? (plist["ProgramArguments"] as? [String])?.first
        // KeepAlive may be a bool or a dictionary of conditions.
        let keepsAlive = (plist["KeepAlive"] as? Bool) ?? (plist["KeepAlive"] is [String: Any])

        return LaunchItem(
            url: url,
            label: label,
            program: program,
            runsAtLoad: plist["RunAtLoad"] as? Bool ?? false,
            keepsAlive: keepsAlive,
            isDisabled: overrides[label] ?? plist["Disabled"] as? Bool ?? false,
            scope: scope
        )
    }
}
