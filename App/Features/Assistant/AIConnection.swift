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

    /// How hard the model thinks; more effort is slower and costs more.
    static let effortLevels: [(id: String, detail: String)] = [
        ("low", "Hızlı ve kısa"),
        ("medium", "Dengeli"),
        ("high", "Özenli"),
        ("xhigh", "Çok özenli"),
        ("max", "En derin, en yavaş"),
    ]

    /// Claude models offered by number, newest first. Keel recommends the first.
    static let claudeModelIDs = [
        "claude-opus-5-5", "claude-sonnet-5-5", "claude-fable-5-1", "claude-haiku-5-5",
        "claude-opus-5", "claude-sonnet-5", "claude-fable-5",
        "claude-opus-4-8", "claude-opus-4-7", "claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5",
    ]
    static let recommendedClaudeModel = "claude-opus-5-5"

    /// The model Claude Code uses when Keel does not pick one, learned from
    /// its answers, so the picker can mark it.
    static var claudeCodeAccountDefault: String? {
        get { UserDefaults.standard.string(forKey: "keel.ai.claudeCode.accountDefault") }
        set { UserDefaults.standard.set(newValue, forKey: "keel.ai.claudeCode.accountDefault") }
    }

    var kind: Kind
    var model: String
    /// OpenAI-compatible only: the preset the user started from and its endpoint.
    var presetID: String?
    var baseURL: String?
    /// nil keeps the provider's default.
    var effort: String?

    var supportsEffort: Bool { kind == .claude || kind == .claudeCode }

    /// Models the picker offers for this kind of connection, as (id, name).
    var modelChoices: [(id: String, name: String)] {
        switch kind {
        case .apple:
            return [("on-device", "Cihazdaki model")]
        case .claudeCode:
            let accountDefault = Self.claudeCodeAccountDefault.map { " (\(ModelNames.display($0)))" } ?? ""
            return [("default", "Hesabın varsayılanı" + accountDefault)]
                + Self.claudeModelIDs.map { ($0, ModelNames.display($0)) }
        case .claude:
            return Self.claudeModelIDs.map { ($0, ModelNames.display($0)) }
        case .openAICompatible:
            return [(model, model)]
        }
    }

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
            return model == "default" ? "Hesabın varsayılanı" : ModelNames.display(model)
        }
        if kind == .claude { return ModelNames.display(model) }
        return model
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
            var backend = AnthropicBackend(apiKey: apiKey ?? "", model: model)
            if let effort { backend.effort = effort }
            return backend
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
