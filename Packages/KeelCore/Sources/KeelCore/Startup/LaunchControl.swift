import Foundation

/// Turning launchd jobs off and on with `launchctl`, the way System Settings'
/// "Allow in the Background" switches do. Disabling is remembered by launchd
/// across restarts and undone by enabling; the job's plist is never touched.
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
