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
                StatCard(title: "Bellek (RAM)", value: "—", detail: "Faz 1'de canlı gösterilecek")
                StatCard(
                    title: "Temizlenebilir",
                    value: cleanup.lastScan == nil ? "—" : ByteFormat.string(cleanup.totalBytes),
                    detail: cleanup.lastScan == nil ? "Taramadan sonra hesaplanır" : "Ayrıntılar Temizlik'te",
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
                    .foregroundStyle(Palette.hull)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tarama yalnızca okur. Hiçbir şey sen onaylamadan silinmez; silinenler Çöp Kutusu'na taşınır, oradan geri alabilirsin.")
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
        return "\(ByteFormat.string(cleanup.totalBytes)) temizlenebilir alan bulundu."
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
    var value: String
    var detail: String
    var isDark = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).eyebrowStyle(color: isDark ? Palette.Sidebar.eyebrow : Palette.slate)
            Text(value)
                .font(.keelMono(26, .semibold))
                .foregroundStyle(isDark ? .white : Palette.hull)
            Text(detail)
                .font(.keel(13, .medium))
                .foregroundStyle(isDark ? Palette.Sidebar.text : Palette.slate)
        }
        .keelCard(padding: 22, fill: isDark ? Palette.hull : Palette.card)
    }
}
