import KeelCore
import SwiftUI

struct PerformanceView: View {
    @Environment(SystemStatus.self) private var status
    @Environment(PerformanceModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: "Performans",
                subtitle: "Bellek baskısını, işlemciyi ve kendiliğinden başlayan servisleri izle."
            )

            HStack(alignment: .top, spacing: 16) {
                MemoryCard(memory: status.memory)
                CPUCard(usage: status.cpuUsage, history: status.cpuHistory)
                StartupSummaryCard(
                    count: model.launchItemsLoaded ? model.activeLaunchItems.count : nil
                )
            }

            HStack(alignment: .top, spacing: 24) {
                TopAppsCard(apps: model.topApps)
                LaunchItemsCard(items: model.launchItems, loaded: model.launchItemsLoaded) {
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

// MARK: - Live cards

private struct MemoryCard: View {
    let memory: MemorySnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bellek").eyebrowStyle()
                Spacer()
                if let memory {
                    Text(pressureLabel(memory.pressure))
                        .font(.keel(13, .bold))
                        .foregroundStyle(pressureColor(memory.pressure, text: true))
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                ByteAmount(bytes: memory.map { Int64($0.usedBytes) }, size: 30, base: .binary)
                if let memory {
                    Text("/ \(ByteFormat.string(Int64(memory.totalBytes), base: .binary))")
                        .font(.keel(14, .semibold))
                        .foregroundStyle(Palette.slate)
                }
            }
            ProgressBar(
                fraction: memory?.usedFraction ?? 0,
                tint: memory.map { pressureColor($0.pressure, text: false) } ?? Palette.track,
                height: 10
            )
            Text("macOS boş belleği önbellek olarak kullanır. Asıl önemli olan bellek baskısıdır.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .keelCard(padding: 24, radius: 20)
    }

    private func pressureLabel(_ pressure: MemorySnapshot.Pressure) -> String {
        switch pressure {
        case .normal: "Baskı: Normal"
        case .warning: "Baskı: Yüksek"
        case .critical: "Baskı: Kritik"
        }
    }

    private func pressureColor(_ pressure: MemorySnapshot.Pressure, text: Bool) -> Color {
        switch pressure {
        case .normal: text ? Palette.mintText : Palette.keelGreen
        case .warning: text ? Palette.warningText : Palette.warning
        case .critical: Palette.danger
        }
    }
}

private struct CPUCard: View {
    let usage: Double?
    let history: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("İşlemci").eyebrowStyle()
                Spacer()
                if let usage {
                    Text(usage > 0.8 ? "Yoğun" : "Normal")
                        .font(.keel(13, .bold))
                        .foregroundStyle(usage > 0.8 ? Palette.warningText : Palette.mintText)
                }
            }
            Text(usage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—")
                .font(.keelMono(30, .semibold))
                .tracking(-1.8)
                .foregroundStyle(Palette.hull)
            Sparkline(values: history)
                .frame(height: 52)
        }
        .keelCard(padding: 24, radius: 20)
    }
}

/// Bars for recent CPU readings; the latest one is highlighted.
private struct Sparkline: View {
    let values: [Double]

    var body: some View {
        let padded = Array(repeating: 0.0, count: max(SystemStatus.historyLength - values.count, 0)) + values
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(padded.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(index == padded.count - 1 ? Palette.keelGreen : Color(hex: 0xCFE7DD))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(2, 52 * value))
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

private struct StartupSummaryCard: View {
    let count: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kendiliğinden başlayan").eyebrowStyle(color: Palette.Sidebar.eyebrow)
            Text(count.map(String.init) ?? "—")
                .font(.keelMono(30, .semibold))
                .foregroundStyle(.white)
            Text("Açılışta ya da arka planda kendiliğinden çalışan servis. Uygulamaların açılış ayarları Sistem Ayarları'nda.")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.Sidebar.text)
                .fixedSize(horizontal: false, vertical: true)
            Button("Sistem Ayarları'nda yönet", action: PerformanceModel.openLoginItemsSettings)
                .buttonStyle(.plain)
                .font(.keel(14, .bold))
                .foregroundStyle(Palette.keelGreen)
                .frame(minHeight: 44)
        }
        .keelCard(padding: 24, radius: 20, fill: Palette.hull)
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
                            .foregroundStyle(Palette.hull)
                            .lineLimit(1)
                        Spacer(minLength: 12)
                        ByteAmount(bytes: Int64(app.footprintBytes), size: 14, base: .binary)
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
    let loaded: Bool
    let reload: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "Arka plan servisleri", detail: "\(items.count) öğe") {
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
                                .foregroundStyle(Palette.hull)
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
                .foregroundStyle(Palette.hull)
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
