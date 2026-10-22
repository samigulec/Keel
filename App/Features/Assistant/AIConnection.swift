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

    /// The model id that means "whatever the account uses by default". Keel
    /// only falls back to it when its own default is not open to the account.
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

    /// Keel starts each provider on its best model.
    static func defaultModel(for kind: Kind) -> String {
        switch kind {
        case .claudeCode: "claude-opus-5-5"
        case .chatGPT: "gpt-6.1-sol"
        case .apple: "on-device"
        }
    }

    var kind: Kind
    var model: String
    /// nil keeps the provider's default.
    var effort: String?

    init(kind: Kind, model: String? = nil, effort: String? = nil) {
        self.kind = kind
        self.model = model ?? Self.defaultModel(for: kind)
        self.effort = effort
    }

    static let apple = AIConnection(kind: .apple)

    var supportsEffort: Bool { kind != .apple }

    /// Runs on this Mac: nothing is sent to a server.
    var isLocal: Bool { kind == .apple }

    var usesAccountDefault: Bool { model == Self.accountDefault }

    /// Models the picker offers for this provider, as (id, name).
    var modelChoices: [(id: String, name: String)] {
        switch kind {
        case .apple: [("on-device", "Cihazdaki model")]
        case .claudeCode: Self.claudeModelIDs.map { ($0, ModelNames.display($0)) }
        case .chatGPT: Self.chatGPTModelIDs.map { ($0, ModelNames.display($0)) }
        }
    }

    /// "Hesabın varsayılanı (Opus 4.6)", for when Keel fell back to it.
    static func accountDefaultName(for kind: Kind) -> String {
        let learned = learnedDefault(for: kind).map { " (\(ModelNames.display($0)))" } ?? ""
        return "Hesabın varsayılanı" + learned
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
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              var saved = try? JSONDecoder().decode(AIConnection.self, from: data) else { return nil }
        // Earlier versions started on the account's default model; move once
        // to Keel's default. A later fallback to the account default stays.
        let migrated = "keel.ai.startsOnKeelDefault"
        if !UserDefaults.standard.bool(forKey: migrated) {
            UserDefaults.standard.set(true, forKey: migrated)
            if saved.usesAccountDefault {
                saved.model = defaultModel(for: saved.kind)
                saved.save()
            }
        }
        return saved
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
