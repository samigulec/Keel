import Foundation
import KeelCore

/// Runs the commands that change how the Mac starts up and cools itself.
/// Anything that needs root goes through macOS's own administrator prompt;
/// Keel never sees or keeps the password.
enum SystemControl {
    enum Outcome: Equatable {
        case done(String)
        case cancelled
        case failed(String)

        var errorMessage: String? {
            switch self {
            case .done, .cancelled: nil
            case .failed(let message): message
            }
        }
    }

    private static let osascript = URL(fileURLWithPath: "/usr/bin/osascript")

    /// A shell command as the user.
    static func run(_ command: String) async -> Outcome {
        guard let result = try? await ProcessLines.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", command], mergingStandardError: true) else {
            return .failed("Komut çalıştırılamadı.")
        }
        return result.status == 0 ? .done(result.output) : .failed(clean(result.output))
    }

    /// A shell command as root, after macOS asks for an administrator's password.
    static func runAsAdministrator(_ command: String, prompt: String) async -> Outcome {
        await appleScript(ShellCommand.administratorScript(command, prompt: prompt))
    }

    static func appleScript(_ source: String) async -> Outcome {
        guard let result = try? await ProcessLines.run(osascript, arguments: ["-e", source], mergingStandardError: true) else {
            return .failed("osascript çalıştırılamadı.")
        }
        if result.status == 0 { return .done(result.output.replacingOccurrences(of: "\r", with: "\n")) }
        // -128: the user pressed Cancel in the password or permission dialog.
        if result.output.contains("-128") { return .cancelled }
        // -1743: Keel may not control System Events yet.
        if result.output.contains("-1743") {
            return .failed("Keel'in System Events'i kullanmasına izin ver: Sistem Ayarları > Gizlilik ve Güvenlik > Otomasyon.")
        }
        return .failed(clean(result.output))
    }

    /// The message, without osascript's "execution error:" prefix and
    /// "(1)" suffix. `do shell script` ends lines with carriage returns.
    private static func clean(_ output: String) -> String {
        var text = output.replacingOccurrences(of: "\r", with: "\n")
        if let range = text.range(of: "execution error: ") { text = String(text[range.upperBound...]) }
        text = text.replacingOccurrences(of: #"\s*\(-?\d+\)\s*$"#, with: "", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Bilinmeyen hata." : text
    }

    // MARK: Background services

    static func overrides(domain: String) async -> [String: Bool] {
        guard let result = try? await ProcessLines.run(URL(fileURLWithPath: "/bin/launchctl"), arguments: ["print-disabled", domain]),
              result.status == 0 else { return [:] }
        return LaunchControl.parseOverrides(result.output)
    }

    /// Switches services and returns the problems, one line each. The
    /// session's run as the user; the system's together, behind one
    /// administrator prompt.
    static func setLaunchItems(_ items: [LaunchItem], enabled: Bool) async -> [String] {
        var problems: [String] = []
        var system: [LaunchItem] = []
        for item in items {
            if let refusal = LaunchControl.refusal(for: item) {
                problems.append("\(item.displayName): Keel bunu değiştirmez (\(refusal)).")
            } else if LaunchControl.needsAdministrator(item) {
                system.append(item)
            } else if case .failed(let message) = await run(LaunchControl.script(enable: enabled, item: item, userID: getuid())) {
                problems.append("\(item.displayName): \(message)")
            }
        }
        guard !system.isEmpty else { return problems }

        let script = system.map { "{ \(LaunchControl.script(enable: enabled, item: $0, userID: getuid())); }" }.joined(separator: " && ")
        let names = system.map { "\"\($0.displayName)\"" }.joined(separator: ", ")
        let verb = enabled ? "açmak" : "kapatmak"
        switch await runAsAdministrator(script, prompt: "Keel şu sistem servislerini \(verb) istiyor: \(names).") {
        case .done: break
        case .cancelled: problems.append("Yönetici izni verilmedi; sistem servisleri olduğu gibi kaldı.")
        case .failed(let message): problems.append(message)
        }
        return problems
    }

    // MARK: Login items

    static func loginItems() async -> Result<[LoginItem], LoginItemsError> {
        switch await appleScript(LoginItemScript.list) {
        case .done(let output): .success(LoginItemScript.parse(output))
        case .cancelled: .failure(LoginItemsError(message: "İzin verilmedi."))
        case .failed(let message): .failure(LoginItemsError(message: message))
        }
    }

    struct LoginItemsError: Error, Equatable {
        let message: String
    }

    // MARK: Fans

    static func setFans(_ setting: FanSetting) async -> Outcome {
        guard let executable = Bundle.main.executablePath else { return .failed("Keel'in kendi yolu bulunamadı.") }
        let command = ShellCommand.join([executable, FanCommand.flag, setting.argument])
        let prompt = switch setting {
        case .automatic: "Keel fanları yeniden macOS'in kontrolüne vermek istiyor."
        case .fixed(let percent): "Keel fanları en yüksek hızın %\(percent)'ine ayarlamak istiyor."
        }
        return await runAsAdministrator(command, prompt: prompt)
    }
}
