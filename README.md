# Keel

> Keep your computer steady.

macOS için güvenliği ön planda tutan bir bakım uygulaması: disk temizliği,
performans takibi, uygulama kaldırma. Swift 6 + SwiftUI, macOS 14 Sonoma ve üzeri.

Plan ve yol haritası: [docs/PLAN.md](docs/PLAN.md)

## Geliştirme

Gereksinimler: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate        # project.yml → Keel.xcodeproj
open Keel.xcodeproj      # Keel şemasını seç, ⌘R
```

`Keel.xcodeproj` üretilen bir dosyadır, git'e girmez. Proje ayarı değişecekse
`project.yml` düzenlenir.

Çekirdek mantık testleri (macOS veya Linux):

```sh
swift test --package-path Packages/KeelCore
```

## Yapı

| Klasör | İçerik |
|---|---|
| `App/` | SwiftUI uygulaması: tasarım sistemi, ekranlar, menü çubuğu |
| `Packages/KeelCore/` | UI'dan bağımsız çekirdek: güvenlik politikası, sistem bilgileri |
| `Support/` | Info.plist ve entitlements |
| `docs/` | Plan ve kararlar |

## Güvenlik

Silme yapan her işlem `KeelCore`'daki `SafetyPolicy`'den geçer: yalnızca izin
verilen klasörlerin içi, korunan sistem/kullanıcı konumları asla, sembolik
link üzerinden kaçış yok, her şey Çöp Kutusu'na. Ayrıntılar `docs/PLAN.md`.

Fontlar (Manrope, JetBrains Mono) SIL Open Font License 1.1 ile dağıtılır,
lisans metinleri `App/Resources/Fonts/` içinde.
