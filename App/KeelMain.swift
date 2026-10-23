import Foundation
import KeelCore

/// Keel starts as the app, or, when `SystemControl` runs it as root through
/// macOS's administrator prompt, as a one-shot fan command that exits.
@main
enum KeelMain {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.count == 3, arguments[1] == FanCommand.flag {
            exit(FanCommand.run(arguments[2]))
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
