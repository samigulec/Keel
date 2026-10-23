import Foundation
import KeelCore

/// Keel AI through the user's own account, by running the provider's command
/// line tool with no tools of its own: Claude Code for Claude, Codex for
/// ChatGPT. Keel gathers the Mac's state for every message and the model
/// answers from that; cleanups come back as a block Keel turns into a card
/// the user must confirm.
@MainActor
final class AccountSession: ChatSession {
    struct Failure: LocalizedError {
        let message: String
        /// The model that was answering, when the tool said which.
        var model: String?
        var errorDescription: String? { message }
    }

    let kind: AIConnection.Kind
    /// nil uses the account's default model.
    var model: String?
    var effort: String?
    private let gatherContext: @MainActor ((AssistantEvent) -> Void) async -> JSONValue
    private let propose: @MainActor (JSONValue) async -> Void
    /// Called when Keel moved to another model to get an answer: the new
    /// model (nil for the account's default) and a line for the user.
    private let fellBack: @MainActor (_ model: String?, _ notice: String) -> Void
    private var conversationID: String?

    init(
        kind: AIConnection.Kind,
        model: String?,
        effort: String?,
        gatherContext: @escaping @MainActor ((AssistantEvent) -> Void) async -> JSONValue,
        propose: @escaping @MainActor (JSONValue) async -> Void,
        fellBack: @escaping @MainActor (_ model: String?, _ notice: String) -> Void
    ) {
        precondition(kind != .apple, "Apple Intelligence runs in-process")
        self.kind = kind
        self.model = model
        self.effort = effort
        self.gatherContext = gatherContext
        self.propose = propose
        self.fellBack = fellBack
    }

    private var tool: CLITool { kind == .claudeCode ? .claude : .codex }
    /// The install that ran the last message, to name it in errors.
    private var lastExecutablePath: String?
    private var providerName: String { kind == .claudeCode ? "Claude" : "ChatGPT" }

    func send(_ text: String, onEvent: (AssistantEvent) -> Void) async throws {
        guard let executable = await tool.locate() else {
            throw Failure(message: "\(tool.command) bulunamadı. Sağdaki \(providerName) kartından kurulumu kontrol et.")
        }

        lastExecutablePath = executable.path
        let context = await gatherContext(onEvent)
        try Task.checkCancellation()

        let prompt = """
        <keel_context>
        \(context.encodedString())
        </keel_context>

        \(text)
        """

        do {
            try await run(prompt, onEvent: onEvent)
        } catch let failure as Failure where model != nil && CLIErrorText.isModelUnavailable(failure.message) {
            // The account cannot use the chosen model; its default can answer instead.
            let unavailable = model!
            model = nil
            fellBack(nil, "\(ModelNames.display(unavailable)) hesabında açık değil; hesabının varsayılan modeliyle devam ediyorum.")
            try await run(prompt, onEvent: onEvent)
        } catch let failure as Failure where CLIErrorText.isUsageLimit(failure.message)
            && failure.model.flatMap(CLIErrorText.longContextBase(of:)) != nil {
            // Plans often limit the 1M-context variant on its own; the standard one may still answer.
            let longContext = failure.model!
            let standard = CLIErrorText.longContextBase(of: longContext)!
            model = standard
            fellBack(standard, "\(ModelNames.display(longContext)) sınıra takıldı; standart \(ModelNames.display(standard)) ile deniyorum.")
            try await run(prompt, onEvent: onEvent)
        }
    }

    // MARK: Running the tool

    private func run(_ prompt: String, onEvent: (AssistantEvent) -> Void) async throws {
        var filter = ProposalStreamFilter()
        switch kind {
        case .claudeCode: try await runClaude(prompt, filter: &filter, onEvent: onEvent)
        case .chatGPT: try await runCodex(prompt, filter: &filter, onEvent: onEvent)
        case .apple: return
        }
        try Task.checkCancellation()

        let end = filter.finish()
        if !end.visible.isEmpty { onEvent(.textDelta(end.visible)) }
        for proposal in end.proposals {
            await propose(proposal)
        }
        onEvent(.stopped(.endTurn))
    }

    /// Shows a chunk of the answer, minus any cleanup block.
    private static func emit(_ chunk: String, filter: inout ProposalStreamFilter, onEvent: (AssistantEvent) -> Void) {
        let visible = filter.feed(chunk)
        if !visible.isEmpty { onEvent(.textDelta(visible)) }
    }

    private func runClaude(_ prompt: String, filter: inout ProposalStreamFilter, onEvent: (AssistantEvent) -> Void) async throws {
        // A new conversation gets a fresh id; later messages resume it.
        let newID = conversationID == nil ? UUID().uuidString.lowercased() : nil
        var arguments = [
            "-p", prompt,
            "--output-format", "stream-json", "--verbose", "--include-partial-messages",
            "--tools", "",
            "--strict-mcp-config",
            "--system-prompt", KeelContext.instructions,
        ]
        if let model { arguments += ["--model", model] }
        if let effort { arguments += ["--effort", effort] }
        if let conversationID {
            arguments += ["--resume", conversationID]
        } else if let newID {
            arguments += ["--session-id", newID]
        }

        var parser = ClaudeCodeStreamParser()
        var outcome: (isError: Bool, message: String)?
        var answering: String?
        do {
            for try await line in try await tool.stream(arguments) {
                for event in parser.consume(line) {
                    switch event {
                    case .text(let chunk): Self.emit(chunk, filter: &filter, onEvent: onEvent)
                    case .started(let model):
                        answering = model
                        onEvent(.usage(TurnUsage(model: model)))
                    case .usage(let usage): onEvent(.usage(usage))
                    case .retry: break
                    case .result(let id, let isError, let message):
                        outcome = (isError, message)
                        if !isError, let id { conversationID = id }
                    }
                }
            }
        } catch let failure as ProcessFailure {
            // Claude Code reports most errors in its result line, then exits with 1.
            if let outcome, outcome.isError {
                throw Failure(message: describe(outcome.message), model: answering)
            }
            throw Failure(message: describe(failure), model: answering)
        }
        if let outcome, outcome.isError {
            throw Failure(message: describe(outcome.message), model: answering)
        }
        if conversationID == nil, let newID, outcome != nil { conversationID = newID }
    }

    private func runCodex(_ prompt: String, filter: inout ProposalStreamFilter, onEvent: (AssistantEvent) -> Void) async throws {
        var arguments = [
            "exec", "--json",
            "--skip-git-repo-check",
            "--ignore-user-config", "--ignore-rules",
            "--sandbox", "read-only",
            // Keel AI only reads the context Keel sends; Codex gets no tools.
            "-c", "features.shell_tool=false",
            "-c", "features.unified_exec=false",
            "-c", "features.view_image=false",
            "-c", "web_search=\"disabled\"",
            "-c", "developer_instructions=\(Self.tomlString(KeelContext.instructions))",
        ]
        if let model { arguments += ["--model", model] }
        if let effort { arguments += ["-c", "model_reasoning_effort=\"\(effort)\""] }
        if let conversationID { arguments += ["resume", conversationID] }
        arguments.append(prompt)

        var parser = CodexStreamParser()
        var thread: String?
        var failed: String?
        var answered = false
        do {
            for try await line in try await tool.stream(arguments) {
                for event in parser.consume(line) {
                    switch event {
                    case .started(let threadID): thread = threadID
                    case .text(let text):
                        // Separate answers that arrive as several messages.
                        Self.emit(answered ? "\n\n" + text : text, filter: &filter, onEvent: onEvent)
                        answered = true
                    case .usage(var usage):
                        usage.model = model
                        onEvent(.usage(usage))
                    case .failed(let message): failed = message
                    }
                }
            }
        } catch let failure as ProcessFailure {
            if let message = failed ?? parser.lastError {
                throw Failure(message: describe(message))
            }
            throw Failure(message: describe(failure))
        }
        if let failed {
            throw Failure(message: describe(failed))
        }
        // Only a thread that answered is resumed; a failed one starts over.
        if let thread { conversationID = thread }
    }

    // MARK: Errors

    private func describe(_ failure: ProcessFailure) -> String {
        let detail = failure.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        if detail.isEmpty {
            return "\(tool.command) beklenmedik şekilde kapandı (çıkış kodu \(failure.status)). Sağdaki \(providerName) kartından girişi kontrol et."
        }
        return describe(detail)
    }

    private func describe(_ message: String) -> String {
        let detail = String(message.trimmingCharacters(in: .whitespacesAndNewlines).prefix(400))
        let lowered = detail.lowercased()
        if lowered.contains("version_too_old") || (lowered.contains("update") && lowered.contains("version")) {
            // Look for a newer install next time, e.g. after `claude update`.
            tool.forgetLocation()
            let path = lastExecutablePath.map { " Keel'in kullandığı: \($0)." } ?? ""
            return "\(tool.command) çok eski ve bu modeli desteklemiyor.\(path) Terminal'de `\(tool.command) update` çalıştırıp tekrar dene; Keel bir sonraki mesajda en yeni kurulumu yeniden arar."
        }
        if CLIErrorText.isModelUnavailable(detail) {
            return "Bu model hesabında açık değil: \(detail)"
        }
        if CLIErrorText.isUsageLimit(detail) {
            let other = kind == .claudeCode ? "ChatGPT" : "Claude"
            return "\(providerName) planının kullanım sınırına ulaşıldı (\(detail)). Sınır birkaç saat içinde yenilenir; bu arada \(other) ya da Apple Intelligence'a geçebilirsin."
        }
        if CLIErrorText.needsLogin(detail) {
            return "\(providerName) hesabına yeniden giriş gerekiyor. Sağdaki \(providerName) kartından \"Giriş yap\"a bas.\n\(detail)"
        }
        return "\(providerName) yanıt veremedi: \(detail)"
    }

    /// A TOML basic string, for passing text through `codex -c key=value`.
    static func tomlString(_ text: String) -> String {
        var result = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default:
                if scalar.value < 0x20 || scalar.value == 0x7F {
                    result += String(format: "\\u%04X", scalar.value)
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }
        return result + "\""
    }
}

/// Collects the Mac's current state for providers that cannot call Keel's tools.
@MainActor
enum KeelContext {
    static func gather(
        status: SystemStatus,
        cleanup: CleanupModel,
        performance: PerformanceModel,
        applications: ApplicationsModel,
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
        let apps = await step("get_installed_apps") {
            KeelTools.installedApps(await applications.listWhenReady(), compact: true)
        }

        return [
            "system": system,
            "cleanable_space": cleanable,
            "top_memory_apps": apps,
            "background_services": KeelTools.backgroundServices(performance, compact: true),
            "installed_apps": apps,
        ]
    }

    /// Instructions for account providers, which see Keel's readings in each
    /// message instead of calling tools.
    static let instructions = """
    You are Keel AI, the assistant inside Keel, a maintenance app for macOS. You help the user understand and improve their Mac: speed, memory, storage, battery, background services and cleanup.

    Every user message starts with <keel_context>: fresh readings Keel took from this Mac just now (system status, cleanable space by category with item paths, apps using the most memory, background services, installed apps with sizes and last use). Answer from that data and quote the numbers; do not guess beyond it. You have no tools and cannot run commands or read files; never try to.

    To suggest a cleanup, end your answer with exactly one block in this form, and nothing after it:
    ```keel-cleanup
    {"items": ["~/Library/Caches/Firefox/Profiles"], "categories": [], "reason": "One sentence on why this helps."}
    ```
    When the user names specific things, list them in "items" using the exact paths from the context. For whole categories use "categories" with ids from the context that have items. Either list may be empty. Prefer the preselected ones; include "trash" (deleted permanently) or "oldDownloads" (personal files) only when the user clearly wants that. Keel shows the block as a card and nothing is removed unless the user confirms, so never say something was cleaned.

    You cannot remove apps. When the user wants to, point them to Keel's Uygulamalar section, which moves an app and its leftover files to the Trash.

    Be honest about macOS: free RAM is used as cache, so high memory use alone is not a problem; memory pressure is what matters. Do not recommend RAM cleaners, removing language files from apps, or disabling system services.

    Write for someone who is not an expert. Keep answers short, use short bullet lists for steps, and answer in the language the user writes in.
    """
}
