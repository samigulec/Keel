import Foundation
import KeelCore

/// Which AI the user connected. The API key is kept in the Keychain, not here.
struct AIConnection: Codable, Equatable {
    enum Kind: String, Codable {
        case claude
        case openAICompatible
    }

    var kind: Kind
    var model: String
    /// OpenAI-compatible only: the preset the user started from and its endpoint.
    var presetID: String?
    var baseURL: String?

    static let claudeDefault = AIConnection(kind: .claude, model: AnthropicBackend.defaultModel)

    var keychainAccount: String {
        switch kind {
        case .claude: "anthropic"
        case .openAICompatible: "openai-compatible:\(baseURL ?? "")"
        }
    }

    var needsKey: Bool {
        switch kind {
        case .claude: true
        case .openAICompatible: preset?.needsKey ?? true
        }
    }

    var preset: OpenAICompatibleBackend.Preset? {
        OpenAICompatibleBackend.presets.first { $0.id == presetID }
    }

    var providerName: String {
        switch kind {
        case .claude: "Claude"
        case .openAICompatible: preset?.name ?? "OpenAI uyumlu"
        }
    }

    var modelName: String {
        AnthropicBackend.models.first { $0.id == model }?.name ?? model
    }

    func backend(apiKey: String?) throws -> any ChatBackend {
        switch kind {
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
