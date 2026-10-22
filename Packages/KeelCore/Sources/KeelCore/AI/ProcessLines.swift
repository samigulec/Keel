import Foundation

public struct ProcessFailure: Error, Equatable, Sendable {
    public let status: Int32
    public let standardError: String

    public init(status: Int32, standardError: String) {
        self.status = status
        self.standardError = standardError
    }
}

/// Runs a command and streams its standard output line by line.
public enum ProcessLines {
    /// Holds non-Sendable Foundation objects that are only touched from the
    /// reader thread or to terminate the process.
    private final class Box: @unchecked Sendable {
        let process: Process
        let output: Pipe
        let error: Pipe
        private let lock = NSLock()
        private var errorData = Data()
        private(set) var wasCancelled = false

        init(process: Process, output: Pipe, error: Pipe) {
            self.process = process
            self.output = output
            self.error = error
        }

        func appendError(_ data: Data) {
            lock.lock()
            errorData.append(data)
            lock.unlock()
        }

        var errorText: String {
            lock.lock()
            defer { lock.unlock() }
            return String(decoding: errorData, as: UTF8.self)
        }

        func cancel() {
            lock.lock()
            wasCancelled = true
            lock.unlock()
            if process.isRunning { process.terminate() }
        }
    }

    public static func stream(
        _ executable: URL,
        arguments: [String],
        environment: [String: String]? = nil,
        currentDirectory: URL? = nil
    ) throws -> AsyncThrowingStream<String, any Error> {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        if let environment { process.environment = environment }
        if let currentDirectory { process.currentDirectoryURL = currentDirectory }
        let box = Box(process: process, output: Pipe(), error: Pipe())
        process.standardOutput = box.output
        process.standardError = box.error
        process.standardInput = FileHandle.nullDevice
        try process.run()

        let (stream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()
        continuation.onTermination = { termination in
            if case .cancelled = termination { box.cancel() }
        }

        // Drain stderr separately so a chatty process cannot block on a full pipe.
        DispatchQueue.global(qos: .utility).async {
            let handle = box.error.fileHandleForReading
            while true {
                let data = handle.availableData
                if data.isEmpty { break }
                box.appendError(data)
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let handle = box.output.fileHandleForReading
            var buffer: [UInt8] = []
            while true {
                let data = handle.availableData
                if data.isEmpty { break }
                buffer.append(contentsOf: data)
                while let newline = buffer.firstIndex(of: 0x0A) {
                    continuation.yield(String(decoding: buffer[..<newline], as: UTF8.self))
                    buffer.removeSubrange(...newline)
                }
            }
            if !buffer.isEmpty {
                continuation.yield(String(decoding: buffer, as: UTF8.self))
            }
            box.process.waitUntilExit()
            let status = box.process.terminationStatus
            if status != 0, !box.wasCancelled {
                continuation.finish(throwing: ProcessFailure(status: status, standardError: box.errorText))
            } else {
                continuation.finish()
            }
        }
        return stream
    }

    /// Runs a command to completion and returns its exit status and output.
    public static func run(
        _ executable: URL,
        arguments: [String],
        environment: [String: String]? = nil,
        currentDirectory: URL? = nil
    ) async throws -> (status: Int32, output: String) {
        var lines: [String] = []
        do {
            for try await line in try stream(executable, arguments: arguments, environment: environment, currentDirectory: currentDirectory) {
                lines.append(line)
            }
            return (0, lines.joined(separator: "\n"))
        } catch let failure as ProcessFailure {
            let output = lines.joined(separator: "\n")
            return (failure.status, output.isEmpty ? failure.standardError : output)
        }
    }
}
