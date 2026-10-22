import SwiftUI

/// Placeholder for sections that are designed but not built yet. It states
/// what the section will do so the roadmap is visible inside the app.
struct ComingSoonView: View {
    let section: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            PageHeader(title: section.title, subtitle: subtitle)

            VStack(alignment: .leading, spacing: 16) {
                Pill(text: "Faz \(section.phase)")
                Text("Neler gelecek")
                    .font(.keel(18, .extraBold))
                    .foregroundStyle(Palette.text)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(plannedFeatures, id: \.self) { feature in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(Palette.mintText)
                            Text(feature)
                                .font(.keel(15, .medium))
                                .foregroundStyle(Palette.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .keelCard(padding: 28, radius: 20)
        }
    }

    private var subtitle: String {
        switch section {
        case .smartScan: "Tek tıkla temizlik, hız ve güvenlik kontrolü"
        case .cleanup: "Silmek istediğin kategorileri seç. Silinenler Çöp Kutusu'na taşınır."
        case .performance: "Bellek baskısını, işlemciyi ve açılış öğelerini izle."
        case .applications: "Uygulamaları artık dosyalarıyla birlikte kaldır."
        case .assistant: "Bilgisayarın hakkında soru sor; Keel analiz edip öneri sunar."
        }
    }

    private var plannedFeatures: [String] {
        switch section {
        case .smartScan:
            []
        case .cleanup:
            [
                "Kullanıcı önbellekleri ve eski günlük dosyaları",
                "Çöp Kutusu ve eski indirmeler",
                "Tarayıcı önbellekleri (tarayıcı kapalıyken)",
                "Xcode DerivedData ve Simulator önbellekleri",
                "Seç, onayla, Çöp Kutusu'na taşı. Kalıcı silme yok",
            ]
        case .performance:
            [
                "Canlı işlemci ve bellek baskısı",
                "En çok kaynak tüketen uygulamalar",
                "Açılış öğeleri listesi",
            ]
        case .applications:
            [
                "Uygulama kaldırıcı: .app ve ilgili ~/Library artıkları",
                "Büyük ve eski dosyalar",
                "Kullanıcı LaunchAgent'larını aç/kapat",
            ]
        case .assistant:
            [
                "Sistem durumuna göre öneriler",
                "Yalnızca özet veriler gönderilir, dosya içerikleri asla",
                "Her öneri onayınla uygulanır",
            ]
        }
    }
}
