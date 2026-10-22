import Foundation
import KeelCore

/// Keel AI through the user's own Claude account, by running Claude Code
/// with no tools of its own. Keel gathers the Mac's state for every message
/// and Claude answers from that; cleanups come back as a block Keel turns
/// into a card the user must confirm.
@MainActor
final class ClaudeCodeSession: ChatSession {
    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    var modelAlias: String?
    var effort: String?
    private let gatherContext: @MainActor ((AssistantEvent) -> Void) async -> JSONValue
    private let propose: @MainActor (JSONValue) async -> Void
    private var sessionID: String?

    init(
        modelAlias: String?,
        effort: String?,
        gatherContext: @escaping @MainActor ((AssistantEvent) -> Void) async -> JSONValue,
        propose: @escaping @MainActor (JSONValue) async -> Void
    ) {
        self.modelAlias = modelAlias
        self.effort = effort
        self.gatherContext = gatherContext
        self.propose = propose
    }

    func send(_ text: String, onEvent: (AssistantEvent) -> Void) async throws {
        guard let executable = await ClaudeCodeCLI.locate() else {
            throw Failure(message: "Claude Code bulunamadı. Bağlantı ayarlarından kurulumu kontrol et.")
        }

        let context = await gatherContext(onEvent)
        try Task.checkCancellation()

        let prompt = """
        <keel_context>
        \(context.encodedString())
        </keel_context>

        \(text)
        """

        // A new conversation gets a fresh id; later messages resume it.
        let newID = sessionID == nil ? UUID().uuidString.lowercased() : nil
        var arguments = [
            "-p", prompt,
            "--output-format", "stream-json", "--verbose", "--include-partial-messages",
            "--tools", "",
            "--strict-mcp-config",
            "--system-prompt", Self.systemPrompt,
        ]
        if let modelAlias { arguments += ["--model", modelAlias] }
        if let effort { arguments += ["--effort", effort] }
        if let sessionID {
            arguments += ["--resume", sessionID]
        } else if let newID {
            arguments += ["--session-id", newID]
        }

        var parser = ClaudeCodeStreamParser()
        var filter = ProposalStreamFilter()
        var outcome: (isError: Bool, message: String)?
        do {
            let lines = try ProcessLines.stream(
                executable,
                arguments: arguments,
                environment: ClaudeCodeCLI.environment,
                currentDirectory: ClaudeCodeCLI.workingDirectory
            )
            for try await line in lines {
                for event in parser.consume(line) {
                    switch event {
                    case .text(let chunk):
                        let visible = filter.feed(chunk)
                        if !visible.isEmpty { onEvent(.textDelta(visible)) }
                    case .started(let model):
                        onEvent(.usage(TurnUsage(model: model)))
                    case .usage(let usage):
                        onEvent(.usage(usage))
                    case .retry:
                        break
                    case .result(let id, let isError, let message):
                        outcome = (isError, message)
                        if !isError, let id { sessionID = id }
                    }
                }
            }
        } catch let failure as ProcessFailure {
            throw Failure(message: Self.describe(failure))
        }
        try Task.checkCancellation()

        if let outcome, outcome.isError {
            throw Failure(message: "Claude yanıt veremedi: \(outcome.message)")
        }
        if sessionID == nil, let newID, outcome != nil { sessionID = newID }

        let end = filter.finish()
        if !end.visible.isEmpty { onEvent(.textDelta(end.visible)) }
        for proposal in end.proposals {
            await propose(proposal)
        }
        onEvent(.stopped(.endTurn))
    }

    private static func describe(_ failure: ProcessFailure) -> String {
        let detail = failure.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = detail.lowercased()
        if lowered.contains("login") || lowered.contains("log in") || lowered.contains("auth") {
            return "Claude hesabına giriş gerekiyor. Bağlantı ayarlarından \"Giriş yap\"a bas."
        }
        if lowered.contains("limit") {
            return "Claude kullanım sınırına ulaşıldı: \(detail.prefix(200))"
        }
        return detail.isEmpty ? "Claude Code beklenmedik şekilde kapandı (\(failure.status))." : "Claude Code hata verdi: \(detail.prefix(300))"
    }

    static let systemPrompt = """
    You are Keel AI, the assistant inside Keel, a maintenance app for macOS. You help the user understand and improve their Mac: speed, memory, storage, battery, background services and cleanup.

    Every user message starts with <keel_context>: fresh readings Keel took from this Mac just now (system status, cleanable space by category, apps using the most memory, background services). Answer from that data and quote the numbers; do not guess beyond it. You have no tools and cannot run commands.

    To suggest a cleanup, end your answer with exactly one block in this form, and nothing after it:
    ```keel-cleanup
    {"items": ["~/Library/Caches/Firefox/Profiles"], "categories": [], "reason": "One sentence on why this helps."}
    ```
    When the user names specific things, list them in "items" using the exact paths from the context. For whole categories use "categories" with ids from the context that have items. Either list may be empty. Prefer the preselected ones; include "trash" (deleted permanently) or "oldDownloads" (personal files) only when the user clearly wants that. Keel shows the block as a card and nothing is removed unless the user confirms, so never say something was cleaned.

    Be honest about macOS: free RAM is used as cache, so high memory use alone is not a problem; memory pressure is what matters. Do not recommend RAM cleaners, removing language files from apps, or disabling system services.

    Write for someone who is not an expert. Keep answers short, use short bullet lists for steps, and answer in the language the user writes in.
    """
}

/// Collects the Mac's current state for providers that cannot call tools.
@MainActor
enum KeelContext {
    static func gather(
        status: SystemStatus,
        cleanup: CleanupModel,
        performance: PerformanceModel,
        report: (AssistantEvent) -> Void
    ) async -> JSONValue {
        func step(_ name: String, _ work: () async -> JSONValue) async -> JSONValue {
            let id = UUID().uuidString
            report(.toolStarted(id: id, name: name))
            let result = await work()
            report(.toolFinished(id: id, name: name, isError: false))
            return result
        }

        let system = await step("get_system_status") { KeelTools.systemStatus(status) }
        let cleanable = await step("scan_cleanable_space") {
            // A recent scan is reused; scanning on every message would be slow.
            if cleanup.lastScan.map({ Date().timeIntervalSince($0) > 600 }) ?? true {
                await cleanup.scanAndWait()
            }
            return KeelTools.cleanupSummary(cleanup.results, appNames: cleanup.runningAppNames)
        }
        let apps = await step("get_top_memory_apps") {
            await performance.refreshApps()
            return KeelTools.topApps(performance)
        }
        if !performance.launchItemsLoaded {
            await performance.refreshLaunchItems()
        }

        return [
            "system": system,
            "cleanable_space": cleanable,
            "top_memory_apps": apps,
            "background_services": KeelTools.backgroundServices(performance, compact: true),
        ]
    }
}
