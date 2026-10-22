import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Streams a response with URLSession. HTTP errors are read in full and
/// thrown with the provider's own message.
public struct URLSessionTransport: StreamingTransport {
    public init() {}

    public func lines(for request: URLRequest) async throws -> AsyncThrowingStream<String, any Error> {
        #if canImport(Darwin)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.invalidResponse("Yanıt HTTP değil")
        }
        guard (200..<300).contains(http.statusCode) else {
            var body = ""
            for try await line in bytes.lines {
                body += line
                if body.count > 20_000 { break }
            }
            throw AIError.http(status: http.statusCode, message: errorMessage(fromBody: body))
        }

        let (stream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()
        let task = Task {
            do {
                for try await line in bytes.lines {
                    continuation.yield(line)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
        #else
        throw AIError.unsupportedPlatform
        #endif
    }
}
