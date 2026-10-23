import Foundation

/// An app in "Open at Login", the list System Events manages.
public struct LoginItem: Identifiable, Equatable, Sendable {
    public var id: String { path.isEmpty ? name : path }
    public let name: String
    /// The app's path, e.g. "/Applications/Steam.app"; empty when unknown.
    public let path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

/// The AppleScript Keel runs through `osascript` to read and change the
/// list, and the parsing of its answer.
public enum LoginItemScript {
    /// One item per line: name, a tab, then the path.
    public static let list = """
    set answer to ""
    tell application "System Events"
        repeat with anItem in every login item
            set answer to answer & (name of anItem) & tab & (path of anItem) & linefeed
        end repeat
    end tell
    return answer
    """

    public static func parse(_ output: String) -> [LoginItem] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            var path = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            if path == "missing value" { path = "" }
            while path.count > 1, path.hasSuffix("/") { path.removeLast() }
            return LoginItem(name: name, path: path)
        }
    }

    public static func remove(_ item: LoginItem) -> String {
        "tell application \"System Events\" to delete login item \(ShellCommand.appleScriptString(item.name))"
    }

    /// Adds the app back; nil when its path is unknown.
    public static func add(_ item: LoginItem) -> String? {
        guard !item.path.isEmpty else { return nil }
        return "tell application \"System Events\" to make login item at end with properties {path:\(ShellCommand.appleScriptString(item.path)), hidden:false}"
    }
}
