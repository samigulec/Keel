import Foundation
import KeelCore

/// A cleanup Keel AI suggested: whole categories or single items. Nothing
/// happens until the user confirms it, and they can untick any item first.
struct CleanupProposal: Identifiable, Equatable {
    let id = UUID()
    let items: [CleanupItem]
    let reason: String
    /// Titles of the categories the items come from.
    let titles: [String]

    var bytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }
}

/// "~/Library/Caches/x" <-> "/Users/me/Library/Caches/x"
enum HomePath {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path

    static func display(_ url: URL) -> String {
        url.path.hasPrefix(home) ? "~" + url.path.dropFirst(home.count) : url.path
    }

    static func expand(_ path: String) -> String {
        var path = path.trimmingCharacters(in: .whitespaces)
        if path.hasPrefix("~") { path = home + path.dropFirst() }
        while path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return path
    }
}

/// The tools Keel AI may call. They read the Mac's state through the same
/// models the screens use; none of them changes anything. Changes are only
/// proposed, as cards the user confirms.
@MainActor
enum KeelTools {
    static let displayNames: [String: String] = [
        "get_system_status": "Sistem durumu",
        "scan_cleanable_space": "Temizlenebilir alan taraması",
        "get_top_memory_apps": "Uygulamaların bellek kullanımı",
        "get_background_services": "Arka plan servisleri",
        "get_installed_apps": "Yüklü uygulamalar",
        "get_large_files": "Büyük dosyalar",
        "propose_cleanup": "Temizlik önerisi",
        "propose_action": "Öneri",
    ]

    /// `compact` trims tool output for models with a small context window,
    /// such as Apple's on-device model.
    static func make(
        status: SystemStatus,
        cleanup: CleanupModel,
        performance: PerformanceModel,
        applications: ApplicationsModel,
        largeFiles: LargeFilesModel,
        compact: Bool = false,
        propose: @escaping @MainActor (CleanupProposal) -> Void,
        proposeAction: @escaping @MainActor (ActionProposal) -> Void
    ) -> [AITool] {
        let noInput: JSONValue = ["type": "object", "properties": [:], "additionalProperties": false]

        return [
            AITool(
                name: "get_system_status",
                description: "Reads the Mac's current state: chip, CPU load per core, GPU load, memory use and pressure with its breakdown and swap, disk space and throughput, battery health, temperatures per part (CPU, GPU, SSD, battery) and fan speeds, thermal state and uptime. Call this whenever the user asks why the Mac is slow, hot, loud or low on space, or about memory, CPU, GPU, battery or storage.",
                inputSchema: noInput
            ) { _ in
                systemStatus(status, compact: compact).encodedString()
            },

            AITool(
                name: "scan_cleanable_space",
                description: "Scans app caches, old logs, browser caches, developer caches, old downloads and the Trash, and returns each category's size and largest items. Takes a few seconds and only reads. Call this before recommending any cleanup or when the user asks what takes up space.",
                inputSchema: noInput
            ) { _ in
                let results = await cleanup.scanAndWait()
                return cleanupSummary(results, appNames: cleanup.runningAppNames, compact: compact).encodedString()
            },

            AITool(
                name: "get_top_memory_apps",
                description: "Lists the apps using the most memory right now, helper processes included (e.g. a browser's tabs). Call this when memory pressure is high or the user asks which app slows the Mac down.",
                inputSchema: noInput
            ) { _ in
                await performance.refreshApps()
                return topApps(performance, compact: compact).encodedString()
            },

            AITool(
                name: "get_installed_apps",
                description: "Lists the installed apps: the largest with their size, apps not opened for 90+ days, and Intel-only apps that run through Rosetta. Call this when the user asks which apps take space, which they could remove, or about old or Intel apps. Keel AI cannot remove apps; tell the user to use Keel's Uygulamalar section, which removes an app with its leftover files.",
                inputSchema: noInput
            ) { _ in
                let apps = await applications.listWhenReady()
                return installedApps(apps, compact: compact).encodedString()
            },

            AITool(
                name: "get_large_files",
                description: "Lists the largest files in the user's own folders (Desktop, Documents, Downloads and so on; not Library or apps) with size, folder, kind and when each was last opened. Takes a while the first time. Call this when the user asks what takes up space in their files, about old downloads, videos or disk images. Keel AI cannot remove them; point the user to Keel's Büyük Dosyalar section.",
                inputSchema: noInput
            ) { _ in
                let files = await largeFiles.filesWhenReady()
                return largeFilesSummary(files, compact: compact).encodedString()
            },

            AITool(
                name: "get_background_services",
                description: "Lists launchd agents and daemons that start on their own (at login or kept running) with their labels, and the apps that open at login. Call this when the user asks what runs in the background, why startup is slow, or wants something to stop starting on its own. Reading login items the first time may ask the user for permission.",
                inputSchema: noInput
            ) { _ in
                await performance.refreshLaunchItems()
                let listed = await performance.loginItemsWhenReady()
                let loginItems: JSONValue = performance.loginItemsLoaded
                    ? .array(listed.map { .string($0.name) })
                    : .string(performance.loginItemsError ?? "unavailable")
                return JSONValue.object([
                    "services": backgroundServices(performance, compact: compact),
                    "login_items": loginItems,
                ]).encodedString()
            },

            AITool(
                name: "propose_cleanup",
                description: "Shows the user a cleanup card with a button to confirm; nothing is removed unless they press it, so never say that something was cleaned. Call scan_cleanable_space first. Pass `items` (paths exactly as scan_cleanable_space lists them) when the user names specific things, e.g. only Firefox's cache; pass `categories` for whole categories. Prefer preselected categories; propose 'trash' (deleted permanently) or 'oldDownloads' (personal files) only when the user clearly wants that.",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "items": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Paths of single items from scan_cleanable_space, e.g. ~/Library/Caches/Firefox/Profiles.",
                        ],
                        "categories": [
                            "type": "array",
                            "items": ["type": "string", "enum": .array(CleanupCategoryID.allCases.map { .string($0.rawValue) })],
                            "description": "Whole categories from scan_cleanable_space.",
                        ],
                        "reason": ["type": "string", "description": "One sentence for the user on why this helps."],
                    ],
                    "required": ["reason"],
                    "additionalProperties": false,
                ]
            ) { input in
                proposal(from: input, cleanup: cleanup, propose: propose).encodedString()
            },

            AITool(
                name: "propose_action",
                description: "Shows the user a card with a button to confirm; nothing changes unless they press it, so never say it was done. Actions: 'disable_startup' / 'enable_startup' with `names` = service labels from get_background_services (Keel refuses macOS's own com.apple.* services; leave security software and VPNs the user relies on alone unless asked); 'remove_login_items' with `names` = login item app names (the apps stay installed); 'quit_apps' with `names` = app names from get_top_memory_apps (apps ask before losing unsaved work); 'set_fans' with `mode` 'auto' or `percent` 50-100 of each fan's top speed (only when the Mac is hot or the user asks; needs the administrator password; stays until auto or a restart).",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "action": ["type": "string", "enum": .array(ActionProposals.actions.map(JSONValue.string))],
                        "names": ["type": "array", "items": ["type": "string"], "description": "Service labels, login item names or app names, depending on the action."],
                        "mode": ["type": "string", "enum": ["auto"], "description": "set_fans only: back to automatic."],
                        "percent": ["type": "integer", "minimum": 50, "maximum": 100, "description": "set_fans only: fixed speed as a share of each fan's maximum."],
                        "reason": ["type": "string", "description": "One sentence for the user on why this helps."],
                    ],
                    "required": ["action", "reason"],
                    "additionalProperties": false,
                ]
            ) { input in
                let (proposal, result) = await ActionProposals.resolve(input, performance: performance)
                if let proposal { proposeAction(proposal) }
                return result.encodedString()
            },
        ]
    }

    // MARK: - Proposals

    /// Resolves the model's request against the latest scan and shows the card.
    static func proposal(
        from input: JSONValue,
        cleanup: CleanupModel,
        propose: @MainActor (CleanupProposal) -> Void
    ) -> JSONValue {
        let all = cleanup.results.flatMap(\.items)
        let byPath = Dictionary(all.map { ($0.url.path, $0) }, uniquingKeysWith: { first, _ in first })

        var chosen: [CleanupItem] = []
        var notFound: [String] = []
        for path in (input["items"]?.arrayValue ?? []).compactMap(\.stringValue) {
            if let item = byPath[HomePath.expand(path)] {
                if !chosen.contains(item) { chosen.append(item) }
            } else {
                notFound.append(path)
            }
        }
        let categories = (input["categories"]?.arrayValue ?? []).compactMap { $0.stringValue.flatMap(CleanupCategoryID.init(rawValue:)) }
        for result in cleanup.results where categories.contains(result.category.id) {
            let extra = result.items.filter { !chosen.contains($0) }
            chosen += extra
        }

        guard !chosen.isEmpty else {
            return [
                "shown": false,
                "reason": "Nothing matched the latest scan. Run scan_cleanable_space and use its exact paths or category ids.",
                "not_found": .array(notFound.map(JSONValue.string)),
            ]
        }

        let titles = cleanup.results
            .filter { result in chosen.contains { $0.category == result.category.id } }
            .map(\.category.title)
        let proposal = CleanupProposal(items: chosen, reason: input["reason"]?.stringValue ?? "", titles: titles)
        propose(proposal)

        var result: [String: JSONValue] = [
            "shown": true,
            "item_count": .number(Double(chosen.count)),
            "total": .string(ByteFormat.string(proposal.bytes)),
            "note": "The user now sees a card, can untick items and decides. Nothing has been removed yet.",
        ]
        if !notFound.isEmpty { result["not_found"] = .array(notFound.map(JSONValue.string)) }
        return .object(result)
    }

    // MARK: - Summaries

    static func largeFilesSummary(_ files: [LargeFile], compact: Bool = false) -> JSONValue {
        let now = Date()
        let shown = files.prefix(compact ? 6 : 20)
        let list: [JSONValue] = shown.map { file in
            let days: JSONValue = file.lastActivity.map { .number(Double(Int(now.timeIntervalSince($0) / 86_400))) } ?? .null
            return .object([
                "name": .string(file.url.lastPathComponent),
                "folder": .string(FileText.folder(file.url)),
                "size_mb": .number(Double(file.sizeBytes / 1_000_000)),
                "kind": .string(file.kind.rawValue),
                "days_since_opened": days,
            ])
        }
        let total = files.reduce(0) { $0 + $1.sizeBytes }
        return .object([
            "count_over_50_mb": .number(Double(files.count)),
            "total_gb": .number((Double(total) / 1e8).rounded() / 10),
            "largest": .array(list),
        ])
    }

    static func installedApps(_ apps: [AppEntry], compact: Bool = false) -> JSONValue {
        let now = Date()
        func days(_ date: Date?) -> JSONValue {
            date.map { .number(Double(Int(now.timeIntervalSince($0) / 86_400))) } ?? .null
        }
        let limit = compact ? 5 : 12
        let largest = apps.filter { $0.sizeBytes != nil }.sorted { $0.sizeBytes! > $1.sizeBytes! }.prefix(limit)
        let unused = apps.filter { entry in
            entry.lastUsed.map { now.timeIntervalSince($0) > ApplicationsModel.unusedAfter } ?? false
        }
        let intel = apps.filter { $0.app.architecture == .intel }

        return [
            "count": .number(Double(apps.count)),
            "total_gb": .number((Double(apps.reduce(0) { $0 + ($1.sizeBytes ?? 0) }) / 1e8).rounded() / 10),
            "sizes_still_measuring": .bool(apps.contains { $0.sizeBytes == nil }),
            "largest": .array(largest.map { entry in
                [
                    "name": .string(entry.app.name),
                    "size_mb": .number(Double((entry.sizeBytes ?? 0) / 1_000_000)),
                    "days_since_used": days(entry.lastUsed),
                    "source": .string(entry.app.source.rawValue),
                ]
            }),
            "unused_90_days": .array(unused.prefix(limit).map { entry in
                ["name": .string(entry.app.name), "days_since_used": days(entry.lastUsed)]
            }),
            "intel_only": .array(intel.prefix(limit).map { .string($0.app.name) }),
            "note": "Last-used dates come from Spotlight and may be missing for some apps.",
        ]
    }

    private static func gib(_ bytes: UInt64) -> JSONValue {
        .number((Double(bytes) / 1_073_741_824 * 10).rounded() / 10)
    }

    private static func gb(_ bytes: Int64) -> JSONValue {
        .number((Double(bytes) / 1_000_000_000 * 10).rounded() / 10)
    }

    private static func percent(_ value: Double) -> JSONValue {
        .number((value * 100).rounded())
    }

    static func topApps(_ performance: PerformanceModel, compact: Bool = false) -> JSONValue {
        .array(performance.topApps.prefix(compact ? 5 : 8).map { app in
            ["app": .string(app.name), "memory_mb": .number(Double(app.footprintBytes / 1_048_576))]
        })
    }

    static func backgroundServices(_ performance: PerformanceModel, compact: Bool = false) -> JSONValue {
        let items = compact ? Array(performance.activeLaunchItems.prefix(12)) : performance.launchItems
        return .array(items.map { item in
            var entry: [String: JSONValue] = [
                "name": .string(item.displayName),
                // What propose_action takes.
                "label": .string(item.label),
                "scope": .string(item.scope.rawValue),
                "starts": .string(item.isDisabled ? "disabled" : item.keepsAlive ? "always" : item.runsAtLoad ? "at_login" : "on_demand"),
            ]
            if LaunchControl.refusal(for: item) != nil { entry["keel_can_change"] = false }
            if !compact {
                entry["program"] = item.program.map(JSONValue.string) ?? .null
            }
            return .object(entry)
        })
    }

    static func systemStatus(_ status: SystemStatus, compact: Bool = false) -> JSONValue {
        let info = status.info
        var result: [String: JSONValue] = [
            "chip": info.chipName.map(JSONValue.string) ?? .null,
            "model_identifier": info.modelIdentifier.map(JSONValue.string) ?? .null,
            "macos": .string(info.osVersion),
            "cores": [
                "logical": .number(Double(info.logicalCores)),
                "performance": info.performanceCores.map { .number(Double($0)) } ?? .null,
                "efficiency": info.efficiencyCores.map { .number(Double($0)) } ?? .null,
            ],
            "uptime_hours": .number((status.uptime / 3_600).rounded()),
            "thermal_state": .string(thermalName(status.thermalState)),
        ]

        if let memory = status.memory {
            var memoryInfo: [String: JSONValue] = [
                "total_gb": gib(memory.totalBytes),
                "used_gb": gib(memory.usedBytes),
                "pressure": .string("\(memory.pressure)"),
                "swap_used_gb": gib(memory.swapUsedBytes),
            ]
            if let parts = memory.breakdown {
                memoryInfo["app_gb"] = gib(parts.appBytes)
                memoryInfo["wired_gb"] = gib(parts.wiredBytes)
                memoryInfo["compressed_gb"] = gib(parts.compressedBytes)
                memoryInfo["cached_files_gb"] = gib(parts.cachedFilesBytes)
            }
            result["memory"] = .object(memoryInfo)
        }

        if let thermals = status.thermals {
            var sensors: [String: JSONValue] = [:]
            for summary in thermals.summaries {
                let reading: [String: JSONValue] = [
                    "hottest_c": .number(summary.hottest.rounded()),
                    "average_c": .number(summary.average.rounded()),
                ]
                sensors[summary.group.rawValue] = .object(reading)
            }
            result["temperatures"] = .object(sensors)
            if thermals.hasFans {
                let fans: [JSONValue] = thermals.fans.map { fan in
                    let maximum: JSONValue = fan.maximumRPM.map { JSONValue.number($0.rounded()) } ?? .null
                    return .object(["rpm": .number(fan.rpm.rounded()), "max_rpm": maximum])
                }
                result["fans"] = .array(fans)
            } else {
                result["fans"] = .string("none (fanless Mac)")
            }
        }

        var cpu: [String: JSONValue] = ["usage_percent": status.cpuUsage.map(percent) ?? .null]
        if let split = status.cpuSplit {
            cpu["user_percent"] = percent(split.user)
            cpu["system_percent"] = percent(split.system)
        }
        if let loads = status.loadAverages {
            cpu["load_average_1_5_15"] = .array(loads.map { .number(($0 * 10).rounded() / 10) })
        }
        if !compact, !status.perCoreUsage.isEmpty {
            cpu["per_core_percent"] = .array(status.perCoreUsage.map(percent))
        }
        result["cpu"] = .object(cpu)

        if let gpu = status.gpu {
            result["gpu"] = [
                "name": gpu.name.map(JSONValue.string) ?? .null,
                "cores": gpu.coreCount.map { .number(Double($0)) } ?? .null,
                "usage_percent": percent(gpu.utilization),
                "memory_in_use_gb": gpu.memoryInUseBytes.map(gib) ?? .null,
            ]
        }

        if let disk = status.disk {
            var diskInfo: [String: JSONValue] = [
                "total_gb": gb(disk.totalBytes),
                "free_gb": gb(disk.availableBytes),
                "used_percent": percent(disk.usedFraction),
            ]
            if let device = status.storageDevice {
                diskInfo["model"] = .string(device.model)
                diskInfo["solid_state"] = .bool(device.isSolidState)
            }
            if let rate = status.diskRate {
                diskInfo["read_mb_per_s"] = .number((rate.readPerSecond / 1_000_000).rounded())
                diskInfo["write_mb_per_s"] = .number((rate.writePerSecond / 1_000_000).rounded())
            }
            result["disk"] = .object(diskInfo)
        }

        if let battery = status.battery {
            result["battery"] = [
                "charge_percent": percent(battery.charge),
                "health_percent": battery.health.map(percent) ?? .null,
                "cycle_count": battery.cycleCount.map { .number(Double($0)) } ?? .null,
                "temperature_c": battery.temperatureCelsius.map { .number($0.rounded()) } ?? .null,
                "charging": .bool(battery.isCharging),
                "plugged_in": .bool(battery.isPluggedIn),
            ]
        }

        return .object(result)
    }

    static func cleanupSummary(_ results: [CategoryScanResult], appNames: [String: String], compact: Bool = false) -> JSONValue {
        .array(results.map { result in
            let skipped = Set(result.skipped.compactMap { item -> String? in
                if case .appRunning(let bundleID) = item.reason { appNames[bundleID] ?? bundleID } else { nil }
            })
            return [
                "id": .string(result.category.id.rawValue),
                "title": .string(result.category.title),
                "total_mb": .number(Double(result.totalBytes / 1_000_000)),
                "item_count": .number(Double(result.items.count)),
                "preselected": .bool(result.category.selectedByDefault),
                "removal": .string(result.category.removal == .deletePermanently ? "deleted_permanently" : "moved_to_trash"),
                "unreadable": .bool(result.items.isEmpty && !result.unreadableRoots.isEmpty),
                "skipped_because_running": .array(skipped.sorted().map(JSONValue.string)),
                // Largest first; these paths are what propose_cleanup accepts as items.
                "items": .array(result.items.prefix(compact ? 3 : 15).map { item in
                    ["path": .string(HomePath.display(item.url)), "size_mb": .number((Double(item.sizeBytes) / 100_000).rounded() / 10)]
                }),
                "more_items": .number(Double(max(result.items.count - (compact ? 3 : 15), 0))),
            ]
        })
    }

    private static func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }
}
