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

/// What the user is looking at in Keel, so Keel AI knows what "this" means.
struct ScreenContext: Equatable {
    let section: AppSection
    /// e.g. "Seçili uygulama: Zoom, 1,2 GB, 214 gün önce kullanıldı"
    var detail: String?

    /// Sent before the user's message; the chat shows only the message.
    var note: String {
        var text = "The user is on Keel's \(section.title) screen."
        if let detail { text += " " + detail }
        return "<keel_screen>\(text)</keel_screen>"
    }
}

/// Running totals for the line under the chat box.
struct ChatStats: Equatable {
    var model: String?
    var costUSD: Double?
    var turns = 0
    var contextTokens: Int?
    var contextWindow: Int?

    var contextFraction: Double? {
        guard let contextTokens, let contextWindow, contextWindow > 0 else { return nil }
        return min(Double(contextTokens) / Double(contextWindow), 1)
    }
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
    /// Where each applied suggestion's items went, so the card can undo it.
    private(set) var undoableProposals: [UUID: [TrashedItem]] = [:]
    private(set) var undoneProposals: Set<UUID> = []
    private(set) var stats = ChatStats()
    var draft = ""
    /// The screen the user is on when they write from the companion panel;
    /// nil on the Keel AI tab itself.
    @ObservationIgnored var screen: ScreenContext?

    static let suggestions = [
        "Bilgisayarım neden yavaş?",
        "Neleri güvenle silebilirim?",
        "Pilimin durumu nasıl?",
        "Arka planda neler çalışıyor?",
    ]

    private let status: SystemStatus
    private let cleanup: CleanupModel
    private let performance: PerformanceModel
    private let applications: ApplicationsModel
    @ObservationIgnored private var session: (any ChatSession)?
    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var chatID = UUID()

    init(status: SystemStatus, cleanup: CleanupModel, performance: PerformanceModel, applications: ApplicationsModel) {
        self.status = status
        self.cleanup = cleanup
        self.performance = performance
        self.applications = applications
        if let saved = AIConnection.load(), saved.kind != .apple || AppleIntelligence.isAvailable {
            connection = saved
        } else if AppleIntelligence.isAvailable {
            // Nothing to set up: start with the free on-device model.
            connection = .apple
        }
    }

    // MARK: Connection

    /// Sign-in state of ChatGPT and Claude.
    let accounts = Accounts()

    /// The providers in the order the panel shows them.
    static let providers: [AIConnection.Kind] = [.chatGPT, .claudeCode, .apple]

    /// Switches provider. A conversation cannot move between providers, so
    /// this starts a new chat.
    func use(_ kind: AIConnection.Kind) {
        guard connection?.kind != kind else { return }
        // Each provider starts on Keel's default model; if the account lacks
        // it, the session falls back to the account's default and says so.
        let next = AIConnection(kind: kind)
        next.save()
        connection = next
        startNewChat()
    }

    func startNewChat() {
        runTask?.cancel()
        chatID = UUID()
        session = nil
        items = []
        appliedProposals = [:]
        stats = ChatStats()
        isRunning = false
    }

    /// Picks another model or effort. Within the same provider the
    /// conversation carries on and the next message uses the new setting.
    func update(kind: AIConnection.Kind? = nil, model: String? = nil, effort: String?? = nil) {
        if let kind, kind != connection?.kind { use(kind) }
        guard var connection else { return }
        if let model { connection.model = model }
        if let effort { connection.effort = effort }
        connection.save()
        self.connection = connection
        stats.model = nil

        if let account = session as? AccountSession {
            account.model = connection.usesAccountDefault ? nil : connection.model
            account.effort = connection.effort
        }
    }

    // MARK: Conversation

    func send(_ text: String? = nil) {
        let message = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isRunning, connection != nil else { return }
        if text == nil { draft = "" }

        items.append(ChatItem(kind: .user, text: message))
        isRunning = true
        let chat = chatID
        let prompt = screen.map { "\($0.note)\n\n\(message)" } ?? message
        runTask = Task {
            do {
                let session = try await currentSession()
                try await session.send(prompt) { [weak self] event in
                    guard let self, self.chatID == chat else { return }
                    self.handle(event)
                }
                if chatID == chat { stats.turns += 1 }
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

    private func currentSession() async throws -> any ChatSession {
        if let session { return session }
        guard let connection else { throw AIError.invalidResponse("Bağlantı yok") }
        let chat = chatID
        let isOnDevice = connection.kind == .apple
        let tools = KeelTools.make(
            status: status, cleanup: cleanup, performance: performance, applications: applications, compact: isOnDevice
        ) { [weak self] proposal in
            guard let self, self.chatID == chat else { return }
            self.items.append(ChatItem(kind: .proposal(proposal)))
        }

        let session: any ChatSession
        if connection.kind == .apple {
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
            let proposeTool = tools.first { $0.definition.name == "propose_cleanup" }
            session = AccountSession(
                kind: connection.kind,
                model: connection.usesAccountDefault ? nil : connection.model,
                effort: connection.effort,
                gatherContext: { [status, cleanup, performance, applications] report in
                    await KeelContext.gather(
                        status: status, cleanup: cleanup, performance: performance, applications: applications, report: report
                    )
                },
                propose: { input in
                    _ = try? await proposeTool?.run(input)
                },
                fellBack: { [weak self] model, notice in
                    guard let self, self.chatID == chat, var current = self.connection else { return }
                    current.model = model ?? AIConnection.accountDefault
                    current.save()
                    self.connection = current
                    self.items.append(ChatItem(kind: .notice(isError: false), text: notice))
                }
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

        case .usage(let usage):
            if let model = usage.model {
                stats.model = model
                if let connection, connection.kind != .apple, connection.usesAccountDefault {
                    AIConnection.setLearnedDefault(model, for: connection.kind)
                }
            }
            if let cost = usage.costUSD {
                // Claude Code reports the session's running total; the API reports each response.
                stats.costUSD = connection?.kind == .claudeCode ? cost : (stats.costUSD ?? 0) + cost
            }
            if let context = usage.contextTokens { stats.contextTokens = context }
            if let window = usage.contextWindow { stats.contextWindow = window }

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

    /// The items the user is about to confirm, from a suggestion card.
    private(set) var pendingCleanup: (proposal: CleanupProposal, items: [CleanupItem])?

    func review(_ proposal: CleanupProposal, items: [CleanupItem]) {
        guard !items.isEmpty, cleanup.phase == .ready else { return }
        pendingCleanup = (proposal, items)
    }

    /// Puts a suggestion's cleaned items back from the Trash.
    func undoProposal(_ id: UUID) {
        guard let trashed = undoableProposals.removeValue(forKey: id) else { return }
        Task {
            let report = await Undo.restore(trashed)
            undoneProposals.insert(id)
            items.append(ChatItem(kind: .notice(isError: !report.failed.isEmpty), text: Undo.summary(report)))
            cleanup.scan()
        }
    }

    func cancelPendingCleanup() {
        pendingCleanup = nil
    }

    /// Starts the confirmed cleanup. The items are taken right away, because
    /// the dialog clears what is pending as it closes.
    func confirmPendingCleanup() {
        guard let pending = pendingCleanup else { return }
        pendingCleanup = nil
        let chat = chatID
        Task {
            let report = await cleanup.cleanAndWait(items: pending.items)
            guard chatID == chat else { return }
            describeCleanup(of: pending.proposal, report)
        }
    }

    /// Says in the chat what the cleanup did, including what it left alone and why.
    private func describeCleanup(of proposal: CleanupProposal, _ report: CleanupReport?) {
        guard let report else {
            items.append(ChatItem(
                kind: .notice(isError: true),
                text: "Temizlik başlamadı: başka bir tarama ya da temizlik sürüyor, veya bu öğeler son taramada artık yok. Biraz sonra tekrar dene."
            ))
            return
        }
        appliedProposals[proposal.id] = report.freedBytes
        if !report.trashed.isEmpty { undoableProposals[proposal.id] = report.trashed }

        var lines: [String] = []
        for skipped in report.skipped {
            let name = skipped.url.lastPathComponent
            switch skipped.reason {
            case .appRunning(let bundleID):
                let app = cleanup.runningAppNames[bundleID] ?? bundleID
                lines.append("\(name): \(app) açık olduğu için atlandı. Uygulamayı kapatıp tekrar dene.")
            case .denied(let reason):
                lines.append("\(name): güvenlik kuralı izin vermedi (\(reason)).")
            case .permanentDeletionNotAllowed:
                lines.append("\(name): kalıcı silmeye izin verilmeyen bir yerde.")
            }
        }
        for failure in report.failed {
            lines.append("\(failure.item.url.lastPathComponent): \(failure.message)")
        }
        if !lines.isEmpty {
            items.append(ChatItem(kind: .notice(isError: report.removed.isEmpty), text: lines.joined(separator: "\n")))
        }
    }

    var pendingBytes: Int64 { pendingCleanup?.items.reduce(0) { $0 + $1.sizeBytes } ?? 0 }

    var pendingPermanentBytes: Int64 {
        pendingCleanup?.items.filter { $0.removal == .deletePermanently }.reduce(0) { $0 + $1.sizeBytes } ?? 0
    }

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
    - A message may start with <keel_screen>: the Keel screen the user is on and what they selected there. Use it to understand what "this" or "bu" refers to; do not repeat the tag.
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
            case .stream(_, let message), .invalidResponse(let message), .http(_, let message):
                return message
            case .unsupportedPlatform:
                return "Bu platformda desteklenmiyor."
            }
        }
        return error.localizedDescription
    }
}
