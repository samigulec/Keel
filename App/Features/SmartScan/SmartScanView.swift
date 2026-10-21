import KeelCore
import SwiftUI

struct SmartScanView: View {
    var openCleanup: () -> Void
    @Environment(SystemStatus.self) private var status

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
                StatCard(title: "Temizlenebilir", value: "—", detail: "Taramadan sonra hesaplanır", isDark: true)
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 40) {
            ZStack {
                Circle().stroke(Palette.track, lineWidth: 16)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Palette.keelGreen)
            }
            .frame(width: 180, height: 180)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                Pill(text: "Henüz taranmadı", background: Palette.track, foreground: Palette.slate)
                Text("Bilgisayarını tarayıp neyin yer kapladığını ve neyin güvenle temizlenebileceğini göstereceğiz.")
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
                    Button {} label: {
                        Label("Taramayı başlat", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.keelPrimary)
                    .disabled(true)
                    .help("Tarama motoru Faz 1'de geliyor")

                    Button("Temizliğe git", action: openCleanup)
                        .buttonStyle(.keelSecondary)
                }
                .padding(.top, 6)
            }
        }
        .keelCard(padding: 36, radius: 24)
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Depolama").eyebrowStyle()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(status.disk.map { ByteFormat.string($0.availableBytes) } ?? "—")
                    .font(.keelMono(26, .semibold))
                    .foregroundStyle(Palette.hull)
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
