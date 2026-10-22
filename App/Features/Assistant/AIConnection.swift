import Foundation
import KeelCore

/// Which AI the user connected. The API key is kept in the Keychain, not here.
struct AIConnection: Codable, Equatable {
    enum Kind: String, Codable {
        /// Apple's on-device model: no key, no account, nothing leaves the Mac.
        case apple
        /// The user's own Claude account, through the Claude Code tool they installed.
        case claudeCode
        case claude
        case openAICompatible
    }

    /// Model choices for a Claude account; Claude Code resolves the aliases.
    static let claudeCodeModels: [(alias: String, name: String)] = [
        ("default", "Hesabının varsayılanı"),
        ("opus", "Opus"),
        ("sonnet", "Sonnet"),
        ("haiku", "Haiku"),
    ]

    var kind: Kind
    var model: String
    /// OpenAI-compatible only: the preset the user started from and its endpoint.
    var presetID: String?
    var baseURL: String?

    static let claudeDefault = AIConnection(kind: .claude, model: AnthropicBackend.defaultModel)
    static let apple = AIConnection(kind: .apple, model: "on-device")

    var keychainAccount: String {
        switch kind {
        case .apple: "apple"
        case .claudeCode: "claude-code"
        case .claude: "anthropic"
        case .openAICompatible: "openai-compatible:\(baseURL ?? "")"
        }
    }

    var needsKey: Bool {
        switch kind {
        case .apple, .claudeCode: false
        case .claude: true
        case .openAICompatible: preset?.needsKey ?? true
        }
    }

    var preset: OpenAICompatibleBackend.Preset? {
        OpenAICompatibleBackend.presets.first { $0.id == presetID }
    }

    var providerName: String {
        switch kind {
        case .apple: "Apple Intelligence"
        case .claudeCode: "Claude hesabı"
        case .claude: "Claude API"
        case .openAICompatible: preset?.name ?? "OpenAI uyumlu"
        }
    }

    var modelName: String {
        if kind == .apple { return "Cihaz üzerinde" }
        if kind == .claudeCode {
            return Self.claudeCodeModels.first { $0.alias == model }?.name ?? model
        }
        return AnthropicBackend.models.first { $0.id == model }?.name ?? model
    }

    /// Runs on this Mac: nothing is sent to a server.
    var isLocal: Bool {
        kind == .apple || (baseURL.map { $0.contains("localhost") || $0.contains("127.0.0.1") } ?? false)
    }

    func backend(apiKey: String?) throws -> any ChatBackend {
        switch kind {
        case .apple, .claudeCode:
            throw AIError.invalidResponse("\(providerName) HTTP üzerinden çalışmaz")
        case .claude:
            return AnthropicBackend(apiKey: apiKey ?? "", model: model)
        case .openAICompatible:
            guard let baseURL, let url = URL(string: baseURL) else {
                throw AIError.invalidResponse("Geçersiz sunucu adresi")
            }
            return OpenAICompatibleBackend(baseURL: url, apiKey: apiKey, model: model)
        }
    }

    // MARK: Persistence

    private static let defaultsKey = "keel.ai.connection"

    static func load() -> AIConnection? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(AIConnection.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
