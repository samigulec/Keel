import KeelCore
import SwiftUI

struct SmartScanView: View {
    var openCleanup: () -> Void
    @Environment(SystemStatus.self) private var status
    @Environment(CleanupModel.self) private var cleanup

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            PageHeader(
                title: "Akıllı Tarama",
                subtitle: "Tek tıkla temizlik, hız ve güvenlik kontrolü"
            )

            hero

            HStack(alignment: .top, spacing: 16) {
                storageCard
                StatCard(
                    title: "Bellek (RAM)",
                    bytes: status.memory.map { Int64($0.usedBytes) },
                    detail: status.memory.map { memoryDetail($0) } ?? "Ölçülüyor…",
                    base: .binary
                )
                StatCard(
                    title: "Temizlenebilir",
                    bytes: cleanup.lastScan == nil ? nil : cleanup.recommendedBytes,
                    detail: cleanup.lastScan == nil ? "Taramadan sonra hesaplanır" : "Önerilen kategoriler",
                    isDark: true
                )
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 40) {
            ZStack {
                Circle().stroke(Palette.track, lineWidth: 16)
                if cleanup.phase == .scanning {
                    ProgressView().controlSize(.large)
                } else {
                    Image(systemName: cleanup.lastScan == nil ? "magnifyingglass" : "checkmark")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Palette.keelGreen)
                }
            }
            .frame(width: 180, height: 180)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                statePill
                Text(headline)
                    .font(.keel(26, .extraBold))
                    .tracking(-0.4)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.keel(15, .medium))
                    .foregroundStyle(Palette.slate)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    if cleanup.lastScan != nil, cleanup.phase != .scanning {
                        Button("Sonuçları gör", action: openCleanup)
                            .buttonStyle(.keelPrimary)
                        Button("Yeniden tara", action: cleanup.scan)
                            .buttonStyle(.keelSecondary)
                            .disabled(cleanup.isBusy)
                    } else {
                        Button(action: cleanup.scan) {
                            Label(cleanup.phase == .scanning ? "Taranıyor…" : "Taramayı başlat", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.keelPrimary)
                        .disabled(cleanup.isBusy)

                        Button("Temizliğe git", action: openCleanup)
                            .buttonStyle(.keelSecondary)
                    }
                }
                .padding(.top, 6)
            }
        }
        .keelCard(padding: 36, radius: 24)
    }

    @ViewBuilder
    private var statePill: some View {
        if cleanup.phase == .scanning {
            Pill(text: "Taranıyor…", background: Palette.track, foreground: Palette.slate)
        } else if let lastScan = cleanup.lastScan {
            Pill(text: "Son tarama: \(lastScan.formatted(date: .omitted, time: .shortened))")
        } else {
            Pill(text: "Henüz taranmadı", background: Palette.track, foreground: Palette.slate)
        }
    }

    private var headline: String {
        guard cleanup.lastScan != nil else {
            return "Bilgisayarını tarayıp neyin yer kapladığını ve neyin güvenle temizlenebileceğini göstereceğiz."
        }
        guard cleanup.totalBytes > 0 else {
            return "Her şey temiz görünüyor. Temizlenecek bir şey bulunamadı."
        }
        guard cleanup.recommendedBytes > 0 else {
            return "Önerilen kategoriler temiz. Gözden geçirmen gereken \(ByteFormat.string(cleanup.optInBytes)) var."
        }
        return "\(ByteFormat.string(cleanup.recommendedBytes)) güvenle temizlenebilir."
    }

    private var detail: String {
        let safety = "Hiçbir şey sen onaylamadan silinmez; silinenler Çöp Kutusu'na taşınır, oradan geri alabilirsin."
        guard cleanup.lastScan != nil, cleanup.optInBytes > 0 else {
            return "Tarama yalnızca okur. " + safety
        }
        // Joined by hand: the system list formatter follows the Mac's language, not the app's.
        let titles = cleanup.optInTitles
        let places = titles.count > 1
            ? titles.dropLast().joined(separator: ", ") + " ve " + titles[titles.count - 1]
            : titles.first ?? ""
        return "Ayrıca \(places) içinde \(ByteFormat.string(cleanup.optInBytes)) var; bunları Temizlik'te kendin seçebilirsin. " + safety
    }

    private func memoryDetail(_ memory: MemorySnapshot) -> String {
        let total = ByteFormat.string(Int64(memory.totalBytes), base: .binary)
        let pressure = switch memory.pressure {
        case .normal: "normal"
        case .warning: "yüksek"
        case .critical: "kritik"
        }
        return "\(total) içinden · baskı \(pressure)"
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Depolama").eyebrowStyle()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                ByteAmount(bytes: status.disk?.availableBytes, size: 26)
                Text("boş")
                    .font(.keel(15, .semibold))
                    .foregroundStyle(Palette.slate)
            }
            ProgressBar(fraction: status.disk?.usedFraction ?? 0)
        }
        .keelCard(padding: 22)
    }
}

private struct StatCard: View {
    var title: String
    var bytes: Int64?
    var detail: String
    var base: ByteFormat.Base = .decimal
    var isDark = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).eyebrowStyle(color: isDark ? Palette.Sidebar.eyebrow : Palette.slate)
            ByteAmount(bytes: bytes, size: 26, base: base)
            Text(detail)
                .font(.keel(13, .medium))
                .foregroundStyle(isDark ? Palette.Sidebar.text : Palette.slate)
        }
        .modifier(StatCardSurface(isHighlighted: isDark))
    }
}

/// The highlighted stat sits on the summary gradient; the others are glass.
private struct StatCardSurface: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        if isHighlighted {
            content.keelSummaryCard(padding: 22)
        } else {
            content.keelCard(padding: 22)
        }
    }
}
