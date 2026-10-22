import Foundation
import KeelCore

/// A cleanup Keel AI suggested. Nothing happens until the user confirms it.
struct CleanupProposal: Identifiable, Equatable {
    let id = UUID()
    let categories: [CleanupCategoryID]
    let reason: String
    let bytes: Int64
    let titles: [String]
}

/// The tools Keel AI may call. They read the Mac's state through the same
/// models the screens use; none of them changes anything on disk.
@MainActor
enum KeelTools {
    static let displayNames: [String: String] = [
        "get_system_status": "Sistem durumu",
        "scan_cleanable_space": "Temizlenebilir alan taraması",
        "get_top_memory_apps": "Uygulamaların bellek kullanımı",
        "get_background_services": "Arka plan servisleri",
        "propose_cleanup": "Temizlik önerisi",
    ]

    /// `compact` trims tool output for models with a small context window,
    /// such as Apple's on-device model.
    static func make(
        status: SystemStatus,
        cleanup: CleanupModel,
        performance: PerformanceModel,
        compact: Bool = false,
        propose: @escaping @MainActor (CleanupProposal) -> Void
    ) -> [AITool] {
        let noInput: JSONValue = ["type": "object", "properties": [:], "additionalProperties": false]

        return [
            AITool(
                name: "get_system_status",
                description: "Reads the Mac's current state: chip, CPU load per core, GPU load, memory use and pressure with its breakdown and swap, disk space and throughput, battery health, temperature state and uptime. Call this whenever the user asks why the Mac is slow, hot, loud or low on space, or about memory, CPU, GPU, battery or storage.",
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
                name: "get_background_services",
                description: "Lists launchd agents and daemons that start on their own (at login or kept running), with their owner and program path. Call this when the user asks what runs in the background or why startup is slow. Keel cannot turn these off; point the user to System Settings > General > Login Items if they want to.",
                inputSchema: noInput
            ) { _ in
                await performance.refreshLaunchItems()
                return backgroundServices(performance, compact: compact).encodedString()
            },

            AITool(
                name: "propose_cleanup",
                description: "Shows the user a cleanup card for the given categories with a button to confirm. Nothing is removed unless the user presses it, so never say that something was cleaned. Call scan_cleanable_space first; only categories with items in the latest scan can be proposed. Prefer the preselected categories; propose 'trash' (deleted permanently) or 'oldDownloads' (personal files) only when the user clearly wants that.",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "categories": [
                            "type": "array",
                            "items": ["type": "string", "enum": .array(CleanupCategoryID.allCases.map { .string($0.rawValue) })],
                            "description": "Category ids from scan_cleanable_space.",
                        ],
                        "reason": ["type": "string", "description": "One sentence for the user on why this helps."],
                    ],
                    "required": ["categories", "reason"],
                    "additionalProperties": false,
                ]
            ) { input in
                let requested = (input["categories"]?.arrayValue ?? []).compactMap { $0.stringValue.flatMap(CleanupCategoryID.init(rawValue:)) }
                let available = cleanup.results.filter { requested.contains($0.category.id) && !$0.items.isEmpty }
                guard !available.isEmpty else {
                    return #"{"shown":false,"reason":"Nothing to clean in those categories. Run scan_cleanable_space first."}"#
                }
                let proposal = CleanupProposal(
                    categories: available.map(\.category.id),
                    reason: input["reason"]?.stringValue ?? "",
                    bytes: available.reduce(0) { $0 + $1.totalBytes },
                    titles: available.map(\.category.title)
                )
                propose(proposal)
                let result: JSONValue = [
                    "shown": true,
                    "total": .string(ByteFormat.string(proposal.bytes)),
                    "note": "The user now sees a card and decides. Nothing has been removed yet.",
                ]
                return result.encodedString()
            },
        ]
    }

    // MARK: - Summaries

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
                "scope": .string(item.scope.rawValue),
                "starts": .string(item.isDisabled ? "disabled" : item.keepsAlive ? "always" : item.runsAtLoad ? "at_login" : "on_demand"),
            ]
            if !compact {
                entry["label"] = .string(item.label)
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
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return .array(results.map { result in
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
                "largest_items": .array(result.items.prefix(compact ? 2 : 5).map { item in
                    let path = item.url.path.hasPrefix(home) ? "~" + item.url.path.dropFirst(home.count) : item.url.path
                    return ["path": .string(path), "size_mb": .number(Double(item.sizeBytes / 1_000_000))]
                }),
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
