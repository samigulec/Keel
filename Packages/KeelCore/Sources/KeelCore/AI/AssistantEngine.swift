import Foundation

/// A tool the assistant may call. Tools only read; anything that changes the
/// Mac is returned as a proposal the user must confirm in the app.
@MainActor
public struct AITool {
    public let definition: ToolDefinition
    public let run: @MainActor (JSONValue) async throws -> String

    public init(name: String, description: String, inputSchema: JSONValue, run: @escaping @MainActor (JSONValue) async throws -> String) {
        self.definition = ToolDefinition(name: name, description: description, inputSchema: inputSchema)
        self.run = run
    }
}

public enum AssistantEvent: Equatable, Sendable {
    case textDelta(String)
    case toolStarted(id: String, name: String)
    case toolFinished(id: String, name: String, isError: Bool)
    /// Tokens and cost of one model response.
    case usage(TurnUsage)
    /// Why the turn ended, when it is worth telling the user.
    case stopped(StopReason)
}

/// Runs a conversation with one provider: sends the history, streams the
/// answer, runs requested tools and loops until the model is done.
///
/// History is append-only: earlier turns are never edited, because providers
/// such as Claude validate the thinking they returned against it.
@MainActor
public final class AssistantEngine {
    public private(set) var history: [JSONValue] = []

    private var backend: any ChatBackend
    private let transport: any StreamingTransport
    private let systemPrompt: String
    private let tools: [String: AITool]
    private let toolDefinitions: [ToolDefinition]
    /// Upper bound on model calls per user message, so a confused model cannot loop forever.
    private let maxSteps: Int

    public init(
        backend: any ChatBackend,
        transport: any StreamingTransport,
        systemPrompt: String,
        tools: [AITool],
        maxSteps: Int = 12
    ) {
        self.backend = backend
        self.transport = transport
        self.systemPrompt = systemPrompt
        self.tools = Dictionary(tools.map { ($0.definition.name, $0) }, uniquingKeysWith: { first, _ in first })
        // Stable order keeps the cached prompt prefix identical between requests.
        self.toolDefinitions = tools.map(\.definition).sorted { $0.name < $1.name }
        self.maxSteps = maxSteps
    }

    /// Switches model or settings mid-conversation; the history is kept.
    /// Thinking from another model is dropped by the provider, unbilled.
    public func replaceBackend(_ backend: any ChatBackend) {
        self.backend = backend
    }

    /// Sends one user message. On failure the whole exchange is rolled back,
    /// so the history never ends with an unanswered message or tool call.
    public func send(_ text: String, onEvent: (AssistantEvent) -> Void) async throws {
        let checkpoint = history.count
        history.append(backend.userMessage(text))
        do {
            try await runLoop(onEvent: onEvent)
        } catch {
            history.removeSubrange(checkpoint...)
            throw error
        }
    }

    private func runLoop(onEvent: (AssistantEvent) -> Void) async throws {
        for _ in 0..<maxSteps {
            try Task.checkCancellation()
            let turn = try await streamTurn(onEvent: onEvent)
            history.append(turn.assistantMessage)
            if let usage = turn.usage { onEvent(.usage(usage)) }

            switch turn.stopReason {
            case .refusal, .maxTokens, .other:
                // A cut-off or declined turn may hold incomplete tool input; never run it.
                onEvent(.stopped(turn.stopReason))
                return
            case .endTurn, .toolUse:
                break
            }
            guard !turn.toolCalls.isEmpty else {
                onEvent(.stopped(.endTurn))
                return
            }

            var results: [ToolResultPayload] = []
            for call in turn.toolCalls {
                onEvent(.toolStarted(id: call.id, name: call.name))
                let result = await run(call)
                results.append(result)
                onEvent(.toolFinished(id: call.id, name: call.name, isError: result.isError))
            }
            history.append(contentsOf: backend.toolResultMessages(results))
        }
        onEvent(.stopped(.other("step_limit")))
    }

    private func streamTurn(onEvent: (AssistantEvent) -> Void) async throws -> BackendTurn {
        let request = try backend.request(system: systemPrompt, history: history, tools: toolDefinitions)
        var parser = SSEParser()
        var accumulator = backend.makeAccumulator()
        for try await line in try await transport.lines(for: request) {
            guard let event = parser.feed(line) else { continue }
            if let text = try accumulator.consume(event), !text.isEmpty {
                onEvent(.textDelta(text))
            }
        }
        return try accumulator.finish()
    }

    private func run(_ call: ToolCall) async -> ToolResultPayload {
        guard let tool = tools[call.name] else {
            return ToolResultPayload(callID: call.id, content: "Unknown tool: \(call.name)", isError: true)
        }
        guard let input = call.input else {
            let wrapped: JSONValue = ["INVALID_JSON": .string(call.rawInput)]
            return ToolResultPayload(callID: call.id, content: wrapped.encodedString(), isError: true)
        }
        do {
            return ToolResultPayload(callID: call.id, content: try await tool.run(input), isError: false)
        } catch {
            return ToolResultPayload(callID: call.id, content: "Tool failed: \(error.localizedDescription)", isError: true)
        }
    }
}
