import AppKit
import KeelCore

/// Uses the Claude Code command line tool the user installed, so they can
/// sign in with their own Claude account. Sign-in always happens in Claude
/// Code's own flow; Keel never sees or stores the account's credentials.
@MainActor
enum ClaudeCodeCLI {
    struct Status: Equatable {
        var executable: URL?
        var isLoggedIn = false
        /// none, claude.ai, oauth_token, api_key, ... as Claude Code reports it.
        var authMethod: String?
        var email: String?

        var isInstalled: Bool { executable != nil }
    }

    static let installCommand = "curl -fsSL https://claude.ai/install.sh | bash"
    static let setupGuide = URL(string: "https://code.claude.com/docs/en/setup")!

    private static var cachedExecutable: URL?

    // MARK: Finding the tool

    static func locate() async -> URL? {
        if let cachedExecutable, FileManager.default.isExecutableFile(atPath: cachedExecutable.path) {
            return cachedExecutable
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(home)/.claude/local/claude",
            "\(home)/.npm-global/bin/claude",
        ]
        if let found = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) {
            cachedExecutable = URL(fileURLWithPath: found)
            return cachedExecutable
        }
        // Apps do not get the user's shell PATH; ask a login shell instead.
        let shell = try? await ProcessLines.run(URL(fileURLWithPath: "/bin/zsh"), arguments: ["-lc", "command -v claude"])
        if let path = shell?.output.split(separator: "\n").last.map(String.init),
           path.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: path) {
            cachedExecutable = URL(fileURLWithPath: path)
        }
        return cachedExecutable
    }

    /// The environment Claude Code runs with: common install folders on PATH,
    /// and no API key variable, so the user's account login is what it uses.
    static var environment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extra = ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin"]
        environment["PATH"] = (extra + [environment["PATH"] ?? "/usr/bin:/bin"]).joined(separator: ":")
        environment.removeValue(forKey: "ANTHROPIC_API_KEY")
        return environment
    }

    /// An empty folder of Keel's own, so no project's settings, hooks or MCP
    /// servers are picked up when Claude Code starts.
    static var workingDirectory: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Keel/ClaudeCode", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    // MARK: Account

    static func status() async -> Status {
        guard let executable = await locate() else { return Status() }
        var status = Status(executable: executable)
        guard let result = try? await ProcessLines.run(executable, arguments: ["auth", "status"], environment: environment, currentDirectory: workingDirectory) else {
            return status
        }
        let json = try? JSONValue.parse(result.output)
        status.authMethod = json?["authMethod"]?.stringValue
        status.email = json.flatMap { firstString(named: "email", in: $0) }
        status.isLoggedIn = result.status == 0 && status.authMethod != "none"
        return status
    }

    /// Starts Claude Code's own sign-in, which opens the browser. Links the
    /// tool prints are passed on, in case the browser did not open.
    static func startLogin(onLink: @escaping @MainActor (URL) -> Void) async throws -> Task<Void, any Error> {
        guard let executable = await locate() else { throw ProcessFailure(status: 127, standardError: "claude bulunamadı") }
        let lines = try ProcessLines.stream(executable, arguments: ["auth", "login"], environment: environment, currentDirectory: workingDirectory)
        return Task {
            for try await line in lines {
                if let link = firstLink(in: line) { onLink(link) }
            }
        }
    }

    /// Fallback when sign-in needs a terminal: opens Terminal running it.
    static func loginInTerminal() async {
        guard let executable = await locate() else { return }
        let script = FileManager.default.temporaryDirectory.appendingPathComponent("keel-claude-login.command")
        let contents = "#!/bin/zsh -l\n'\(executable.path)' auth login\necho\necho \"Giriş tamamlandı; bu pencereyi kapatıp Keel'e dönebilirsin.\"\n"
        do {
            try contents.write(to: script, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
            NSWorkspace.shared.open(script)
        } catch {}
    }

    static func logout() async {
        guard let executable = await locate() else { return }
        _ = try? await ProcessLines.run(executable, arguments: ["auth", "logout"], environment: environment, currentDirectory: workingDirectory)
    }

    // MARK: Helpers

    private static func firstLink(in line: String) -> URL? {
        guard let start = line.range(of: "https://") else { return nil }
        let link = line[start.lowerBound...].prefix { !$0.isWhitespace }
        return URL(string: String(link))
    }

    private static func firstString(named key: String, in value: JSONValue) -> String? {
        switch value {
        case .object(let object):
            if let found = object[key]?.stringValue { return found }
            return object.values.lazy.compactMap { firstString(named: key, in: $0) }.first
        case .array(let array):
            return array.lazy.compactMap { firstString(named: key, in: $0) }.first
        default:
            return nil
        }
    }
}
