import Foundation
import Testing
@testable import KeelCore

@Suite("Startup control")
struct StartupControlTests {
    func item(_ label: String, scope: LaunchItem.Scope, path: String = "/Library/LaunchDaemons/x.plist") -> LaunchItem {
        LaunchItem(url: URL(fileURLWithPath: path), label: label, program: nil, runsAtLoad: true, keepsAlive: false, isDisabled: false, scope: scope)
    }

    @Test func parsesOverridesOldAndNew() {
        let output = """
        disabled services = {
        \t"com.cloudflare.1dot1dot1dot1.macos.warp.daemon" => disabled
        \t"com.microsoft.update.agent" => enabled
        \t"com.valvesoftware.steam.ipctool" => true
        \t"org.example.old" => false
        }
        login item associations = {
        }
        """
        let overrides = LaunchControl.parseOverrides(output)
        #expect(overrides == [
            "com.cloudflare.1dot1dot1dot1.macos.warp.daemon": true,
            "com.microsoft.update.agent": false,
            "com.valvesoftware.steam.ipctool": true,
            "org.example.old": false,
        ])
    }

    @Test func overrideWinsOverPlist() throws {
        let sandbox = try Sandbox()
        let agents = sandbox.home.appendingPathComponent("Library/LaunchAgents")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        for (label, disabled) in [("a.off.by.launchctl", false), ("b.on.by.launchctl", true), ("c.untouched", false)] {
            let data = try PropertyListSerialization.data(fromPropertyList: ["Label": label, "RunAtLoad": true, "Disabled": disabled], format: .xml, options: 0)
            try data.write(to: agents.appendingPathComponent("\(label).plist"))
        }
        let items = LaunchItemScanner.items(in: agents, scope: .user, overrides: ["a.off.by.launchctl": true, "b.on.by.launchctl": false])
        #expect(items.map(\.isDisabled) == [true, false, false])
    }

    @Test func refusesAppleAndOddLabels() {
        #expect(LaunchControl.refusal(for: item("com.apple.mdworker", scope: .system)) != nil)
        #expect(LaunchControl.refusal(for: item("evil; rm -rf ~", scope: .user)) != nil)
        #expect(LaunchControl.refusal(for: item("com.crystalidea.macsfancontrol.smcwrite", scope: .system)) == nil)
        #expect(LaunchControl.refusal(for: item("homebrew.mxcl.postgresql@16", scope: .user)) == nil)
    }

    @Test func scriptsTargetTheRightDomain() {
        let daemon = item("com.cloudflare.warp.daemon", scope: .system, path: "/Library/LaunchDaemons/com.cloudflare.warp.daemon.plist")
        #expect(LaunchControl.needsAdministrator(daemon))
        #expect(LaunchControl.script(enable: false, item: daemon, userID: 501)
            == "/bin/launchctl disable 'system/com.cloudflare.warp.daemon' && { /bin/launchctl bootout 'system/com.cloudflare.warp.daemon' 2>/dev/null; true; }")

        let agent = item("com.microsoft.update.agent", scope: .allUsers, path: "/Library/LaunchAgents/com.microsoft.update.agent.plist")
        #expect(!LaunchControl.needsAdministrator(agent))
        #expect(LaunchControl.script(enable: true, item: agent, userID: 501)
            == "/bin/launchctl enable 'gui/501/com.microsoft.update.agent' && { /bin/launchctl bootstrap 'gui/501' '/Library/LaunchAgents/com.microsoft.update.agent.plist' 2>/dev/null; true; }")
    }

    @Test func quoting() {
        #expect(ShellCommand.quote("it's") == "'it'\\''s'")
        #expect(ShellCommand.join(["/Applications/My App.app/Contents/MacOS/Keel", "--fan", "auto"])
            == "'/Applications/My App.app/Contents/MacOS/Keel' '--fan' 'auto'")
        #expect(ShellCommand.appleScriptString(#"say "hi" \ bye"#) == #""say \"hi\" \\ bye""#)
        #expect(ShellCommand.administratorScript("echo 'a'", prompt: "Keel")
            == #"do shell script "echo 'a'" with prompt "Keel" with administrator privileges"#)
    }

    @Test func loginItems() {
        let output = "Steam\t/Applications/Steam.app/\nMacs Fan Control\t/Applications/Macs Fan Control.app\nGhost\tmissing value\n\n"
        let items = LoginItemScript.parse(output)
        #expect(items == [
            LoginItem(name: "Steam", path: "/Applications/Steam.app"),
            LoginItem(name: "Macs Fan Control", path: "/Applications/Macs Fan Control.app"),
            LoginItem(name: "Ghost", path: ""),
        ])
        #expect(LoginItemScript.remove(items[0]) == #"tell application "System Events" to delete login item "Steam""#)
        #expect(LoginItemScript.add(items[2]) == nil)
        #expect(LoginItemScript.add(items[1])?.contains(#"path:"/Applications/Macs Fan Control.app""#) == true)
    }
}

@Suite("Fan control")
struct FanControlTests {
    @Test func settingArguments() {
        #expect(FanSetting(argument: "auto") == .automatic)
        #expect(FanSetting(argument: "75") == .fixed(percent: 75))
        #expect(FanSetting(argument: "0") == nil)
        #expect(FanSetting(argument: "101") == nil)
        #expect(FanSetting(argument: "٧٥") == nil)
        #expect(FanSetting(argument: "75; reboot") == nil)
        #expect(FanSetting.fixed(percent: 60).argument == "60")
    }

    @Test func targetsStayWithinLimits() {
        #expect(FanMath.target(percent: 100, minimum: 1_200, maximum: 6_000) == 6_000)
        #expect(FanMath.target(percent: 50, minimum: 1_200, maximum: 6_000) == 3_000)
        // Never below the fan's own minimum.
        #expect(FanMath.target(percent: 10, minimum: 1_200, maximum: 6_000) == 1_200)
        #expect(FanMath.target(percent: 50, minimum: 0, maximum: 0) == nil)
        #expect(FanMath.target(percent: 50, minimum: 7_000, maximum: 6_000) == nil)
        #expect(FanMath.target(percent: 0, minimum: 1_200, maximum: 6_000) == nil)
    }

    @Test func encodingRoundTrips() throws {
        for (value, type) in [(4_321.5, "flt "), (2_500.25, "fpe2"), (1.0, "ui8 "), (3.0, "ui16")] {
            let bytes = try #require(FanMath.encode(value, type: type))
            #expect(SMCValue.decode(type: type, bytes: bytes) == value)
        }
        #expect(FanMath.encode(1, type: "ui8 ") == [1])
        #expect(FanMath.encode(300, type: "ui8 ") == nil)
        #expect(FanMath.encode(-1, type: "flt ") == nil)
        #expect(FanMath.encode(1, type: "sp78") == nil)
    }
}

@Suite("Fan helper")
struct FanHelperTests {
    @Test func requestsRoundTripAndRejectJunk() throws {
        let request = FanHelper.Request(id: "8C1F2A9E-1B2C-4D5E-8F90-A1B2C3D4E5F6", setting: .fixed(percent: 80))
        #expect(FanHelper.Request(line: request.line) == request)
        #expect(FanHelper.Request(line: "abc auto")?.setting == .automatic)
        #expect(FanHelper.Request(line: "abc 101") == nil)
        #expect(FanHelper.Request(line: "../x 80") == nil)
        #expect(FanHelper.Request(line: "abc 80 extra") == nil)
        #expect(FanHelper.Request(line: "") == nil)
    }

    @Test func statusRoundTrips() throws {
        let status = FanHelper.Status(id: "abc-1", succeeded: false, lines: ["Fan 1: macOS kontrolü geri aldı."])
        #expect(FanHelper.Status(text: status.text) == status)
        #expect(FanHelper.Status(text: "abc maybe") == nil)
        #expect(FanHelper.Status(text: "abc ok")?.lines == [])
    }

    @Test func installScriptIsOneLineAndRootOwned() throws {
        let script = FanHelper.installScript(from: "/Users/me/Library/Developer/Xcode/DerivedData/Keel/Build/Products/Debug/Keel.app/Contents/MacOS/Keel", userID: 501)
        #expect(!script.contains("\n"))
        #expect(!FanHelper.plist.contains("\n"))
        #expect(script.contains("/usr/bin/install -o root -g wheel -m 755 '/Users/me/"))
        #expect(script.contains("/usr/sbin/chown 501 '/Library/Application Support/Keel/FanRequest'"))
        #expect(script.contains("/bin/launchctl bootstrap system '/Library/LaunchDaemons/com.samigulec.Keel.fan.plist'"))
        let plist = try #require(try PropertyListSerialization.propertyList(from: Data(FanHelper.plist.utf8), format: nil) as? [String: Any])
        #expect(plist["Label"] as? String == FanHelper.label)
        #expect(plist["ProgramArguments"] as? [String] == [FanHelper.executable, FanHelper.daemonFlag])
        #expect(plist["WatchPaths"] as? [String] == [FanHelper.requestFolder])
        #expect(FanHelper.uninstallScript().contains("/bin/rm -rf '/Library/Application Support/Keel'"))
    }
}
