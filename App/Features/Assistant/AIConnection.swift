import Foundation
import KeelCore

/// Which AI Keel AI talks to. Every option uses the user's own account or
/// their Mac; Keel holds no keys or credentials.
struct AIConnection: Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        /// The user's ChatGPT account, through the Codex tool they installed.
        case chatGPT
        /// The user's Claude account, through the Claude Code tool they installed.
        case claudeCode
        /// Apple's on-device model: no account, nothing leaves the Mac.
        case apple
    }

    /// The model id that means "whatever the account uses by default".
    static let accountDefault = "default"

    /// How hard the model thinks; more effort is slower and uses more of the plan.
    static let effortLevels: [(id: String, name: String, detail: String)] = [
        ("low", "Düşük", "Hızlı ve kısa"),
        ("medium", "Orta", "Dengeli"),
        ("high", "Yüksek", "Özenli"),
        ("xhigh", "Çok yüksek", "Çok özenli"),
        ("max", "En yüksek", "En derin, en yavaş"),
    ]

    /// Claude models by number, newest first.
    static let claudeModelIDs = [
        "claude-opus-5-5", "claude-sonnet-5-5", "claude-fable-5-1", "claude-haiku-5-5",
        "claude-opus-5", "claude-sonnet-5", "claude-fable-5",
        "claude-opus-4-8", "claude-opus-4-7", "claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5",
    ]

    /// ChatGPT models Codex offers, in Codex's own order.
    static let chatGPTModelIDs = [
        "gpt-6.1-sol", "gpt-6-astra", "gpt-6-sol", "gpt-6-luna",
        "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-5.5",
    ]

    static let recommendedModels: Set<String> = ["claude-opus-5-5", "gpt-6.1-sol"]

    var kind: Kind
    var model: String
    /// nil keeps the provider's default.
    var effort: String?

    init(kind: Kind, model: String = AIConnection.accountDefault, effort: String? = nil) {
        self.kind = kind
        self.model = model
        self.effort = effort
    }

    static let apple = AIConnection(kind: .apple, model: "on-device")

    var supportsEffort: Bool { kind != .apple }

    /// Runs on this Mac: nothing is sent to a server.
    var isLocal: Bool { kind == .apple }

    var usesAccountDefault: Bool { model == Self.accountDefault }

    /// Models the picker offers for this provider, as (id, name).
    var modelChoices: [(id: String, name: String)] {
        let numbered: [String]
        switch kind {
        case .apple: return [("on-device", "Cihazdaki model")]
        case .claudeCode: numbered = Self.claudeModelIDs
        case .chatGPT: numbered = Self.chatGPTModelIDs
        }
        let learned = Self.learnedDefault(for: kind).map { " (\(ModelNames.display($0)))" } ?? ""
        return [(Self.accountDefault, "Hesabın varsayılanı" + learned)]
            + numbered.map { ($0, ModelNames.display($0)) }
    }

    var providerName: String {
        switch kind {
        case .chatGPT: "ChatGPT"
        case .claudeCode: "Claude"
        case .apple: "Apple Intelligence"
        }
    }

    var modelName: String {
        switch kind {
        case .apple: "Cihazdaki model"
        case .claudeCode, .chatGPT:
            if usesAccountDefault {
                Self.learnedDefault(for: kind).map(ModelNames.display) ?? "Hesabın varsayılanı"
            } else {
                ModelNames.display(model)
            }
        }
    }

    /// The model the account answers with when Keel does not pick one,
    /// learned from its answers so the picker can name it.
    static func learnedDefault(for kind: Kind) -> String? {
        UserDefaults.standard.string(forKey: "keel.ai.\(kind.rawValue).accountDefault")
    }

    static func setLearnedDefault(_ model: String, for kind: Kind) {
        UserDefaults.standard.set(model, forKey: "keel.ai.\(kind.rawValue).accountDefault")
    }

    // MARK: Persistence

    private static let defaultsKey = "keel.ai.connection"

    /// The saved choice; one from an older Keel that no longer exists reads as none.
    static func load() -> AIConnection? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(AIConnection.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
