import AppKit
import KeelCore

/// A provider's own command line tool the user installed: Claude Code for
/// Claude, Codex for ChatGPT. Sign-in always happens in the tool's own flow;
/// Keel never sees or stores the account's credentials.
@MainActor
final class CLITool {
    struct Account: Equatable {
        var executable: URL?
        var isLoggedIn = false
        /// What to show under the provider's name, e.g. the account's email.
        var detail: String?

        var isInstalled: Bool { executable != nil }
    }

    let command: String
    let installCommand: String
    let setupGuide: URL
    private let loginArguments: [String]
    private let logoutArguments: [String]
    private let statusArguments: [String]
    private let readStatus: (_ exitStatus: Int32, _ output: String) -> (isLoggedIn: Bool, detail: String?)
    /// Variables that would make the tool use an API key instead of the account.
    private let removedVariables: [String]
    private var cachedExecutable: URL?

    private init(
        command: String,
        installCommand: String,
        setupGuide: URL,
        loginArguments: [String],
        logoutArguments: [String],
        statusArguments: [String],
        removedVariables: [String],
        readStatus: @escaping (Int32, String) -> (isLoggedIn: Bool, detail: String?)
    ) {
        self.command = command
        self.installCommand = installCommand
        self.setupGuide = setupGuide
        self.loginArguments = loginArguments
        self.logoutArguments = logoutArguments
        self.statusArguments = statusArguments
        self.removedVariables = removedVariables
        self.readStatus = readStatus
    }

    static let claude = CLITool(
        command: "claude",
        installCommand: "curl -fsSL https://claude.ai/install.sh | bash",
        setupGuide: URL(string: "https://code.claude.com/docs/en/setup")!,
        loginArguments: ["auth", "login"],
        logoutArguments: ["auth", "logout"],
        statusArguments: ["auth", "status"],
        removedVariables: ["ANTHROPIC_API_KEY"]
    ) { exitStatus, output in
        // `claude auth status` prints JSON with authMethod and the account's email.
        let json = try? JSONValue.parse(output)
        let method = json?["authMethod"]?.stringValue
        let isLoggedIn = exitStatus == 0 && json != nil && method != "none"
        if method == "api_key" { return (isLoggedIn, "Claude Code bir API anahtarıyla girişli") }
        return (isLoggedIn, json.flatMap { CLITool.firstString(named: "email", in: $0) })
    }

    static let codex = CLITool(
        command: "codex",
        installCommand: "curl -fsSL https://chatgpt.com/codex/install.sh | sh",
        setupGuide: URL(string: "https://developers.openai.com/codex/cli")!,
        loginArguments: ["login"],
        logoutArguments: ["logout"],
        statusArguments: ["login", "status"],
        removedVariables: ["OPENAI_API_KEY", "CODEX_API_KEY"]
    ) { exitStatus, output in
        // `codex login status` prints e.g. "Logged in using ChatGPT" and exits 0.
        let isLoggedIn = exitStatus == 0 && output.contains("Logged in")
        let detail = output.contains("API key") ? "Codex bir API anahtarıyla girişli" : nil
        return (isLoggedIn, detail)
    }

    // MARK: Finding the tool

    func locate() async -> URL? {
        if let cachedExecutable, FileManager.default.isExecutableFile(atPath: cachedExecutable.path) {
            return cachedExecutable
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let folders = ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "\(home)/.npm-global/bin", "\(home)/.\(command)/bin", "\(home)/.claude/local"]
        if let found = folders.map({ "\($0)/\(command)" }).first(where: FileManager.default.isExecutableFile(atPath:)) {
            cachedExecutable = URL(fileURLWithPath: found)
            return cachedExecutable
        }
        // Apps do not get the user's shell PATH; ask a login shell instead.
        let shell = try? await ProcessLines.run(URL(fileURLWithPath: "/bin/zsh"), arguments: ["-lc", "command -v \(command)"])
        if let path = shell?.output.split(separator: "\n").last.map(String.init),
           path.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: path) {
            cachedExecutable = URL(fileURLWithPath: path)
        }
        return cachedExecutable
    }

    /// Common install folders on PATH, and no API key variables, so the
    /// user's account login is what the tool uses.
    var environment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extra = ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin"]
        environment["PATH"] = (extra + [environment["PATH"] ?? "/usr/bin:/bin"]).joined(separator: ":")
        for variable in removedVariables { environment.removeValue(forKey: variable) }
        return environment
    }

    /// An empty folder of Keel's own, so no project's settings, hooks or
    /// instructions are picked up when the tool starts.
    var workingDirectory: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Keel/\(command)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func stream(_ arguments: [String]) async throws -> AsyncThrowingStream<String, any Error> {
        guard let executable = await locate() else { throw ProcessFailure(status: 127, standardError: "\(command) bulunamadı") }
        return try ProcessLines.stream(executable, arguments: arguments, environment: environment, currentDirectory: workingDirectory)
    }

    // MARK: Account

    func account() async -> Account {
        guard let executable = await locate() else { return Account() }
        var account = Account(executable: executable)
        guard let result = try? await ProcessLines.run(
            executable,
            arguments: statusArguments,
            environment: environment,
            currentDirectory: workingDirectory,
            mergingStandardError: true
        ) else { return account }
        let state = readStatus(result.status, result.output)
        account.isLoggedIn = state.isLoggedIn
        account.detail = state.detail
        return account
    }

    /// Starts the tool's own sign-in, which opens the browser. Links it
    /// prints are passed on, in case the browser did not open.
    func startLogin(onLink: @escaping @MainActor (URL) -> Void) async throws -> Task<Void, any Error> {
        guard let executable = await locate() else { throw ProcessFailure(status: 127, standardError: "\(command) bulunamadı") }
        let lines = try ProcessLines.stream(
            executable,
            arguments: loginArguments,
            environment: environment,
            currentDirectory: workingDirectory,
            mergingStandardError: true
        )
        return Task {
            for try await line in lines {
                if let link = Self.firstLink(in: line) { onLink(link) }
            }
        }
    }

    /// Fallback when sign-in needs a terminal: opens Terminal running it.
    func loginInTerminal() async {
        guard let executable = await locate() else { return }
        let script = FileManager.default.temporaryDirectory.appendingPathComponent("keel-\(command)-login.command")
        let arguments = loginArguments.joined(separator: " ")
        let contents = "#!/bin/zsh -l\n'\(executable.path)' \(arguments)\necho\necho \"Giriş tamamlandı; bu pencereyi kapatıp Keel'e dönebilirsin.\"\n"
        do {
            try contents.write(to: script, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
            NSWorkspace.shared.open(script)
        } catch {}
    }

    func logout() async {
        guard let executable = await locate() else { return }
        _ = try? await ProcessLines.run(executable, arguments: logoutArguments, environment: environment, currentDirectory: workingDirectory)
    }

    // MARK: Helpers

    nonisolated private static func firstLink(in line: String) -> URL? {
        guard let start = line.range(of: "https://") else { return nil }
        let link = line[start.lowerBound...].prefix { !$0.isWhitespace }
        return URL(string: String(link))
    }

    nonisolated private static func firstString(named key: String, in value: JSONValue) -> String? {
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
