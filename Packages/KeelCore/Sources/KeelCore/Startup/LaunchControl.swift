import Foundation

/// Turning launchd jobs off and on with `launchctl disable` and `enable`.
/// The job's plist is never touched.
public enum LaunchControl {
    /// Parses `launchctl print-disabled <domain>`: label -> disabled.
    /// Recent macOS writes "enabled"/"disabled", older versions true/false.
    public static func parseOverrides(_ output: String) -> [String: Bool] {
        var overrides: [String: Bool] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.components(separatedBy: "=>")
            guard parts.count == 2 else { continue }
            let label = parts[0].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let state = parts[1].trimmingCharacters(in: .whitespaces)
            guard !label.isEmpty else { continue }
            switch state {
            case "disabled", "true": overrides[label] = true
            case "enabled", "false": overrides[label] = false
            default: continue
            }
        }
        return overrides
    }

    /// The launchd domain a job runs in: the user's session or the system.
    public static func domain(for item: LaunchItem, userID: UInt32) -> String {
        item.scope == .system ? "system" : "gui/\(userID)"
    }

    /// System-wide daemons need an administrator.
    public static func needsAdministrator(_ item: LaunchItem) -> Bool {
        item.scope == .system
    }

    /// Why Keel will not switch a job, or nil when it may.
    public static func refusal(for item: LaunchItem) -> String? {
        if item.label.hasPrefix("com.apple.") { return "macOS'in kendi servisi" }
        if !isPlainLabel(item.label) { return "etiketi beklenmedik karakterler içeriyor" }
        return nil
    }

    /// Letters, digits and the punctuation launchd labels use, e.g. Homebrew's
    /// "homebrew.mxcl.postgresql@16".
    static func isPlainLabel(_ label: String) -> Bool {
        !label.isEmpty && label.count <= 200 && label.unicodeScalars.allSatisfy {
            ($0.isASCII && CharacterSet.alphanumerics.contains($0)) || "._-@+".unicodeScalars.contains($0)
        }
    }

    /// A shell script that turns the job off (and stops it) or back on (and
    /// starts it). Stopping and starting may fail when the job is not
    /// running or already loaded; only the switch itself decides success.
    public static func script(enable: Bool, item: LaunchItem, userID: UInt32) -> String {
        let target = ShellCommand.quote("\(domain(for: item, userID: userID))/\(item.label)")
        if enable {
            let domain = ShellCommand.quote(domain(for: item, userID: userID))
            return "/bin/launchctl enable \(target) && { /bin/launchctl bootstrap \(domain) \(ShellCommand.quote(item.url.path)) 2>/dev/null; true; }"
        }
        return "/bin/launchctl disable \(target) && { /bin/launchctl bootout \(target) 2>/dev/null; true; }"
    }
}

/// Result of switching one or more background services. Service failures are
/// kept separate from log-write errors so callers know accurately which
/// services changed and whether undo applies.
public struct LaunchSwitchOutcome: Equatable, Sendable {
    public struct CardSummary: Equatable, Sendable {
        public let text: String
        public let isError: Bool
        public let canUndo: Bool
        public let undone: Bool

        public init(text: String, isError: Bool, canUndo: Bool, undone: Bool = false) {
            self.text = text
            self.isError = isError
            self.canUndo = canUndo
            self.undone = undone
        }
    }

    public var changed: [LaunchItem]
    public var serviceProblems: [String]
    public var logProblem: String?

    public init(changed: [LaunchItem] = [], serviceProblems: [String] = [], logProblem: String? = nil) {
        self.changed = changed
        self.serviceProblems = serviceProblems
        self.logProblem = logProblem
    }

    public var allProblems: [String] {
        serviceProblems + (logProblem.map { [$0] } ?? [])
    }

    public var succeeded: Bool { serviceProblems.isEmpty }
    public var canUndo: Bool { !changed.isEmpty }

    public func applySummary(enabled: Bool) -> CardSummary {
        let verb = enabled ? "açıldı" : "kapatıldı"
        if serviceProblems.isEmpty {
            let base = "\(changed.count) servis \(verb)."
            let text = logProblem.map { "\(base)\n\($0)" } ?? base
            return CardSummary(text: text, isError: false, canUndo: !changed.isEmpty)
        }
        var lines: [String] = []
        if !changed.isEmpty { lines.append("\(changed.count) servis \(verb).") }
        lines.append(contentsOf: allProblems)
        return CardSummary(text: lines.joined(separator: "\n"), isError: true, canUndo: !changed.isEmpty)
    }

    public func undoSummary() -> CardSummary {
        if serviceProblems.isEmpty {
            let base = "Geri alındı; servisler eski hâlinde."
            let text = logProblem.map { "\(base)\n\($0)" } ?? base
            return CardSummary(text: text, isError: false, canUndo: false, undone: true)
        }
        return CardSummary(text: allProblems.joined(separator: "\n"), isError: true, canUndo: false, undone: false)
    }
}

/// Quoting for commands handed to a shell or to AppleScript's `do shell script`.
public enum ShellCommand {
    /// One shell word, whatever it contains.
    public static func quote(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    public static func join(_ arguments: [String]) -> String {
        arguments.map(quote).joined(separator: " ")
    }

    /// A double-quoted AppleScript string.
    public static func appleScriptString(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    /// AppleScript that runs `command` as root after macOS asks for an
    /// administrator's password with `prompt`. Keel never sees the password.
    public static func administratorScript(_ command: String, prompt: String) -> String {
        "do shell script \(appleScriptString(command)) with prompt \(appleScriptString(prompt)) with administrator privileges"
    }
}
