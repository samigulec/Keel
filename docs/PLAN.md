# Keel — Teknik Plan

> Keep your computer steady.
> CleanMyMac tarzı, güvenliği ön planda tutan bir macOS bakım uygulaması.

Tasarım: [Keel tasarım kanvası](https://claude.ai/artifact/SDWm1iCjvfETG26SVfdfMh)
(Akıllı Tarama · Temizlik · Performans · Keel AI · Logo)

---

## 1. Temel kararlar

| Konu | Karar | Neden |
|---|---|---|
| Dil / UI | Swift 6 + SwiftUI (gerektiğinde AppKit) | Sistem API'lerine doğrudan erişim, hafif, native görünüm |
| Minimum macOS | **14 Sonoma** | `@Observable`, olgun `MenuBarExtra`, `SMAppService`; 2018 ve sonrası Mac'lerin neredeyse tamamı destekliyor |
| Mimari | Apple Silicon + Intel (Universal) | Ek maliyeti yok |
| Dağıtım | App Store **dışı**: Developer ID imzası + notarization | App Store sandbox'ı önbellek/log temizliğine izin vermez |
| Proje yapısı | XcodeGen (`project.yml`) + yerel Swift Package (`KeelCore`) | `.xcodeproj` elle yazılmaz, git'te çakışma çıkarmaz; çekirdek mantık UI'dan bağımsız test edilir |
| Bağımlılık | Mümkün olduğunca sıfır | Bakım uygulaması sade ve denetlenebilir olmalı |

## 2. Güvenlik ilkeleri (pazarlıksız)

Uygulamayı ileride public yapabilmemizin ön şartı. Her özellik bu kurallara uymak zorunda.

1. **Hiçbir şey kalıcı silinmez.** Silinen her şey önce Çöp Kutusu'na taşınır
   (`FileManager.trashItem`). Kalıcı silme yalnızca kullanıcının kendisi
   "Çöpü boşalt" dediğinde olur.
2. **Önce göster, sonra onayla.** Tarama sadece okur. Silme işlemi her zaman
   kullanıcı onayından sonra ve yalnızca seçilen öğeler için çalışır.
3. **İzin listesi (allowlist), yasak listesi değil.** Temizleyici sadece açıkça
   tanımlı klasörlere dokunur (örn. `~/Library/Caches`). Liste dışındaki hiçbir
   yol silinemez. Bu kontrol `KeelCore` içinde, tek bir yerde (`SafetyPolicy`)
   yapılır ve birim testleriyle korunur.
4. **Korunan yollar asla:** `/System`, `/usr` (hariç `/usr/local`), `/bin`,
   `/sbin`, `/Library/Apple`, uygulama paketlerinin (`.app`) içi, iCloud Drive,
   Fotoğraflar/Mail/Mesajlar kütüphaneleri, Keychain'ler.
5. **Sembolik link takip edilmez**, başka diske taşan yol silinmez.
6. **Çalışan uygulamanın önbelleğine dokunulmaz** (örn. Chrome açıkken Chrome
   önbelleği atlanır, kullanıcıya söylenir).
7. **Her işlem kaydedilir.** `~/Library/Logs/Keel/` altında ne, ne zaman, ne
   kadar taşındı. Hata ayıklama ve güven için.
8. **Root yetkisi MVP'de yok.** Yönetici yetkisi isteyen işler (helper) Faz 3'e
   kadar ertelenir.

## 3. Tasarımdaki bazı noktalarda düzeltme önerisi

Tasarım CleanMyMac/Windows araçlarından esinlendiği için birkaç kart macOS'ta
ya gerçek dışı ya da tehlikeli. Dürüst bir uygulama için önerim:

| Tasarımdaki öğe | Sorun | Öneri |
|---|---|---|
| **Kullanılmayan dil dosyaları** | `.app` içinden dosya silmek kod imzasını bozar, uygulama açılmaz veya güncellenemez | **Kaldıralım** |
| **Belleği boşalt** (11,2 → 7,8 GB) | macOS boş RAM'i zaten önbellek olarak kullanır; "boşaltmak" (`purge`, sudo ister) Mac'i kısa süreliğine *yavaşlatır* | "Bellek baskısı" göstergesi + en çok bellek kullanan uygulamalar listesi, isteğe bağlı "Uygulamadan çık" |
| **Tahmini açılış süresi / +3 sn** | Uygulama başına açılış maliyeti güvenilir ölçülemez, uydurma sayı olur | Açılış öğelerini listele, sayı gösterme. İleride gerçek ölçüm yapılabilirse ekleriz |
| **Açılış öğelerini kapat** | Başka uygulamaların "Login Items" ayarını değiştiren public API yok | Kullanıcı LaunchAgent'larını (`~/Library/LaunchAgents`) aç/kapat + Login Items için Sistem Ayarları'na derin link |
| **DNS önbelleği / Arama dizini / Disk kontrolü** | Hepsi yönetici yetkisi ister | Faz 3 (privileged helper) |
| **Sağlık puanı 86/100** | Formül tanımsız | Basit ve açıklanabilir bir formül: disk doluluğu + temizlenebilir alan + bellek baskısı. Formül arayüzde "Bu puan nasıl hesaplanır?" ile gösterilir |
| **"7 gün boyunca saklarız"** | Kendi karantinamızı yazmak karmaşık | macOS Çöp Kutusu'nu kullanırız. Metin: "Silinenler Çöp Kutusu'na taşınır, oradan geri alabilirsin" |

## 4. Modül yapısı

```
Keel/
├── project.yml                 # XcodeGen tanımı → Keel.xcodeproj üretir
├── App/                        # SwiftUI uygulaması (sadece Mac'te derlenir)
│   ├── KeelApp.swift           # @main, WindowGroup + MenuBarExtra
│   ├── DesignSystem/           # Renkler, tipografi, ortak bileşenler (tasarımdan)
│   ├── Features/
│   │   ├── SmartScan/          # 1 · Akıllı Tarama
│   │   ├── Cleanup/            # 2 · Temizlik
│   │   ├── Performance/        # 3 · Performans
│   │   └── Assistant/          # 4 · Keel AI (Faz 4)
│   └── MenuBar/                # Menü çubuğu durum göstergesi
├── Packages/KeelCore/          # Saf Swift paketi: UI yok, test edilebilir
│   ├── Sources/KeelCore/
│   │   ├── Safety/             # SafetyPolicy: izin listesi, korunan yollar
│   │   ├── Scanning/           # Klasör boyutu, dosya yaşı, paralel tarama
│   │   ├── Cleanup/            # Kategoriler (önbellek, log, çöp, indirmeler…)
│   │   ├── System/             # Disk, RAM, CPU okuma (sysctl/host_statistics)
│   │   └── Actions/            # Çöpe taşıma, işlem günlüğü
│   └── Tests/KeelCoreTests/
└── docs/
```

`KeelCore` platforma özel kodu `#if os(macOS)` ile ayırır. Böylece tarama,
güvenlik politikası ve kategori kuralları Linux'ta (CI'da) da test edilebilir.

## 5. Yol haritası

### Faz 0 — İskelet
- XcodeGen projesi, `KeelCore` paketi, boş SwiftUI penceresi + kenar çubuğu
- Tasarım sistemi: renkler (Deep Hull `#0F1A17`, Keel Green `#2FBF8F`,
  Mist `#F3F5F4`, Slate `#56635E`), Manrope + JetBrains Mono, logo
  (Ekim 2026: tasarım koyu temaya geçti: lacivert `#071423` zemin, cam
  kartlar, nane-camgöbeği geçişler ve bölüm karakterleri)
- `SafetyPolicy` ve testleri **ilk yazılan kod** olur
- GitHub Actions: macOS runner'da build + test

### Faz 1 — MVP (kendi kullanımın için)
- **Akıllı Tarama:** disk/RAM özeti, temizlenebilir alan, öneriler listesi
- **Temizlik:** kullanıcı önbellekleri, eski loglar, Çöp Kutusu, eski
  indirmeler (yaşa göre), tarayıcı önbellekleri, Xcode DerivedData/Simulator
  önbellekleri (varsa). Seç → onayla → Çöp'e taşı
- **Performans (salt okunur):** CPU, bellek baskısı, en çok kaynak tüketen
  uygulamalar, açılış öğeleri listesi
- **Menü çubuğu:** CPU / RAM / disk boş alanı
- Full Disk Access yoksa onboarding ekranı ve yönlendirme

### Faz 2 — Uygulamalar ve Büyük Dosyalar
- [x] Uygulama kaldırıcı: `.app` + ilgili `~/Library` artıkları (bundle ID ile
  eşleştirme, kullanıcıya tek tek gösterilir), sıfırlama, Intel/Universal,
  App Store kaynağı, kullanılmayan uygulamalar (90+ gün)
- [x] Performans: ağ hızı (Stats gibi), süreç bazında işlemci kullanımı
- Sahipsiz artıklar (kaldırılmış uygulamalardan kalanlar), uygulama güncelleyici
- Sensörler: sıcaklık ve fan (SMC), menü çubuğunda canlı grafikler
- Büyük ve eski dosyalar bulucu, kopya dosyalar
- Kullanıcı LaunchAgent'larını aç/kapat

### Faz 3 — Yönetici yetkisi gerektirenler
- `SMAppService` ile privileged helper + XPC
- Sistem logları, DNS önbelleği, Spotlight yeniden dizinleme, disk doğrulama

### Keel AI (öne alındı, ilk sürüm hazır)
- Kullanıcı kendi hesabıyla bağlanır: ChatGPT (Codex CLI üzerinden), Claude
  (Claude Code üzerinden) ya da cihazdaki Apple Intelligence. API anahtarı yok.
- Giriş sağlayıcının kendi akışında yapılır; Keel kimlik bilgisi görmez ya da
  saklamaz. Yalnızca özet sistem verileri gönderilir, dosya içeriği asla.
- Public sürümden önce: Anthropic ve OpenAI koşullarının üçüncü taraf
  uygulamada bu kullanıma izin verdiğini yeniden doğrula; resmi logolar için
  yazılı izin gerekir.
- Asistan araçlarla gerçek veriye bakar; temizlik yalnızca kart olarak
  önerilir ve kullanıcı onaylamadan hiçbir şey yapılmaz
- Sonra: sohbet geçmişini saklama, daha fazla araç (büyük dosyalar,
  uygulama kaldırma önerileri)

### Faz 4 — Dağıtım
- Developer ID imzası, notarization, Sparkle ile otomatik güncelleme
- Public sürüm

**Koruma (zararlı yazılım taraması)** bilinçli olarak yol haritasında yok. İyi
yapılması çok zor, yarım yapılması yanlış güven verir. İleride değerlendiririz.

## 6. Çalışma şekli

- Kodu bu repoda birlikte yazıyoruz. Mac'te derleme:
  `brew install xcodegen && xcodegen && open Keel.xcodeproj`
- `KeelCore` testleri: `swift test --package-path Packages/KeelCore`
- Her faz ayrı PR. Silme yapan her kod parçası testli olmadan birleşmez.
