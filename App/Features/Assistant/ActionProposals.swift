import AppKit
import KeelCore

/// Something besides a cleanup that Keel AI suggested: turning startup
/// items off or on, quitting apps, or changing the fans. Nothing happens
/// until the user presses the card's button.
struct ActionProposal: Identifiable, Equatable {
    enum Kind: Equatable {
        case startup([LaunchItem], enable: Bool)
        case removeLoginItems([LoginItem])
        case quitApps([RunningApp])
        case fans(FanSetting)
    }

    struct RunningApp: Equatable, Identifiable {
        var id: String { bundleID }
        let name: String
        let bundleID: String
    }

    let id = UUID()
    let kind: Kind
    let reason: String

    var title: String {
        switch kind {
        case .startup(_, let enable): enable ? "Servisleri aç" : "Arka plan servislerini kapat"
        case .removeLoginItems: "Girişte açılmasın"
        case .quitApps: "Uygulamaları kapat"
        case .fans(.automatic): "Fanları otomatiğe al"
        case .fans(.fixed(let percent)): percent == 100 ? "Fanları en yüksek hıza al" : "Fanları %\(percent) hıza al"
        }
    }

    /// What the card lists.
    var lines: [String] {
        switch kind {
        case .startup(let items, _): items.map(\.displayName)
        case .removeLoginItems(let items): items.map(\.name)
        case .quitApps(let apps): apps.map(\.name)
        case .fans(.automatic): ["macOS fan hızını yeniden kendisi ayarlar."]
        case .fans(.fixed): ["Otomatik'e alana ya da Mac yeniden başlayana kadar böyle kalır."]
        }
    }

    var buttonTitle: String {
        switch kind {
        case .startup(_, let enable): enable ? "Aç" : "Kapat"
        case .removeLoginItems: "Listeden çıkar"
        case .quitApps: "Kapat"
        case .fans: "Uygula"
        }
    }

    /// A short note under the button.
    var footnote: String {
        switch kind {
        case .startup(let items, _):
            items.contains(where: LaunchControl.needsAdministrator)
                ? "Sistem servisleri için macOS yönetici şifresi ister. Geri alınabilir."
                : "Mac yeniden başlasa da böyle kalır. Geri alınabilir."
        case .removeLoginItems: "Uygulamalar silinmez; yalnızca girişte açılmazlar. Geri alınabilir."
        case .quitApps: "Kaydedilmemiş işin varsa uygulama önce sorar."
        case .fans: "macOS yönetici şifresi ister."
        }
    }
}

/// The outcome shown on an applied card.
struct ActionResult: Equatable {
    var text: String
    var isError: Bool
    var canUndo: Bool
    var undone = false
}

/// Turns what Keel AI asked for into a card, and carries the card out.
@MainActor
enum ActionProposals {
    static let actions = ["disable_startup", "enable_startup", "remove_login_items", "quit_apps", "set_fans"]

    /// Resolves the request against what is on this Mac now. Returns the
    /// card, or why there is none, plus a note for the model.
    static func resolve(_ input: JSONValue, performance: PerformanceModel) async -> (proposal: ActionProposal?, result: JSONValue) {
        let reason = input["reason"]?.stringValue ?? ""
        let names = (input["names"]?.arrayValue ?? input["labels"]?.arrayValue ?? input["apps"]?.arrayValue ?? [])
            .compactMap(\.stringValue)
        var notFound: [String] = []
        var refused: [String] = []
        let kind: ActionProposal.Kind?

        switch input["action"]?.stringValue {
        case "disable_startup", "enable_startup":
            let enable = input["action"]?.stringValue == "enable_startup"
            if !performance.launchItemsLoaded { await performance.refreshLaunchItems() }
            var chosen: [LaunchItem] = []
            for name in names {
                let matches = performance.launchItems.filter { $0.label == name }
                    + performance.launchItems.filter { $0.label != name && $0.displayName.localizedCaseInsensitiveCompare(name) == .orderedSame }
                guard let item = matches.first else { notFound.append(name); continue }
                if let refusal = LaunchControl.refusal(for: item) {
                    refused.append("\(item.displayName): \(refusal)")
                } else if !chosen.contains(item), item.isDisabled == enable {
                    chosen.append(item)
                }
            }
            kind = chosen.isEmpty ? nil : .startup(chosen, enable: enable)

        case "remove_login_items":
            let listed = await performance.loginItemsWhenReady()
            if let error = performance.loginItemsError, !performance.loginItemsLoaded {
                return (nil, ["shown": false, "reason": .string(error)])
            }
            var chosen: [LoginItem] = []
            for name in names {
                guard let item = listed.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame || $0.path == name }) else {
                    notFound.append(name)
                    continue
                }
                if !chosen.contains(item) { chosen.append(item) }
            }
            kind = chosen.isEmpty ? nil : .removeLoginItems(chosen)

        case "quit_apps":
            let running = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
            var chosen: [ActionProposal.RunningApp] = []
            for name in names {
                guard let app = running.first(where: {
                    $0.bundleIdentifier == name || $0.localizedName?.localizedCaseInsensitiveCompare(name) == .orderedSame
                }), let bundleID = app.bundleIdentifier else {
                    notFound.append(name)
                    continue
                }
                if bundleID == Bundle.main.bundleIdentifier || bundleID == "com.apple.finder" {
                    refused.append("\(app.localizedName ?? bundleID): kapatılmaz")
                } else if !chosen.contains(where: { $0.bundleID == bundleID }) {
                    chosen.append(.init(name: app.localizedName ?? bundleID, bundleID: bundleID))
                }
            }
            kind = chosen.isEmpty ? nil : .quitApps(chosen)

        case "set_fans":
            if input["mode"]?.stringValue == "auto" {
                kind = .fans(.automatic)
            } else if let percent = input["percent"]?.numberValue.map({ Int($0.rounded()) }), (50...100).contains(percent) {
                kind = .fans(.fixed(percent: percent))
            } else {
                return (nil, ["shown": false, "reason": "Pass mode \"auto\", or percent between 50 and 100."])
            }

        default:
            return (nil, ["shown": false, "reason": .string("Unknown action. Use one of: \(actions.joined(separator: ", ")).")])
        }

        var result: [String: JSONValue] = [:]
        if !notFound.isEmpty { result["not_found"] = .array(notFound.map(JSONValue.string)) }
        if !refused.isEmpty { result["refused"] = .array(refused.map(JSONValue.string)) }
        guard let kind else {
            result["shown"] = false
            result["reason"] = "Nothing to change: the names did not match, were refused, or are already in that state."
            return (nil, .object(result))
        }
        result["shown"] = true
        result["note"] = "The user now sees a card and decides. Nothing has changed yet."
        return (ActionProposal(kind: kind, reason: reason), .object(result))
    }

    static func apply(_ proposal: ActionProposal, performance: PerformanceModel) async -> ActionResult {
        switch proposal.kind {
        case .startup(let items, let enable):
            let problems = await performance.setLaunchItems(items, enabled: enable)
            let changed = items.count - problems.count
            guard problems.isEmpty else {
                return ActionResult(text: problems.joined(separator: "\n"), isError: true, canUndo: changed > 0)
            }
            return ActionResult(text: "\(items.count) servis \(enable ? "açıldı" : "kapatıldı").", isError: false, canUndo: true)

        case .removeLoginItems(let items):
            var problems: [String] = []
            for item in items {
                if case .failed(let message) = await performance.removeLoginItem(item) { problems.append("\(item.name): \(message)") }
            }
            guard problems.isEmpty else { return ActionResult(text: problems.joined(separator: "\n"), isError: true, canUndo: problems.count < items.count) }
            return ActionResult(text: "\(items.count) uygulama artık girişte açılmayacak.", isError: false, canUndo: true)

        case .quitApps(let apps):
            for app in apps {
                for running in NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID) {
                    running.terminate()
                }
            }
            try? await Task.sleep(for: .seconds(2))
            let stillOpen = apps.filter { !NSRunningApplication.runningApplications(withBundleIdentifier: $0.bundleID).isEmpty }
            guard stillOpen.isEmpty else {
                return ActionResult(
                    text: "Hâlâ açık: \(stillOpen.map(\.name).joined(separator: ", ")). Kaydedilmemiş bir iş için soruyor olabilir.",
                    isError: true, canUndo: false
                )
            }
            return ActionResult(text: "\(apps.map(\.name).joined(separator: ", ")) kapatıldı.", isError: false, canUndo: false)

        case .fans(let setting):
            switch await performance.setFans(setting) {
            case .done(let output):
                let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return ActionResult(text: text.isEmpty ? "Fanlar ayarlandı." : text, isError: false, canUndo: setting != .automatic)
            case .cancelled:
                return ActionResult(text: "Yönetici izni verilmedi; fanlar olduğu gibi kaldı.", isError: true, canUndo: false)
            case .failed(let message):
                return ActionResult(text: message, isError: true, canUndo: false)
            }
        }
    }

    /// Reverses an applied card where that makes sense.
    static func undo(_ proposal: ActionProposal, performance: PerformanceModel) async -> ActionResult {
        switch proposal.kind {
        case .startup(let items, let enable):
            let problems = await performance.setLaunchItems(items, enabled: !enable)
            return ActionResult(
                text: problems.isEmpty ? "Geri alındı; servisler eski hâlinde." : problems.joined(separator: "\n"),
                isError: !problems.isEmpty, canUndo: false, undone: problems.isEmpty
            )
        case .removeLoginItems(let items):
            for item in items { await performance.restoreLoginItem(item) }
            let missing = items.filter { !performance.loginItems.contains($0) }
            return ActionResult(
                text: missing.isEmpty ? "Geri alındı; uygulamalar yine girişte açılacak." : "Geri eklenemedi: \(missing.map(\.name).joined(separator: ", ")).",
                isError: !missing.isEmpty, canUndo: false, undone: missing.isEmpty
            )
        case .fans:
            switch await performance.setFans(.automatic) {
            case .done: return ActionResult(text: "Fanlar yeniden otomatik.", isError: false, canUndo: false, undone: true)
            case .cancelled: return ActionResult(text: "Yönetici izni verilmedi; fanlar elle ayarlı kaldı.", isError: true, canUndo: true)
            case .failed(let message): return ActionResult(text: message, isError: true, canUndo: true)
            }
        case .quitApps:
            return ActionResult(text: "Kapatılan uygulamalar geri açılmaz.", isError: true, canUndo: false)
        }
    }
}
