import Foundation
import KeelCore

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device model: free, private and with nothing to set up, on
/// Macs where Apple Intelligence is turned on (macOS 26 and later).
enum AppleIntelligence {
    enum Status: Equatable {
        case available
        /// Why it cannot be used, in words for the user.
        case unavailable(String)
    }

    @MainActor
    static var status: Status {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable("Bu Mac Apple Intelligence'ı desteklemiyor.")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("Sistem Ayarları > Apple Intelligence ve Siri'den Apple Intelligence'ı aç.")
            case .unavailable(.modelNotReady):
                return .unavailable("Apple Intelligence modeli hazırlanıyor; biraz sonra tekrar dene.")
            case .unavailable:
                return .unavailable("Apple Intelligence şu an kullanılamıyor.")
            }
        }
        #endif
        return .unavailable("Apple Intelligence macOS 26 ve sonrasında, Apple Silicon Mac'lerde çalışır.")
    }

    @MainActor
    static var isAvailable: Bool { status == .available }

    /// User-facing text for the on-device model's errors; nil for other errors.
    static func describe(_ error: any Error) -> String? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                return "Sohbet cihazdaki model için çok uzadı. Sağdan \"Yeni sohbet\" başlat."
            case .unsupportedLanguageOrLocale:
                return "Apple Intelligence bu dili henüz desteklemiyor. İngilizce sormayı ya da Claude bağlamayı dene."
            case .guardrailViolation, .refusal:
                return "Apple Intelligence bu isteği yanıtlamadı. Soruyu farklı ifade etmeyi dene."
            case .assetsUnavailable:
                return "Apple Intelligence modeli şu an hazır değil; biraz sonra tekrar dene."
            case .rateLimited:
                return "Çok sık istek gönderildi; birkaç saniye bekleyip tekrar dene."
            default:
                return error.localizedDescription
            }
        }
        #endif
        return nil
    }

    @MainActor
    static func makeSession(
        tools: [AITool],
        instructions: String,
        onToolEvent: @escaping @MainActor (AssistantEvent) -> Void
    ) -> (any ChatSession)? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), isAvailable {
            return AppleIntelligenceSession(tools: tools, instructions: instructions, onToolEvent: onToolEvent)
        }
        #endif
        return nil
    }
}

/// Runs Keel's tools for the on-device model and reports them to the chat.
@MainActor
final class AppleToolBridge {
    private let tools: [String: AITool]
    private let onEvent: @MainActor (AssistantEvent) -> Void

    init(tools: [AITool], onEvent: @escaping @MainActor (AssistantEvent) -> Void) {
        self.tools = Dictionary(tools.map { ($0.definition.name, $0) }, uniquingKeysWith: { first, _ in first })
        self.onEvent = onEvent
    }

    func run(name: String, input: JSONValue) async throws -> String {
        guard let tool = tools[name] else { return "Unknown tool \(name)" }
        let id = UUID().uuidString
        onEvent(.toolStarted(id: id, name: name))
        do {
            let output = try await tool.run(input)
            onEvent(.toolFinished(id: id, name: name, isError: false))
            return output
        } catch {
            onEvent(.toolFinished(id: id, name: name, isError: true))
            throw error
        }
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
@MainActor
final class AppleIntelligenceSession: ChatSession {
    private let session: LanguageModelSession
    private let bridge: AppleToolBridge

    init(tools: [AITool], instructions: String, onToolEvent: @escaping @MainActor (AssistantEvent) -> Void) {
        let bridge = AppleToolBridge(tools: tools, onEvent: onToolEvent)
        let appleTools: [any Tool] = tools.map { tool -> any Tool in
            if tool.definition.name == "propose_cleanup" {
                return ProposeCleanupTool(description: tool.definition.description, bridge: bridge)
            }
            if tool.definition.name == "propose_action" {
                return ProposeActionTool(description: tool.definition.description, bridge: bridge)
            }
            return NoArgumentTool(name: tool.definition.name, description: tool.definition.description, bridge: bridge)
        }
        self.bridge = bridge
        self.session = LanguageModelSession(tools: appleTools, instructions: instructions)
    }

    func send(_ text: String, onEvent: (AssistantEvent) -> Void) async throws {
        // Snapshots carry the whole answer so far; pass on only what is new.
        var shown = ""
        for try await snapshot in session.streamResponse(to: Prompt(text)) {
            let content = snapshot.content
            if content.hasPrefix(shown), content.count > shown.count {
                onEvent(.textDelta(String(content.dropFirst(shown.count))))
            }
            shown = content
        }
        onEvent(.stopped(.endTurn))
    }
}

@available(macOS 26.0, *)
private struct NoArgumentTool: Tool {
    let name: String
    let description: String
    let bridge: AppleToolBridge

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        try await bridge.run(name: name, input: [:])
    }
}

@available(macOS 26.0, *)
private struct ProposeCleanupTool: Tool {
    let name = "propose_cleanup"
    let description: String
    let bridge: AppleToolBridge

    @Generable
    struct Arguments {
        @Guide(description: "Paths of single items from scan_cleanable_space, when the user names specific things")
        var items: [String]
        @Guide(description: "Whole category ids from scan_cleanable_space, e.g. userCaches, logs, browserCaches")
        var categories: [String]
        @Guide(description: "One sentence on why this helps")
        var reason: String
    }

    func call(arguments: Arguments) async throws -> String {
        try await bridge.run(name: name, input: [
            "items": .array(arguments.items.map(JSONValue.string)),
            "categories": .array(arguments.categories.map(JSONValue.string)),
            "reason": .string(arguments.reason),
        ])
    }
}

@available(macOS 26.0, *)
private struct ProposeActionTool: Tool {
    let name = "propose_action"
    let description: String
    let bridge: AppleToolBridge

    @Generable
    struct Arguments {
        @Guide(description: "What to do", .anyOf(["disable_startup", "enable_startup", "remove_login_items", "quit_apps", "set_fans"]))
        var action: String
        @Guide(description: "Service labels, login item names or app names; empty for set_fans")
        var names: [String]
        @Guide(description: "set_fans only: 0 for automatic, otherwise 50 to 100 percent of each fan's top speed")
        var percent: Int
        @Guide(description: "One sentence on why this helps")
        var reason: String
    }

    func call(arguments: Arguments) async throws -> String {
        var input: [String: JSONValue] = [
            "action": .string(arguments.action),
            "names": .array(arguments.names.map(JSONValue.string)),
            "reason": .string(arguments.reason),
        ]
        if arguments.action == "set_fans" {
            if arguments.percent == 0 {
                input["mode"] = "auto"
            } else {
                input["percent"] = .number(Double(arguments.percent))
            }
        }
        return try await bridge.run(name: name, input: .object(input))
    }
}
#endif
