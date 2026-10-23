import Foundation

/// The fan helper: a launchd daemon, installed once behind the
/// administrator prompt, that launchd starts as root whenever Keel drops a
/// request file. Changing the fans then needs no password. It only ever
/// changes the fans; it runs a root-owned copy of Keel that the user
/// cannot modify, and does nothing while no request is waiting.
public enum FanHelper {
    /// Bump when the helper's behaviour changes, so Keel offers to reinstall it.
    public static let version = 1
    public static let label = "com.samigulec.Keel.fan"
    public static let daemonFlag = "--keel-fan-daemon"

    public static let executable = "/Library/PrivilegedHelperTools/\(label)"
    public static let plistPath = "/Library/LaunchDaemons/\(label).plist"
    /// Root-owned; holds the status and the version.
    public static let folder = "/Library/Application Support/Keel"
    /// Owned by the user who installed the helper; launchd watches it.
    public static let requestFolder = "\(folder)/FanRequest"
    public static let requestFile = "\(requestFolder)/request"
    public static let statusFile = "\(folder)/FanStatus"
    public static let versionFile = "\(folder)/helper-version"

    /// "<id> <setting>", written by Keel.
    public struct Request: Equatable, Sendable {
        public let id: String
        public let setting: FanSetting

        public init(id: String, setting: FanSetting) {
            self.id = id
            self.setting = setting
        }

        public init?(line: String) {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
            guard parts.count == 2, FanHelper.isPlainID(String(parts[0])),
                  let setting = FanSetting(argument: String(parts[1])) else { return nil }
            self.init(id: String(parts[0]), setting: setting)
        }

        public var line: String { "\(id) \(setting.argument)\n" }
    }

    /// "<id> ok|fail" and then one line each, written by the helper.
    public struct Status: Equatable, Sendable {
        public let id: String
        public let succeeded: Bool
        public let lines: [String]

        public init(id: String, succeeded: Bool, lines: [String]) {
            self.id = id
            self.succeeded = succeeded
            self.lines = lines
        }

        public init?(text: String) {
            var lines = text.split(separator: "\n").map(String.init)
            guard !lines.isEmpty else { return nil }
            let head = lines.removeFirst().split(separator: " ")
            guard head.count == 2, FanHelper.isPlainID(String(head[0])), head[1] == "ok" || head[1] == "fail" else { return nil }
            self.init(id: String(head[0]), succeeded: head[1] == "ok", lines: lines)
        }

        public var text: String {
            ([("\(id) \(succeeded ? "ok" : "fail")")] + lines).joined(separator: "\n") + "\n"
        }
    }

    static func isPlainID(_ id: String) -> Bool {
        (1...64).contains(id.count) && id.unicodeScalars.allSatisfy { ($0.isASCII && CharacterSet.alphanumerics.contains($0)) || $0 == "-" }
    }

    /// The daemon's plist, on one line so it travels inside a shell word.
    public static var plist: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>\
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\
        <plist version="1.0"><dict>\
        <key>Label</key><string>\(label)</string>\
        <key>ProgramArguments</key><array><string>\(executable)</string><string>\(daemonFlag)</string></array>\
        <key>WatchPaths</key><array><string>\(requestFolder)</string></array>\
        <key>ThrottleInterval</key><integer>1</integer>\
        </dict></plist>
        """
    }

    /// Installs or updates the helper from Keel's own executable; runs as root.
    public static func installScript(from source: String, userID: UInt32) -> String {
        let q = ShellCommand.quote
        return [
            "/bin/mkdir -p /Library/PrivilegedHelperTools \(q(requestFolder))",
            // A copy owned by root: the build Keel runs from belongs to the user.
            "/usr/bin/install -o root -g wheel -m 755 \(q(source)) \(q(executable))",
            "/usr/sbin/chown root:wheel \(q(folder))",
            "/bin/chmod 755 \(q(folder))",
            "/usr/sbin/chown \(userID) \(q(requestFolder))",
            "/bin/chmod 700 \(q(requestFolder))",
            "/usr/bin/printf '%s' \(q(plist)) > \(q(plistPath))",
            "/usr/sbin/chown root:wheel \(q(plistPath))",
            "/bin/chmod 644 \(q(plistPath))",
            "{ /bin/launchctl bootout system/\(label) 2>/dev/null; true; }",
            "/bin/launchctl bootstrap system \(q(plistPath))",
            "/usr/bin/printf '%s' \(version) > \(q(versionFile))",
        ].joined(separator: " && ")
    }

    /// Removes everything the install added; runs as root.
    public static func uninstallScript() -> String {
        let q = ShellCommand.quote
        return [
            "{ /bin/launchctl bootout system/\(label) 2>/dev/null; true; }",
            "/bin/rm -f \(q(plistPath)) \(q(executable))",
            "/bin/rm -rf \(q(folder))",
        ].joined(separator: " && ")
    }
}
