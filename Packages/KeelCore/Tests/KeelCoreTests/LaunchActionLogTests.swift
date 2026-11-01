import Foundation
import Testing
@testable import KeelCore

@Suite("Startup log")
struct LaunchActionLogTests {
    let date = Date(timeIntervalSince1970: 1_800_000_000)

    func item(_ label: String, scope: LaunchItem.Scope = .user) -> LaunchItem {
        LaunchItem(
            url: URL(fileURLWithPath: "/Users/me/Library/LaunchAgents/secret-folder/x.plist"),
            label: label, program: "/opt/tool", runsAtLoad: true, keepsAlive: false, isDisabled: false, scope: scope
        )
    }

    @Test func writesAndReadsBackCreatingTheFolder() throws {
        let sandbox = try Sandbox()
        let log = LaunchActionLog(fileURL: sandbox.home.appendingPathComponent("Logs/Keel/startup.log"))
        #expect(try log.entries().isEmpty)

        let entry = LaunchActionLog.Entry(item: item("com.example.agent", scope: .allUsers), enabled: false, outcome: .failed, detail: "olmadı", date: date)
        try log.append(entry)

        #expect(try log.entries() == [entry])
        #expect(entry.label == "com.example.agent")
        #expect(entry.scope == .allUsers)
        #expect(entry.action == .disable)
    }

    @Test func standardLogSitsBesideTheActionLog() {
        let home = URL(fileURLWithPath: "/Users/me")
        #expect(LaunchActionLog.standard(home: home).fileURL.path == "/Users/me/Library/Logs/Keel/startup.log")
        #expect(LaunchActionLog.standard(home: home).fileURL.deletingLastPathComponent() == ActionLog.standard(home: home).fileURL.deletingLastPathComponent())
    }

    @Test func fiftySequentialAppendsKeepEveryLineInOrder() throws {
        let sandbox = try Sandbox()
        let log = LaunchActionLog(fileURL: sandbox.home.appendingPathComponent("startup.log"))
        for index in 0..<50 {
            try log.append(.init(item: item("com.example.\(index)"), enabled: index.isMultiple(of: 2), outcome: .ok, date: date))
        }

        let lines = try String(contentsOf: log.fileURL, encoding: .utf8).split(separator: "\n")
        #expect(lines.count == 50)
        #expect(try log.entries().map(\.label) == (0..<50).map { "com.example.\($0)" })
    }

    @Test func detailIsCutToTwoHundredCharacters() {
        let long = String(repeating: "ş", count: 500)
        let entry = LaunchActionLog.Entry(item: item("a.b"), enabled: true, outcome: .failed, detail: long, date: date)
        #expect(entry.detail?.count == 200)
        #expect(LaunchActionLog.Entry(item: item("a.b"), enabled: true, outcome: .ok, date: date).detail == nil)
    }

    @Test func refusedEntriesCarryTheReason() throws {
        let apple = try #require(LaunchActionLog.Entry.refused(item: item("com.apple.mdworker", scope: .system), enabled: false, date: date))
        #expect(apple.outcome == .refused)
        #expect(apple.detail == LaunchControl.refusal(for: item("com.apple.mdworker")))

        let odd = try #require(LaunchActionLog.Entry.refused(item: item("evil; rm -rf ~"), enabled: true, date: date))
        #expect(odd.outcome == .refused)
        #expect(odd.action == .enable)
        #expect(odd.detail == LaunchControl.refusal(for: item("evil; rm -rf ~")))

        #expect(LaunchActionLog.Entry.refused(item: item("homebrew.mxcl.postgresql@16"), enabled: false, date: date) == nil)
    }

    @Test func linesHoldNoPlistPathOrCommand() throws {
        let sandbox = try Sandbox()
        let log = LaunchActionLog(fileURL: sandbox.home.appendingPathComponent("startup.log"))
        try log.append(.init(item: item("com.example.agent"), enabled: false, outcome: .ok, date: date))

        let line = try String(contentsOf: log.fileURL, encoding: .utf8)
        #expect(!line.contains("secret-folder"))
        #expect(!line.contains("launchctl"))
        #expect(!line.contains("/opt/tool"))
        let keys = try #require(try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]).keys
        #expect(Set(keys) == ["action", "date", "label", "outcome", "scope"])
    }
}
