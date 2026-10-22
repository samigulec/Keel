import Foundation
import KeelCore
import Observation

struct ChatItem: Identifiable {
    enum Kind {
        case user
        case assistant
        case tool(name: String)
        case proposal(CleanupProposal)
        case notice(isError: Bool)
    }

    let id = UUID()
    var kind: Kind
    var text = ""
    var toolCallID: String?
    var isFinished = false
    var isFailed = false
}

/// The Keel AI conversation: connection, messages and the engine behind them.
@MainActor
@Observable
final class AssistantModel {
    private(set) var connection: AIConnection?
    private(set) var items: [ChatItem] = []
    private(set) var isRunning = false
    /// Proposals the user applied, with what was freed.
    private(set) var appliedProposals: [UUID: Int64] = [:]
    var draft = ""

    static let suggestions = [
        "Bilgisayarım neden yavaş?",
        "Neleri güvenle silebilirim?",
        "Pilimin durumu nasıl?",
        "Arka planda neler çalışıyor?",
    ]

    private let status: SystemStatus
    private let cleanup: CleanupModel
    private let performance: PerformanceModel
    @ObservationIgnored private var session: (any ChatSession)?
    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var chatID = UUID()

    init(status: SystemStatus, cleanup: CleanupModel, performance: PerformanceModel) {
        self.status = status
        self.cleanup = cleanup
        self.performance = performance
        let saved = AIConnection.load()
        // A saved connection whose key has gone (e.g. removed in Keychain Access) is not usable.
        if let saved, !saved.needsKey || KeychainStore.read(account: saved.keychainAccount) != nil,
           saved.kind != .apple || AppleIntelligence.isAvailable {
            connection = saved
        } else if saved == nil, AppleIntelligence.isAvailable {
            // Nothing to set up: start with the free on-device model.
            connection = .apple
        }
    }

    // MARK: Connection

    func connect(_ connection: AIConnection, apiKey: String?) throws {
        if let apiKey, !apiKey.isEmpty {
            try KeychainStore.save(apiKey, account: connection.keychainAccount)
        }
        connection.save()
        self.connection = connection
        startNewChat()
    }

    func disconnect() {
        if let connection {
            KeychainStore.delete(account: connection.keychainAccount)
        }
        AIConnection.clear()
        connection = nil
        startNewChat()
    }

    func startNewChat() {
        runTask?.cancel()
        chatID = UUID()
        session = nil
        items = []
        appliedProposals = [:]
        isRunning = false
    }

    // MARK: Conversation

    func send(_ text: String? = nil) {
        let message = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isRunning, connection != nil else { return }
        if text == nil { draft = "" }

        items.append(ChatItem(kind: .user, text: message))
        isRunning = true
        let chat = chatID
        runTask = Task {
            do {
                let session = try currentSession()
                try await session.send(message) { [weak self] event in
                    guard let self, self.chatID == chat else { return }
                    self.handle(event)
                }
            } catch {
                // A new chat was started meanwhile; this answer belongs to the old one.
                guard chatID == chat else { return }
                // Cancelling can surface as URLError.cancelled rather than CancellationError.
                if Task.isCancelled {
                    items.append(ChatItem(kind: .notice(isError: false), text: "Durduruldu. Bu mesaj sohbet geçmişine eklenmedi."))
                } else {
                    items.append(ChatItem(kind: .notice(isError: true), text: Self.describe(error, connection: connection)))
                }
            }
            guard chatID == chat else { return }
            finishOpenItems()
            isRunning = false
        }
    }

    func stop() {
        runTask?.cancel()
    }

    private func currentSession() throws -> any ChatSession {
        if let session { return session }
        guard let connection else { throw AIError.invalidResponse("Bağlantı yok") }
        let chat = chatID
        let isOnDevice = connection.kind == .apple
        let tools = KeelTools.make(status: status, cleanup: cleanup, performance: performance, compact: isOnDevice) { [weak self] proposal in
            guard let self, self.chatID == chat else { return }
            self.items.append(ChatItem(kind: .proposal(proposal)))
        }

        let session: any ChatSession
        if isOnDevice {
            guard let apple = AppleIntelligence.makeSession(
                tools: tools,
                instructions: Self.systemPrompt + Self.onDeviceAddendum,
                onToolEvent: { [weak self] event in
                    guard let self, self.chatID == chat else { return }
                    self.handle(event)
                }
            ) else {
                throw AIError.invalidResponse("Apple Intelligence şu an kullanılamıyor.")
            }
            session = apple
        } else {
            let key = connection.needsKey ? KeychainStore.read(account: connection.keychainAccount) : nil
            session = AssistantEngine(
                backend: try connection.backend(apiKey: key),
                transport: URLSessionTransport(),
                systemPrompt: Self.systemPrompt,
                tools: tools
            )
        }
        self.session = session
        return session
    }

    private func handle(_ event: AssistantEvent) {
        switch event {
        case .textDelta(let text):
            if let index = items.indices.last, case .assistant = items[index].kind, !items[index].isFinished {
                items[index].text += text
            } else {
                items.append(ChatItem(kind: .assistant, text: text))
            }

        case .toolStarted(let id, let name):
            finishOpenAssistantText()
            items.append(ChatItem(kind: .tool(name: name), toolCallID: id))

        case .toolFinished(let id, _, let isError):
            if let index = items.lastIndex(where: { $0.toolCallID == id }) {
                items[index].isFinished = true
                items[index].isFailed = isError
            }

        case .stopped(let reason):
            switch reason {
            case .refusal:
                items.append(ChatItem(kind: .notice(isError: true), text: "Model bu isteği yanıtlamayı reddetti. Soruyu farklı ifade etmeyi deneyebilirsin."))
            case .maxTokens:
                items.append(ChatItem(kind: .notice(isError: false), text: "Yanıt uzunluk sınırına ulaştı ve kesildi."))
            case .other("step_limit"):
                items.append(ChatItem(kind: .notice(isError: false), text: "Çok fazla adım sürdü; burada durdum. Devam etmemi istersen yaz."))
            case .endTurn, .toolUse, .other:
                break
            }
        }
    }

    private func finishOpenAssistantText() {
        if let index = items.indices.last, case .assistant = items[index].kind {
            items[index].isFinished = true
        }
    }

    private func finishOpenItems() {
        for index in items.indices where !items[index].isFinished {
            switch items[index].kind {
            case .assistant, .tool: items[index].isFinished = true
            default: break
            }
        }
    }

    // MARK: Proposals

    /// Selects exactly the proposal's categories, ready for the user's confirmation.
    func prepare(_ proposal: CleanupProposal) -> Bool {
        guard cleanup.phase == .ready else { return false }
        cleanup.selection = Set(proposal.categories)
        return cleanup.selectedBytes > 0
    }

    func apply(_ proposal: CleanupProposal) async {
        guard let report = await cleanup.cleanSelectionAndWait() else { return }
        appliedProposals[proposal.id] = report.freedBytes
    }

    var cleanupConfirmationBytes: Int64 { cleanup.selectedBytes }
    var cleanupPermanentBytes: Int64 { cleanup.selectedPermanentBytes }

    // MARK: Text

    static let systemPrompt = """
    You are Keel AI, the assistant inside Keel, a maintenance app for macOS. You help the user understand and improve their Mac: speed, memory, storage, battery, background services and cleanup.

    How to work:
    - Look before you answer. Use the tools to read the Mac's real state instead of guessing, and quote the numbers you found.
    - You cannot delete, quit or change anything yourself. To suggest a cleanup, call propose_cleanup; the user sees a card and decides. Never say something was cleaned unless the user applied it.
    - Be honest about macOS: free RAM is used as cache, so high memory use alone is not a problem; memory pressure is what matters. Do not recommend RAM cleaners, removing language files from apps, or disabling system services.
    - Write for someone who is not an expert. Keep answers short, and use short bullet lists for steps.
    - Answer in the language the user writes in.
    - Privacy: you only receive the summaries Keel's tools return (sizes, app and folder names, readings). You never see file contents.
    """

    /// The on-device model has a small context window; ask for short answers.
    static let onDeviceAddendum = """

    Keep every answer under 120 words. Call at most two tools per question.
    """

    static func describe(_ error: any Error, connection: AIConnection?) -> String {
        if let message = AppleIntelligence.describe(error) {
            return message
        }
        if let error = error as? AIError {
            switch error {
            case .http(let status, _) where status == 401 || status == 403:
                return "API anahtarı geçersiz ya da yetkisiz. Sağdaki Bağlantı kartından anahtarı kontrol et."
            case .http(429, _):
                return "Hız sınırına takıldı. Biraz bekleyip tekrar dene."
            case .http(529, _), .stream("overloaded_error", _):
                return "Servis şu an çok yoğun. Birkaç saniye sonra tekrar dene."
            case .http(404, let message):
                return "Model ya da adres bulunamadı (\(message)). Model adını kontrol et."
            case .http(let status, let message):
                return "Sağlayıcı hata döndürdü (\(status)): \(message)"
            case .stream(_, let message), .invalidResponse(let message):
                return message
            case .unsupportedPlatform:
                return "Bu platformda desteklenmiyor."
            }
        }
        if let urlError = error as? URLError {
            if connection?.kind == .openAICompatible, connection?.baseURL?.contains("localhost") == true {
                return "Yerel sunucuya bağlanılamadı. Ollama ya da LM Studio çalışıyor mu?"
            }
            return "Bağlantı kurulamadı: \(urlError.localizedDescription)"
        }
        return error.localizedDescription
    }
}
