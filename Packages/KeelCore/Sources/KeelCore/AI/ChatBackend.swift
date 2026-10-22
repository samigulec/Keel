import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum AIError: Error, Equatable, Sendable {
    /// The provider answered with an HTTP error; message is its own explanation.
    case http(status: Int, message: String)
    /// The stream carried an error event, e.g. "overloaded_error".
    case stream(type: String, message: String)
    case invalidResponse(String)
    case unsupportedPlatform
}

public enum StopReason: Equatable, Sendable {
    case endTurn
    case toolUse
    case maxTokens
    /// The model declined; the category comes from the provider when given.
    case refusal(category: String?)
    case other(String)
}

/// A tool the model asked to run. `input` is nil when the arguments were not valid JSON.
public struct ToolCall: Equatable, Sendable {
    public let id: String
    public let name: String
    public let input: JSONValue?
    public let rawInput: String
}

public struct ToolResultPayload: Equatable, Sendable {
    public let callID: String
    public let content: String
    public let isError: Bool

    public init(callID: String, content: String, isError: Bool) {
        self.callID = callID
        self.content = content
        self.isError = isError
    }
}

/// One finished model response.
public struct BackendTurn: Sendable {
    /// The assistant message exactly as it must be sent back next time.
    public let assistantMessage: JSONValue
    public let text: String
    public let toolCalls: [ToolCall]
    public let stopReason: StopReason
}

public struct ToolDefinition: Equatable, Sendable {
    public let name: String
    public let description: String
    public let inputSchema: JSONValue

    public init(name: String, description: String, inputSchema: JSONValue) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

/// Builds requests for one provider and reads its streamed responses.
public protocol ChatBackend: Sendable {
    func userMessage(_ text: String) -> JSONValue
    func request(system: String, history: [JSONValue], tools: [ToolDefinition]) throws -> URLRequest
    func makeAccumulator() -> any TurnAccumulator
    func toolResultMessages(_ results: [ToolResultPayload]) -> [JSONValue]
}

public protocol TurnAccumulator {
    /// Applies one stream event and returns any new visible text.
    mutating func consume(_ event: SSEEvent) throws -> String?
    func finish() throws -> BackendTurn
}

/// Delivers a streamed HTTP response line by line.
public protocol StreamingTransport: Sendable {
    func lines(for request: URLRequest) async throws -> AsyncThrowingStream<String, any Error>
}

/// Reads the human-readable message out of a provider's JSON error body.
func errorMessage(fromBody body: String) -> String {
    guard let json = try? JSONValue.parse(body) else {
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return json["error"]?["message"]?.stringValue
        ?? json["error"]?.stringValue
        ?? json["message"]?.stringValue
        ?? body
}
