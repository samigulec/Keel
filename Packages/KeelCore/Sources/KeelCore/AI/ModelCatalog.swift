import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Plain request/response HTTP, for calls that do not stream.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, Int)
}

public struct URLSessionHTTPClient: HTTPClient {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, Int) {
        #if canImport(Darwin)
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
        #else
        throw AIError.unsupportedPlatform
        #endif
    }
}

/// Lists the models a key can use. Listing models costs nothing, so it
/// doubles as a free check that the key and address are right.
public enum ModelCatalog {
    public static func claudeModels(apiKey: String, client: any HTTPClient = URLSessionHTTPClient()) async throws -> [String] {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models?limit=100")!)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AnthropicBackend.apiVersion, forHTTPHeaderField: "anthropic-version")
        return try await fetch(request, client: client)
    }

    public static func openAICompatibleModels(baseURL: URL, apiKey: String?, client: any HTTPClient = URLSessionHTTPClient()) async throws -> [String] {
        var request = URLRequest(url: baseURL.appendingPathComponent("models"))
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "authorization")
        }
        return try await fetch(request, client: client)
    }

    private static func fetch(_ request: URLRequest, client: any HTTPClient) async throws -> [String] {
        var request = request
        request.timeoutInterval = 20
        let (data, status) = try await client.data(for: request)
        let body = String(data: data, encoding: .utf8) ?? ""
        guard (200..<300).contains(status) else {
            throw AIError.http(status: status, message: errorMessage(fromBody: body))
        }
        return try parseModelIDs(body)
    }

    /// Both Claude and OpenAI-style APIs answer `{"data": [{"id": ...}, ...]}`.
    static func parseModelIDs(_ body: String) throws -> [String] {
        guard let models = try JSONValue.parse(body)["data"]?.arrayValue else {
            throw AIError.invalidResponse("Model listesi okunamadı")
        }
        return models.compactMap { $0["id"]?.stringValue }
    }
}

/// A conversation the Keel AI screen can drive, whatever runs it: the
/// HTTP engine for cloud providers, or an on-device model.
@MainActor
public protocol ChatSession: AnyObject {
    func send(_ text: String, onEvent: (AssistantEvent) -> Void) async throws
}

extension AssistantEngine: ChatSession {}
