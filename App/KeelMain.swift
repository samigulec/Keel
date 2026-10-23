import Foundation
import KeelCore

/// Keel starts as the app, or as root for the fans: a one-shot command run
/// through macOS's administrator prompt, or the installed fan helper that
/// launchd starts when Keel leaves a request (see `FanHelper`).
@main
enum KeelMain {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.count == 3, arguments[1] == FanCommand.flag {
            exit(FanCommand.run(arguments[2]))
        }
        if arguments.count == 2, arguments[1] == FanHelper.daemonFlag {
            exit(FanDaemon.run())
        }
        KeelApp.main()
    }
}

/// `Keel --keel-fan auto|1...100`: the only thing Keel does as root.
enum FanCommand {
    static let flag = "--keel-fan"

    static func run(_ argument: String) -> Int32 {
        guard let setting = FanSetting(argument: argument) else {
            FileHandle.standardError.write(Data("Geçersiz fan ayarı.\n".utf8))
            return 2
        }
        guard geteuid() == 0 else {
            FileHandle.standardError.write(Data("Fanları değiştirmek yönetici izni ister.\n".utf8))
            return 1
        }
        let result = FanController.apply(setting)
        let text = result.lines.joined(separator: "\n") + "\n"
        // Errors go to stderr, where the administrator prompt's caller finds them.
        (result.succeeded ? FileHandle.standardOutput : FileHandle.standardError).write(Data(text.utf8))
        return result.succeeded ? 0 : 1
    }
}

/// The installed fan helper: answers the request Keel left, then exits.
/// launchd starts it again when the request folder changes.
enum FanDaemon {
    static func run() -> Int32 {
        guard geteuid() == 0 else { return 1 }
        // A new request may arrive while one is applied; take up to a few.
        for _ in 0..<5 {
            guard let request = readRequest() else { return 0 }
            if let done = (try? String(contentsOfFile: FanHelper.statusFile, encoding: .utf8)).flatMap(FanHelper.Status.init(text:)),
               done.id == request.id {
                return 0
            }
            let result = FanController.apply(request.setting)
            let status = FanHelper.Status(id: request.id, succeeded: result.succeeded, lines: result.lines)
            try? Data(status.text.utf8).write(to: URL(fileURLWithPath: FanHelper.statusFile), options: .atomic)
        }
        return 0
    }

    /// The request, read without following links and only if it is a small file.
    private static func readRequest() -> FanHelper.Request? {
        let descriptor = open(FanHelper.requestFile, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { return nil }
        defer { close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFREG, info.st_size <= 256 else { return nil }
        var buffer = [UInt8](repeating: 0, count: 256)
        let count = read(descriptor, &buffer, buffer.count)
        guard count > 0 else { return nil }
        return FanHelper.Request(line: String(decoding: buffer.prefix(count), as: UTF8.self))
    }
}
