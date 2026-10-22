import KeelCore
import SwiftUI

struct PerformanceView: View {
    @Environment(SystemStatus.self) private var status
    @Environment(PerformanceModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: "Performans",
                subtitle: "İşlemci, GPU, bellek ve SSD'nin anlık durumu."
            )

            SystemOverview(status: status)

            Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    CPULiveCard(status: status)
                    GPULiveCard(gpu: status.gpu, history: status.gpuHistory)
                }
                GridRow {
                    MemoryLiveCard(memory: status.memory)
                    DiskLiveCard(rate: status.diskRate, readHistory: status.diskReadHistory, writeHistory: status.diskWriteHistory)
                }
                GridRow {
                    MemoryBreakdownCard(memory: status.memory)
                    CoresCard(usage: status.perCoreUsage, info: status.info)
                }
                GridRow {
                    StorageCard(device: status.storageDevice, disk: status.disk, totals: status.diskTotals)
                    if let battery = status.battery {
                        BatteryCard(battery: battery)
                    } else {
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                }
            }

            HStack(alignment: .top, spacing: 16) {
                TopAppsCard(apps: model.topApps)
                LaunchItemsCard(
                    items: model.launchItems,
                    activeCount: model.activeLaunchItems.count,
                    loaded: model.launchItemsLoaded
                ) {
                    Task { await model.refreshLaunchItems() }
                }
            }
        }
        .task {
            await model.refreshLaunchItems()
        }
        .task {
            // Per-app memory is only worth measuring while someone is looking.
            while !Task.isCancelled {
                await model.refreshApps()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
}

// MARK: - Shared pieces

/// A card that fills its grid cell, so cards in a row share one height.
private struct PanelCard<Content: View>: View {
    var fill: Color = Palette.card
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            if fill == Palette.card {
                RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border)
            }
        }
    }
}

private struct CardTitle: View {
    let title: String
    var status: String?
    var statusColor: Color = Palette.mintText

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).eyebrowStyle()
            Spacer()
            if let status {
                Text(status)
                    .font(.keel(13, .bold))
                    .foregroundStyle(statusColor)
            }
        }
    }
}

private struct BigNumber: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.keelMono(30, .semibold))
            .tracking(-1.8)
            .foregroundStyle(Palette.text)
    }
}

/// Bars over a faint track, so the chart reads even when values are low.
private struct Sparkline: View {
    let values: [Double]
    /// The value that fills a bar; nil scales to the largest value shown.
    var maxValue: Double? = 1
    var tint: Color = Palette.keelGreen

    var body: some View {
        let padded = Array(repeating: 0.0, count: max(SystemStatus.historyLength - values.count, 0)) + values
        let scale = maxValue ?? max(padded.max() ?? 0, 1)
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(padded.enumerated()), id: \.offset) { index, value in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Palette.track.opacity(0.6))
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(index == padded.count - 1 ? tint : tint.opacity(0.45))
                            .frame(height: max(2, proxy.size.height * min(value / scale, 1)))
                    }
                }
            }
        }
        .frame(height: 56)
        .accessibilityHidden(true)
    }
}

private struct LegendRow: View {
    let color: Color
    let title: String
    var detail: String?
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.keel(14, .semibold))
                    .foregroundStyle(Palette.text)
                if let detail {
                    Text(detail)
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.keelMono(13, .semibold))
                .foregroundStyle(Palette.text)
        }
    }
}

private enum Format {
    static func percent(_ value: Double) -> String {
        "%\(Int((value * 100).rounded()))"
    }

    static func memory(_ bytes: UInt64) -> String {
        ByteFormat.string(Int64(clamping: bytes), base: .binary)
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        bytesPerSecond < 1_000 ? "0 MB/sn" : ByteFormat.string(Int64(bytesPerSecond)) + "/sn"
    }

    static func uptime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let days = minutes / 1_440
        let hours = (minutes % 1_440) / 60
        if days > 0 { return "\(days) gün \(hours) sa" }
        if hours > 0 { return "\(hours) sa \(minutes % 60) dk" }
        return "\(minutes) dk"
    }

    static func thermal(_ state: ProcessInfo.ThermalState) -> (String, Color) {
        switch state {
        case .nominal: ("Normal", Palette.mintText)
        case .fair: ("Ilık", Palette.mintText)
        case .serious: ("Sıcak", Palette.warningText)
        case .critical: ("Çok sıcak", Palette.danger)
        @unknown default: ("Bilinmiyor", Palette.slate)
        }
    }

    static func pressure(_ pressure: MemorySnapshot.Pressure) -> (String, Color) {
        switch pressure {
        case .normal: ("Baskı: Normal", Palette.mintText)
        case .warning: ("Baskı: Yüksek", Palette.warningText)
        case .critical: ("Baskı: Kritik", Palette.danger)
        }
    }
}

// MARK: - Overview

private struct SystemOverview: View {
    let status: SystemStatus

    var body: some View {
        let thermal = Format.thermal(status.thermalState)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 28) { facts(thermal: thermal) }
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 28) { facts(thermal: thermal).prefix }
                HStack(spacing: 28) { facts(thermal: thermal).suffix }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .keelSummaryCard(padding: 0, radius: 24)
    }

    private func facts(thermal: (String, Color)) -> FactList {
        let info = status.info
        var cores = "\(info.logicalCores) çekirdek"
        if let performance = info.performanceCores, let efficiency = info.efficiencyCores {
            cores = "\(performance)P + \(efficiency)E çekirdek"
        }
        var gpu = "—"
        if let count = status.gpu?.coreCount {
            gpu = "\(count) çekirdek"
        }
        return FactList(items: [
            ("Çip", info.chipName ?? info.modelIdentifier ?? "—", nil),
            ("İşlemci", cores, nil),
            ("GPU", gpu, nil),
            ("Bellek", Format.memory(info.physicalMemoryBytes), nil),
            ("Açık kalma", Format.uptime(status.uptime), nil),
            ("Isı", thermal.0, thermal.1),
        ])
    }
}

/// The overview facts, splittable into two lines on narrow windows.
private struct FactList: View {
    let items: [(String, String, Color?)]

    var body: some View {
        ForEach(items, id: \.0) { item in
            Fact(title: item.0, value: item.1, valueColor: item.2)
        }
    }

    var prefix: FactList { FactList(items: Array(items.prefix(3))) }
    var suffix: FactList { FactList(items: Array(items.dropFirst(3))) }
}

private struct Fact: View {
    let title: String
    let value: String
    var valueColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).eyebrowStyle(color: Palette.Sidebar.eyebrow)
            Text(value)
                .font(.keel(15, .bold))
                .foregroundStyle(valueColor.map { $0 == Palette.mintText ? Palette.keelGreen : $0 } ?? .white)
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Live cards

private struct CPULiveCard: View {
    let status: SystemStatus

    var body: some View {
        PanelCard {
            let usage = status.cpuUsage
            CardTitle(
                title: "İşlemci",
                status: usage.map { $0 > 0.8 ? "Yoğun" : "Normal" },
                statusColor: (usage ?? 0) > 0.8 ? Palette.warningText : Palette.mintText
            )
            BigNumber(text: usage.map(Format.percent) ?? "—")
            Sparkline(values: status.cpuHistory)
            HStack {
                if let split = status.cpuSplit {
                    Text("Kullanıcı \(Format.percent(split.user)) · Sistem \(Format.percent(split.system))")
                }
                Spacer()
                if let loads = status.loadAverages {
                    Text("Yük " + loads.map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: ",") }.joined(separator: " · "))
                        .help("1, 5 ve 15 dakikalık yük ortalaması: çalışmayı bekleyen iş sayısı")
                }
            }
            .font(.keel(12, .semibold))
            .foregroundStyle(Palette.slate)
        }
    }
}

private struct GPULiveCard: View {
    let gpu: GPUSnapshot?
    let history: [Double]

    var body: some View {
        PanelCard {
            CardTitle(title: "GPU", status: gpu?.name)
            BigNumber(text: gpu.map { Format.percent($0.utilization) } ?? "—")
            Sparkline(values: history, tint: Color(hex: 0x4C8DF6))
            Text(detail)
                .font(.keel(12, .semibold))
                .foregroundStyle(Palette.slate)
        }
    }

    private var detail: String {
        guard let gpu else { return "GPU verisi okunamadı" }
        guard let memory = gpu.memoryInUseBytes else { return "Anlık kullanım" }
        return "Kullandığı bellek \(Format.memory(memory))"
    }
}

private struct MemoryLiveCard: View {
    let memory: MemorySnapshot?

    var body: some View {
        PanelCard {
            let pressure = memory.map { Format.pressure($0.pressure) }
            CardTitle(title: "Bellek", status: pressure?.0, statusColor: pressure?.1 ?? Palette.mintText)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                ByteAmount(bytes: memory.map { Int64($0.usedBytes) }, size: 30, base: .binary)
                if let memory {
                    Text("/ \(Format.memory(memory.totalBytes))")
                        .font(.keel(14, .semibold))
                        .foregroundStyle(Palette.slate)
                }
            }
            MemoryBar(memory: memory)
            Text(swapText)
                .font(.keel(12, .semibold))
                .foregroundStyle(Palette.slate)
        }
    }

    private var swapText: String {
        guard let memory else { return "Ölçülüyor…" }
        return memory.swapUsedBytes > 0
            ? "Swap kullanımı \(Format.memory(memory.swapUsedBytes)): bellek yetmeyince diske taşan kısım"
            : "Swap kullanılmıyor"
    }
}

/// Stacked bar: app, wired, compressed and cached memory out of the total.
private struct MemoryBar: View {
    let memory: MemorySnapshot?

    static let appColor = Palette.keelGreen
    static let wiredColor = Color(hex: 0x1BA7D6)
    static let compressedColor = Color(hex: 0xF0782F)
    static let cachedColor = Color.white.opacity(0.35)

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: max(0, proxy.size.width * segment.fraction - 2))
                }
                Spacer(minLength: 0)
            }
            .background(Palette.track)
            .clipShape(Capsule())
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }

    private var segments: [(color: Color, fraction: Double)] {
        guard let memory, memory.totalBytes > 0 else { return [] }
        let total = Double(memory.totalBytes)
        guard let parts = memory.breakdown else {
            return [(Self.appColor, memory.usedFraction)]
        }
        return [
            (Self.appColor, Double(parts.appBytes) / total),
            (Self.wiredColor, Double(parts.wiredBytes) / total),
            (Self.compressedColor, Double(parts.compressedBytes) / total),
            (Self.cachedColor, Double(parts.cachedFilesBytes) / total),
        ]
    }
}

private struct DiskLiveCard: View {
    let rate: DiskIORate?
    let readHistory: [Double]
    let writeHistory: [Double]

    private static let readColor = Palette.keelGreen
    private static let writeColor = Color(hex: 0x4C8DF6)

    var body: some View {
        PanelCard {
            CardTitle(title: "Disk etkinliği")
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                speed("Okuma", rate?.readPerSecond, color: Self.readColor)
                speed("Yazma", rate?.writePerSecond, color: Self.writeColor)
            }
            // Shared scale, so read and write bars compare honestly.
            let scale = max((readHistory + writeHistory).max() ?? 0, 1_000_000)
            VStack(spacing: 4) {
                Sparkline(values: readHistory, maxValue: scale, tint: Self.readColor)
                Sparkline(values: writeHistory, maxValue: scale, tint: Self.writeColor)
            }
        }
    }

    private func speed(_ title: String, _ value: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title)
                    .font(.keel(12, .bold))
                    .foregroundStyle(Palette.slate)
            }
            Text(value.map(Format.speed) ?? "—")
                .font(.keelMono(20, .semibold))
                .tracking(-1)
                .foregroundStyle(Palette.text)
        }
    }
}

// MARK: - Detail cards

private struct MemoryBreakdownCard: View {
    let memory: MemorySnapshot?

    var body: some View {
        PanelCard {
            CardTitle(title: "Bellek dağılımı")
            if let memory, let parts = memory.breakdown {
                let free = memory.totalBytes
                    - min(memory.totalBytes, parts.appBytes + parts.wiredBytes + parts.compressedBytes + parts.cachedFilesBytes)
                LegendRow(color: MemoryBar.appColor, title: "Uygulama belleği", value: Format.memory(parts.appBytes))
                LegendRow(color: MemoryBar.wiredColor, title: "Kablolu (wired)", detail: "Sistemin ayırdığı, boşaltılamaz", value: Format.memory(parts.wiredBytes))
                LegendRow(color: MemoryBar.compressedColor, title: "Sıkıştırılmış", detail: "Yer açmak için sıkıştırılan bellek", value: Format.memory(parts.compressedBytes))
                LegendRow(color: MemoryBar.cachedColor, title: "Önbellek dosyaları", detail: "Uygulamalar isteyince hemen boşalır", value: Format.memory(parts.cachedFilesBytes))
                LegendRow(color: Palette.track, title: "Boş", value: Format.memory(free))
            } else {
                Text("Ayrıntılı dağılım bu sistemde okunamıyor.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
            }
        }
    }
}

private struct CoresCard: View {
    let usage: [Double]
    let info: SystemInfo

    var body: some View {
        PanelCard {
            CardTitle(title: "Çekirdekler", status: layout)
            if usage.isEmpty {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(usage.enumerated()), id: \.offset) { index, value in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Palette.track)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(value > 0.8 ? Palette.warning : Palette.keelGreen)
                                    .frame(height: max(3, 120 * value))
                            }
                            .frame(height: 120)
                            Text("\(index + 1)")
                                .font(.keelMono(11, .medium))
                                .foregroundStyle(Palette.slate)
                        }
                        .frame(maxWidth: .infinity)
                        .help("Çekirdek \(index + 1): \(Format.percent(value))")
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Çekirdek kullanımı")
                .accessibilityValue(usage.map(Format.percent).joined(separator: ", "))
            }
        }
    }

    private var layout: String? {
        guard let performance = info.performanceCores, let efficiency = info.efficiencyCores else { return nil }
        return "\(performance) performans + \(efficiency) verimlilik"
    }
}

private struct StorageCard: View {
    let device: StorageDevice?
    let disk: DiskSpace?
    let totals: DiskIOTotals?

    var body: some View {
        PanelCard {
            CardTitle(title: "SSD", status: device.map { $0.isInternal ? "Dahili" : "Harici" })
            Text(device?.model ?? "Başlangıç diski")
                .font(.keel(18, .extraBold))
                .foregroundStyle(Palette.text)
            if let interconnect = device?.interconnect {
                Text("Bağlantı: \(interconnect)")
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
            }
            if let disk {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    ByteAmount(bytes: disk.usedBytes, size: 20)
                    Text("/ \(ByteFormat.string(disk.totalBytes)) dolu")
                        .font(.keel(13, .semibold))
                        .foregroundStyle(Palette.slate)
                }
                ProgressBar(fraction: disk.usedFraction, tint: disk.usedFraction > 0.9 ? Palette.warning : nil)
            }
            if let totals {
                Text("Açılıştan beri \(ByteFormat.string(Int64(clamping: totals.readBytes))) okundu, \(ByteFormat.string(Int64(clamping: totals.writtenBytes))) yazıldı")
                    .font(.keel(12, .semibold))
                    .foregroundStyle(Palette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct BatteryCard: View {
    let battery: BatterySnapshot

    var body: some View {
        PanelCard {
            CardTitle(title: "Pil", status: state)
            BigNumber(text: Format.percent(battery.charge))
            ProgressBar(fraction: battery.charge, tint: battery.charge < 0.2 ? Palette.warning : Palette.keelGreen)
            VStack(spacing: 10) {
                if let health = battery.health {
                    LegendRow(
                        color: health < 0.8 ? Palette.warning : Palette.keelGreen,
                        title: "Pil sağlığı",
                        detail: health < 0.8 ? "Apple %80'in altını servis önerisi sayar" : "Tasarım kapasitesine göre",
                        value: Format.percent(health)
                    )
                }
                if let cycles = battery.cycleCount {
                    LegendRow(color: Palette.track, title: "Şarj döngüsü", value: "\(cycles)")
                }
                if let temperature = battery.temperatureCelsius {
                    LegendRow(color: Palette.track, title: "Sıcaklık", value: String(format: "%.0f °C", temperature))
                }
            }
        }
    }

    private var state: String {
        if battery.isCharging { return "Şarj oluyor" }
        return battery.isPluggedIn ? "Prize takılı" : "Pilde"
    }
}

// MARK: - Lists

private struct TopAppsCard: View {
    let apps: [AppMemoryUsage]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "En çok bellek kullananlar", detail: "Yardımcı süreçler dahil")
            if apps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(apps) { app in
                    HStack(spacing: 14) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .accessibilityHidden(true)
                        }
                        Text(app.name)
                            .font(.keel(15, .semibold))
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                        Spacer(minLength: 12)
                        ByteAmount(bytes: Int64(clamping: app.footprintBytes), size: 14, base: .binary)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: 48)
                    .overlay(alignment: .top) { Divider().overlay(Palette.divider) }
                }
            }
        }
        .padding(.bottom, 8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
    }
}

private struct LaunchItemsCard: View {
    let items: [LaunchItem]
    let activeCount: Int
    let loaded: Bool
    let reload: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "Arka plan servisleri", detail: "\(activeCount) tanesi kendiliğinden başlıyor") {
                Button("Yenile", action: reload)
                    .buttonStyle(.plain)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.mintText)
            }
            if !loaded {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if items.isEmpty {
                Text("Kendiliğinden başlayan servis bulunamadı.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
                    .padding(24)
            } else {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.keel(15, .semibold))
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                            Text(scopeText(item.scope))
                                .font(.keel(12, .medium))
                                .foregroundStyle(Palette.slate)
                        }
                        Spacer(minLength: 12)
                        Pill(
                            text: stateText(item),
                            background: item.isDisabled ? Palette.track : Palette.mint,
                            foreground: item.isDisabled ? Palette.slate : Palette.mintText
                        )
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: 52)
                    .overlay(alignment: .top) { Divider().overlay(Palette.divider) }
                    .help(item.program ?? item.url.path)
                }
            }
            Button("Uygulamaların açılış ayarları", action: PerformanceModel.openLoginItemsSettings)
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.mintText)
                .padding(.horizontal, 24)
                .frame(minHeight: 44)
        }
        .padding(.bottom, 8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
    }

    private func scopeText(_ scope: LaunchItem.Scope) -> String {
        switch scope {
        case .user: "Senin hesabın"
        case .allUsers: "Tüm kullanıcılar"
        case .system: "Sistem (yönetici)"
        }
    }

    private func stateText(_ item: LaunchItem) -> String {
        if item.isDisabled { return "Kapalı" }
        if item.keepsAlive { return "Sürekli" }
        if item.runsAtLoad { return "Açılışta" }
        return "Gerektiğinde"
    }
}

private struct ListHeader<Accessory: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.keel(18, .extraBold))
                .foregroundStyle(Palette.text)
            Text(detail)
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
            Spacer()
            accessory
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

extension ListHeader where Accessory == EmptyView {
    init(title: String, detail: String) {
        self.init(title: title, detail: detail) { EmptyView() }
    }
}
