import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Validates user LaunchAgent plists under `~/Library/LaunchAgents` and stops
/// their `launchd` jobs via shell-less `/bin/launchctl bootout gui/<uid>/<label>`
/// before the plist is moved to the Trash.
public struct LaunchAgentStopper: Sendable {
    public struct ProcessResult: Equatable, Sendable {
        public let exitCode: Int32
        public let output: String

        public init(exitCode: Int32, output: String = "") {
            self.exitCode = exitCode
            self.output = output
        }
    }

    public enum Validation: Equatable, Sendable {
        case valid(label: String)
        case denied(String)
    }

    public struct StopOutcome: Equatable, Sendable {
        public let label: String
        public let exitCode: Int32

        public var logDetail: String {
            exitCode == 0
                ? "launchctl bootout \(label) (exit 0)"
                : "launchctl bootout \(label) (not loaded, exit \(exitCode))"
        }
    }

    public struct StopError: Error, Equatable, Sendable {
        public let message: String
        public let logDetail: String

        public init(message: String, logDetail: String? = nil) {
            self.message = message
            self.logDetail = logDetail ?? message
        }
    }

    public typealias Runner = @Sendable (_ executable: URL, _ arguments: [String]) throws -> ProcessResult
    public typealias UserIDProvider = @Sendable () -> UInt32

    public static let launchctlURL = URL(fileURLWithPath: "/bin/launchctl")
    static let maxPlistBytes: Int = 1_048_576
    /// Exit codes launchctl returns when the job is simply not loaded.
    static let toleratedExitCodes: Set<Int32> = [0, 3, 113]

    public let launchAgentsRoots: [String]
    public let ownBundleIdentifier: String?
    private let runner: Runner
    private let userIDProvider: UserIDProvider

    public init(
        launchAgentsRoots: [String],
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier,
        runner: Runner? = nil,
        userIDProvider: UserIDProvider? = nil
    ) {
        self.launchAgentsRoots = launchAgentsRoots
        self.ownBundleIdentifier = ownBundleIdentifier
        self.runner = runner ?? Self.liveRunner
        self.userIDProvider = userIDProvider ?? { UInt32(getuid()) }
    }

    public static func standard(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> LaunchAgentStopper {
        let root = SafetyPolicy.canonicalPath(home.appendingPathComponent("Library/LaunchAgents", isDirectory: true))
        return LaunchAgentStopper(launchAgentsRoots: [root], ownBundleIdentifier: ownBundleIdentifier)
    }

    /// Validates that `url` is a regular `.plist` file directly inside one of
    /// `launchAgentsRoots` (read with `O_NOFOLLOW`), has a safe plain `<key>Label</key>`,
    /// and is neither an Apple service nor Keel itself.
    public static func validate(
        _ url: URL,
        launchAgentsRoots: [String],
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> Validation {
        let lexical = url.standardizedFileURL
        guard let parentPath = SafetyPolicy.realPath(lexical.deletingLastPathComponent().path) else {
            return .denied("arka plan görevi klasörü okunamadı")
        }
        guard launchAgentsRoots.contains(parentPath) else {
            return .denied("kullanıcı LaunchAgents klasöründe değil")
        }
        guard lexical.pathExtension.lowercased() == "plist" else {
            return .denied("bir plist dosyası değil")
        }

        let canonicalFile = SafetyPolicy.join(parentPath, lexical.lastPathComponent)
        let data: Data
        switch readRegularFileNoFollow(atPath: canonicalFile) {
        case .success(let bytes):
            data = bytes
        case .failure(.denied(let reason)):
            return .denied(reason)
        }

        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let label = plist["Label"] as? String else {
            return .denied("plist içinde geçerli Label yok")
        }
        guard isSafeLabel(label) else {
            return .denied("arka plan görevi etiketi geçersiz")
        }
        if isProtectedLabel(label, ownBundleIdentifier: ownBundleIdentifier) {
            return .denied("korunan sistem ya da Keel servisi")
        }
        return .valid(label: label)
    }

    /// Strict label gate: never empty, never `/`, `.` or `..`, and only safe
    /// launchd ASCII characters so `gui/<uid>/<label>` can never collapse to
    /// `gui/<uid>`.
    static func isSafeLabel(_ label: String) -> Bool {
        guard !label.isEmpty,
              label != ".",
              label != "..",
              !label.contains("/"),
              LaunchControl.isPlainLabel(label) else {
            return false
        }
        return true
    }

    static func isProtectedLabel(_ label: String, ownBundleIdentifier: String?) -> Bool {
        let lowered = label.lowercased()
        if lowered.hasPrefix("com.apple.") { return true }
        if lowered == "com.samigulec.keel" || lowered.hasPrefix("com.samigulec.keel.") { return true }
        if let own = ownBundleIdentifier?.lowercased(), !own.isEmpty {
            if lowered == own || lowered.hasPrefix(own + ".") { return true }
        }
        return false
    }

    /// Stops the user LaunchAgent backed by `url` without calling `disable`.
    /// Fails closed on validation failure, launch errors, or exit codes other
    /// than `0`, `3`, and `113`.
    public func stop(at url: URL) -> Result<StopOutcome, StopError> {
        let label: String
        switch Self.validate(url, launchAgentsRoots: launchAgentsRoots, ownBundleIdentifier: ownBundleIdentifier) {
        case .valid(let validLabel):
            label = validLabel
        case .denied(let reason):
            return .failure(StopError(message: reason, logDetail: "bootout refused: \(reason)"))
        }

        let target = "gui/\(userIDProvider())/\(label)"
        let result: ProcessResult
        do {
            result = try runner(Self.launchctlURL, ["bootout", target])
        } catch {
            return .failure(StopError(
                message: "Arka plan görevi durdurulamadı (\(label)): \(error.localizedDescription)",
                logDetail: "bootout \(label) launch error: \(error.localizedDescription)"
            ))
        }

        if Self.toleratedExitCodes.contains(result.exitCode) {
            return .success(StopOutcome(label: label, exitCode: result.exitCode))
        }
        return .failure(StopError(
            message: "Arka plan görevi durdurulamadı (\(label), çıkış \(result.exitCode))",
            logDetail: "bootout \(label) failed (exit \(result.exitCode))"
        ))
    }

    // MARK: - Helpers

    private enum ReadFailure: Error {
        case denied(String)
    }

    private static func readRegularFileNoFollow(atPath path: String) -> Result<Data, ReadFailure> {
        let fd = open(path, O_RDONLY | O_NOFOLLOW)
        if fd < 0 {
            if errno == ELOOP {
                return .failure(.denied("bir kısayol"))
            }
            return .failure(.denied("plist dosyası açılamadı"))
        }
        defer { close(fd) }

        var info = stat()
        guard fstat(fd, &info) == 0 else {
            return .failure(.denied("plist dosyası okunamadı"))
        }
        guard (info.st_mode & S_IFMT) == S_IFREG else {
            return .failure(.denied("normal bir plist dosyası değil"))
        }
        let size = Int(info.st_size)
        guard size >= 1, size <= maxPlistBytes else {
            return .failure(.denied("plist dosya boyutu geçersiz"))
        }

        var data = Data()
        data.reserveCapacity(size)
        var buffer = [UInt8](repeating: 0, count: 16_384)
        while true {
            let count = read(fd, &buffer, buffer.count)
            if count > 0 {
                data.append(contentsOf: buffer.prefix(count))
                if data.count > maxPlistBytes {
                    return .failure(.denied("plist dosya boyutu geçersiz"))
                }
            } else if count == 0 {
                break
            } else if errno == EINTR {
                continue
            } else {
                return .failure(.denied("plist dosyası okunamadı"))
            }
        }
        return .success(data)
    }

    private static func liveRunner(_ executable: URL, _ arguments: [String]) throws -> ProcessResult {
        #if os(macOS)
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: outputData, as: UTF8.self)
        return ProcessResult(exitCode: process.terminationStatus, output: output)
        #else
        return ProcessResult(exitCode: 0, output: "")
        #endif
    }
}
