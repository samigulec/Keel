import Foundation
import Testing
@testable import KeelCore

@Suite("System readers")
struct SystemReadersTests {
    @Test func memoryFromMeminfo() throws {
        let text = """
        MemTotal:       16000000 kB
        MemFree:         1000000 kB
        MemAvailable:    4000000 kB
        Cached:          2500000 kB
        """
        let snapshot = try #require(MemoryReader.parseMeminfo(text))
        #expect(snapshot.totalBytes == 16_000_000 * 1024)
        #expect(snapshot.usedBytes == 12_000_000 * 1024)
        #expect(snapshot.pressure == .normal)
        #expect(abs(snapshot.usedFraction - 0.75) < 0.0001)
    }

    @Test func lowAvailableMemoryRaisesPressure() throws {
        let tight = try #require(MemoryReader.parseMeminfo("MemTotal: 1000 kB\nMemAvailable: 150 kB\n"))
        #expect(tight.pressure == .warning)
        let critical = try #require(MemoryReader.parseMeminfo("MemTotal: 1000 kB\nMemAvailable: 50 kB\n"))
        #expect(critical.pressure == .critical)
    }

    @Test func liveMemoryReadingIsSane() throws {
        let snapshot = try #require(MemoryReader.current())
        #expect(snapshot.totalBytes > 0)
        #expect(snapshot.usedBytes <= snapshot.totalBytes)
    }

    @Test func cpuUsageBetweenSamples() {
        let earlier = CPUTicks(user: 100, system: 50, idle: 850, nice: 0)
        let later = CPUTicks(user: 160, system: 70, idle: 1_020, nice: 0)
        // 80 busy out of 250 elapsed
        #expect(abs(CPUReader.usage(from: earlier, to: later) - 0.32) < 0.0001)
        #expect(CPUReader.usage(from: later, to: earlier) == 0)
        #expect(CPUReader.usage(from: earlier, to: earlier) == 0)
    }

    @Test func cpuTicksFromProcStat() throws {
        let ticks = try #require(CPUReader.parseProcStat("cpu  10 2 30 400 5 0 1 0 0 0\ncpu0 1 1 1 1\n"))
        #expect(ticks == CPUTicks(user: 10, system: 30, idle: 400, nice: 2))
    }

    @Test func liveCPUTicksAdvance() throws {
        let first = try #require(CPUReader.ticks())
        var spin = 0
        for value in 0..<2_000_000 { spin &+= value }
        let second = try #require(CPUReader.ticks())
        #expect(second.total >= first.total)
        #expect(spin != 1)
    }

    @Test func processTotalsIncludeHelpers() {
        let samples = [
            ProcessSample(pid: 1, parentPID: 0, footprintBytes: 10),          // launchd
            ProcessSample(pid: 100, parentPID: 1, footprintBytes: 500),       // Browser
            ProcessSample(pid: 101, parentPID: 100, footprintBytes: 300),     // renderer
            ProcessSample(pid: 102, parentPID: 101, footprintBytes: 200),     // nested helper
            ProcessSample(pid: 200, parentPID: 1, footprintBytes: 50),        // Notes
            ProcessSample(pid: 300, parentPID: 1, footprintBytes: 999),       // not an app
        ]
        let totals = ProcessMemory.totals(for: [100, 200], in: samples)
        #expect(totals == [100: 1_000, 200: 50])
    }

    @Test func processTotalsSurviveParentCycles() {
        let samples = [
            ProcessSample(pid: 10, parentPID: 11, footprintBytes: 1),
            ProcessSample(pid: 11, parentPID: 10, footprintBytes: 1),
        ]
        #expect(ProcessMemory.totals(for: [99], in: samples).isEmpty)
    }
}

@Suite("LaunchItemScanner")
struct LaunchItemScannerTests {
    func writePlist(_ object: [String: Any], named name: String, in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
        try data.write(to: directory.appendingPathComponent(name))
    }

    @Test func readsUserLaunchAgents() throws {
        let sandbox = try Sandbox()
        let agents = sandbox.home.appendingPathComponent("Library/LaunchAgents")
        try writePlist([
            "Label": "com.google.keystone.agent",
            "ProgramArguments": ["/Users/me/Library/Application Support/Google/GoogleUpdater/Current/GoogleUpdater.app/Contents/MacOS/GoogleUpdater", "--wake"],
            "RunAtLoad": true,
        ], named: "com.google.keystone.agent.plist", in: agents)
        try writePlist([
            "Label": "homebrew.mxcl.postgresql",
            "Program": "/opt/homebrew/bin/postgres",
            "KeepAlive": ["SuccessfulExit": false],
            "Disabled": true,
        ], named: "homebrew.mxcl.postgresql.plist", in: agents)
        try Data("not a plist".utf8).write(to: agents.appendingPathComponent("broken.plist"))
        try Data("ignored".utf8).write(to: agents.appendingPathComponent("notes.txt"))

        let items = LaunchItemScanner.items(in: agents, scope: .user)

        #expect(items.map(\.displayName) == ["GoogleUpdater", "homebrew.mxcl.postgresql"])
        let updater = items[0]
        #expect(updater.runsAtLoad)
        #expect(!updater.keepsAlive)
        let postgres = items[1]
        #expect(postgres.keepsAlive)
        #expect(postgres.isDisabled)
        #expect(postgres.program == "/opt/homebrew/bin/postgres")
        #expect(postgres.scope == .user)
    }

    @Test func missingFolderIsEmpty() throws {
        let sandbox = try Sandbox()
        #expect(LaunchItemScanner.items(in: sandbox.home.appendingPathComponent("nope"), scope: .user).isEmpty)
    }
}
