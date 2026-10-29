# Karar: Menü çubuğunda canlı grafikler

**KARAR:** DEĞİŞTİRİLEREK KABUL (yalnızca Seçenek B'nin daraltılmış hâli. Simgede canlı grafik (C) bu kararın dışında, ayrı mahkemeye kaldı.)
**İNSAN ONAYI GEREKİR:** EVET. Nedeni: Kural 4'teki teknik tetikleyicilerin hiçbiri yok. Root yok, silme yok, `SafetyPolicy` değişmiyor, veri cihazdan çıkmıyor, yeni bağımlılık yok, imza ya da yayın yok, geri alınamayan bir adım yok. Onay şu iki soru için gerekiyor:
- Faz 2 sırası sahibe ait ve bu soru üç davadır (`GUNDEM.md`) cevapsız.
- PLAN satır 122'deki "canlı grafik" ifadesinin ne kastettiği (B mi, C mi) yalnızca sahip tarafından söylenebilir.

Beş jürinin beşi de, savcı da bu onayı şart koştu. Sahip cevap verene kadar kod yazılmaz.

### Sahibe sorular
1. **Öncelik:** Faz 2 açık maddeleri şunlar: sahipsiz artıklar Aşama 0, uygulama güncelleyici Aşama 0, menü çubuğu canlı grafikleri (bu karar), kopya dosya bulucu, LaunchAgent aç/kapat. Hangisi önce yapılsın? Bu iş için iki seçenek var:
   - (a) Aşağıdaki plan şimdi uygulanır.
   - (b) PLAN satır 122'ye gerekçeli bir erteleme notu düşülür (Seçenek A).

   Not: Aynı soru diğer üç kayıtta da bekliyor. Tek cevap dördünü birden kapatabilir.
2. **Kapsam:** "Menü çubuğunda canlı grafikler" derken ne istiyorsun?
   - (a) Açılan pencerede mini grafik (B) yeterli. B bitince madde `[x]` olur.
   - (b) Asıl istenen menü çubuğu simgesinin kendisinde grafik (C). Bu durumda B bitince madde açık kalır, C için Mac'te ölçüm şartıyla ayrı mahkeme açılır.
3. **Mac'te doğrulama:** Ajanlar Linux'ta çalışıyor. Ekran görüntüsü alamıyor, enerji ölçemiyor. PR birleşmeden önce kendi Mac'inde şu üç kontrolü yapmayı kabul ediyor musun? Hangi makine ve hangi macOS sürümü?
   - Performans ekranının önce/sonra ekran görüntüsü.
   - Menü penceresi açıkken ve kapalıyken Activity Monitor'de Keel'in CPU ve "Energy Impact" değerleri.
   - Mümkünse Instruments (SwiftUI şablonu) ile pencere kapalıyken `MenuBarContent` gövdesinin yeniden hesaplanıp hesaplanmadığı.
4. **Görünüm:** Grafik yalnızca CPU ve ağ satırlarına eklenecek, yanına küçük bir "son 1 dk" etiketi konacak. Bellek ve disk dışarıda kalacak. Uygun mu?

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 4 | HAYIR |
| Sıradan Mac kullanıcısı | KOŞULLU | 3 | HAYIR |
| Kıdemli Swift mühendisi | KOŞULLU | 4 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KOŞULLU | 3 | HAYIR |

5 KOŞULLU, veto yok. Koşullar büyük ölçüde örtüşüyor:
- Kapsam yalnızca B, C ayrı mahkemeye.
- Geçmiş mantığı testleriyle birlikte `KeelCore`'a taşınır.
- Bellek grafiği bu işte yok.
- Ölçüm döngüsü değişmez.
- Yeni bağımlılık yok, Swift Charts da yok.
- Sparkline taşınırken Performans ekranı görsel olarak kontrol edilir.
- Geçmiş verisi Keel AI'ya gönderilmez.
- Kod yazılmadan önce insan onayı alınır.

## Gerekçe

**Kanıt doğrulaması.** Dosyadaki ana tespitleri kodda kendim kontrol ettim:
- `App/SystemStatus.swift:9`: `historyLength = 30`.
- `App/SystemStatus.swift:35-42`: geçmiş dizileri.
- `App/SystemStatus.swift:44-46`: 2 sn aralık ve `slowEvery = 15`.
- `App/SystemStatus.swift:66-79`: hiç durmayan döngü.
- `App/SystemStatus.swift:196-198`: `private static func appending`.
- `App/Features/Performance/PerformanceView.swift:154-179`: `private struct Sparkline`. Yüksekliği sabit 56 pt, zaten `accessibilityHidden(true)` alıyor, `SystemStatus.historyLength`'e bağlı.
- `PerformanceView.swift`'te yedi çağrı satırı var (341, 366, 469, 470, 510, 511, 548). Jürinin "beş kullanım" dediği beş grafik bölümü.
- `App/MenuBar/MenuBarContent.swift`: grafik yok, 260 pt genişlik.
- `App/KeelApp.swift:68-72`: statik SF Symbol ve `.window` stili.
- `KeelCore` testlerinde geçmiş ya da ring buffer testi yok.
- `.github/workflows/ci.yml` macOS runner'larda uygulamayı derliyor. Yani `App/` değişikliklerinin derlendiği CI'da doğrulanabiliyor. Görsel ve enerji doğrulaması ise yapılamıyor.

**Savcının en güçlü argümanı** şu: C, yani simgenin pencere kapalıyken de 2 sn'de bir yeniden çizilmesi, ölçülmemiş bir enerji ve CPU yükü getirir. Bu da bir bakım uygulamasının varlık gerekçesiyle çelişir. Çentikli ekranda simgenin gizlenmesi de kullanıcının Keel'e erişimini keser.

KABUL EDİLDİ. Beş jürinin beşi de aynı yerde duruyor. Elimizdeki tek kanıt topluluk bildirimleri (Control Center, Stats README). Keel'e özel ölçüm yok. Ölçülmemiş bir sürekli yükü menü çubuğuna koymak, güncelleyici kararındaki "ölçülmemiş şeyi önce ölç" çizgisine de aykırı. C bu karardan çıkarıldı. Ayrı mahkemeye ancak Mac'te ölçümle gelebilir.

Savcının öncelik itirazı da (Faz 2 sırası üç davadır cevapsız) KABUL EDİLDİ. İNSAN ONAYI bu yüzden EVET. Savcının "bu maddeyi diğerlerinin altında tut" önerisi ise REDDEDİLDİ. Sıralamayı hakim değil sahip yapar.

**Avukatın en güçlü argümanı** şu: Veri zaten toplanıyor ve yalnızca Performans ekranında kullanılıyor. B yeni ölçüm, yeni okuyucu, ağ, silme ya da bağımlılık getirmiyor. B'yi C'den ayırmak, C'nin ölçüm belirsizliğini beklemeden değer sunar. `appending`'in `KeelCore`'a taşınması da CLAUDE.md'deki "mantık KeelCore'da" kuralıyla çelişen mevcut testsiz borcu kapatır.

KABUL EDİLDİ. Ürün yöneticisi de borcun kapanmasını B'nin "kendi başına değeri" sayıyor.

Avukatın "pencere kapalıyken çizilmez, enerji yükü artmaz" iddiası ise REDDEDİLDİ (doğrulanmamış iddia). macOS ve Swift uzmanları haklı: `MenuBarExtra(.window)` içeriği `@Observable` bir kaynağa bağlı. Gizliyken gövdenin yeniden hesaplanıp hesaplanmadığı ölçülmedi. Şunu da tartıya koydum: `MenuBarContent` bugün de `status`'u gözlüyor (CPU `ProgressBar`'ı, ağ metni). Yani gizli yeniden hesaplama varsa bu yeni bir sorun değil. B'nin eklediği şey yalnızca grafik çiziminin marjinal maliyeti. Bu yüzden ölçümü kod yazmanın değil birleştirmenin ön koşulu yaptım. Ölçümü sahip Mac'te yapar. Sonuç kötüyse PR birleşmez ve konu mahkemeye döner. Ölçülemeyen bir şey PR'da iddia edilmez.

Avukatın rekabet gerekçesi ("rakipler grafik sunuyor") da REDDEDİLDİ. Ürün yöneticisi ve kullanıcı jürisi aynı görüşte: bu bir eşitleme özelliği ve dosyada kullanıcı talebine dair kanıt yok. Ürün gerekçesi yalnızca "son 1 dakikayı tek tıkla görmek" olarak kalır.

**Diğer kararlar.**
- *Bellek grafiği:* Yok. "Kullanılan bellek" macOS'ta yanıltıcı ve temizleme baskısı yaratır. "Baskı" kaynağı ise doğrulanmadı. Konu ayrı karara kaldı.
- *Disk grafiği:* Yok. Satır 30 sn'de bir güncelleniyor.
- *Döngü hızı:* Değişmez. Değişirse Performans grafiklerinin zaman ekseni bozulur.
- *Swift Charts:* Kullanılmaz, bağımlılık sorusu açılmaz.
- *Keel AI:* Ölçüm geçmişi ve grafik verisi Keel AI'ya ya da cihaz dışına gönderilmez (PLAN satır 154). Bu karar böyle bir akışa izin vermez.
- *Yeni okuma kaynağı:* Eklenirse karar geçersizdir ve konu yeniden yargılanır.

Hiçbir oyda veto yok. Kararım oy çoğunluğuyla aynı yönde, çoğunluğa karşı bir karar yok.

## Uygulama planı
(Yalnızca sahip 1. soruya "(a) şimdi" diye cevap verdikten sonra başlanır. Her adım ayrı commit olur. PR'ı ajan birleştirmez, varsayılan dala doğrudan gönderilmez.)

1. **`KeelCore`'a geçmiş kırpma fonksiyonu ve testleri.** Davranış bugünküyle birebir aynı olur.
   - Dosyalar: `Packages/KeelCore/Sources/KeelCore/System/RollingHistory.swift` (yeni) ve `Packages/KeelCore/Tests/KeelCoreTests/RollingHistoryTests.swift` (yeni).
   - Fonksiyon: `public enum RollingHistory { public static func appending(_ value: Double, to history: [Double], limit: Int) -> [Double] }`. Anlamı `Array((history + [value]).suffix(limit))`. Tek ek: `limit <= 0` için `[]` döner, çünkü `suffix` negatif sayıda çöker.
   - Testler:
     - boş diziye ekleme;
     - sınırın altında büyüme;
     - tam dolu dizide en eskinin düşmesi (taşma);
     - eskiden yeniye sıranın korunması;
     - limit değişimi (sınırdan uzun bir dizi kısa limitle kırpılır);
     - `limit == 0` ve negatif limit.
   - Test komutu: `swift test --package-path Packages/KeelCore`.
2. **`SystemStatus` yeni fonksiyonu çağırır.** `SystemStatus.appending` gövdesi `RollingHistory.appending(value, to: history, limit: historyLength)` çağrısına dönüşür, ya da çağrı yerleri doğrudan bunu kullanır. Davranış değişmez. Döngü, aralıklar ve eşzamanlılık kuralı (satır 44-46, 66-79, 97-126) değişmez.
   - Dosya: `App/SystemStatus.swift`.
   - Test: 1. adımdaki testler ve macOS CI derlemesi.
3. **`Sparkline` ortak bileşene taşınır.** `private` kaldırılır ve `var height: CGFloat = 56` parametresi eklenir. Bunun dışında gövde aynen kalır (renkler, 3 pt aralık, 30 çubuğa dolgu, `accessibilityHidden(true)`). Performans ekranındaki çağrı satırları değişmez. Taşıma tek başına bir commit olur.
   - Dosyalar: `App/Features/Performance/PerformanceView.swift` (sil) ve `App/DesignSystem/Components.swift` (ekle).
   - Test: macOS CI derlemesi. Önce/sonra ekran görüntüsünü sahip alır.
4. **Menü penceresine mini grafikler eklenir.** Değer metinleri ve "Keel'i aç" / "Çıkış" düğmeleri olduğu gibi kalır. Pencere genişliği 260 pt kalır.
   - İşlemci satırına `Sparkline(values: status.cpuHistory, height: 20)` eklenir. Mevcut `ProgressBar` korunur.
   - Ağ satırının altına iki grafik **alt alta** gelir (yan yana 30 çubuk 260 pt'ye sığmaz):
     - `status.networkInHistory` ve `status.networkOutHistory`;
     - Performans ekranındaki gibi ortak ölçek: `max(iki dizinin en büyüğü, 1)`;
     - Performans ekranındaki giriş/çıkış renkleri;
     - her biri yaklaşık 16 pt.
   - İki grafiğin anlamı küçük bir "son 1 dk" etiketiyle belirtilir.
   - Bellek ve disk satırlarına grafik eklenmez.
   - Dosya: `App/MenuBar/MenuBarContent.swift`.
   - Test: macOS CI derlemesi. Görsel kontrolü sahip yapar.
5. **PR açıklaması.** Şu bölümleri içerir:
   - Kapsam dışı listesi (aşağıdaki bölüm).
   - Şu not açıkça yazılır: "Menü penceresi açık ve kapalıyken CPU ve enerji etkisi ölçülmedi. Linux'ta ölçülemez. Sahip Mac'te doğrulasın."
   - Sahip için kontrol listesi: önce/sonra ekran görüntüleri, Activity Monitor değerleri, varsa Instruments sonucu.
   - Pazarlama dili yok, "rakiplerden iyi" iddiası yok.
6. **PLAN güncellemesi.** Sahibin 2. soruya cevabına göre yapılır:
   - (a) ise satır 122 `[x]` olur.
   - (b) ise madde açık kalır ve altına şu not eklenir: "Açılan pencerede mini grafik yapıldı. Simgede grafik ayrı mahkeme, ön koşul Mac'te ölçüm."
   - Dosya: `docs/PLAN.md`.

## Kabul kriterleri
- [ ] `swift test --package-path Packages/KeelCore` geçiyor. `RollingHistoryTests` boş, büyüme, taşma, sıra, limit değişimi ve sıfır/negatif limit durumlarını kapsıyor.
- [ ] `App/SystemStatus.swift` içinde kendi kırpma mantığı kalmamış, `RollingHistory` kullanılıyor. Döngü, aralıklar ve iş eşzamanlılığı satırları diff'te değişmemiş.
- [ ] `Sparkline` `App/DesignSystem/Components.swift`'te. Varsayılan yükseklik 56 pt. `PerformanceView.swift` çağrı satırları değişmemiş. `accessibilityHidden(true)` duruyor.
- [ ] `MenuBarContent` içinde yalnızca CPU ve ağ grafikleri var. Sayılar, düğmeler ve 260 pt genişlik korunmuş. "son 1 dk" etiketi var.
- [ ] macOS CI derlemesi (macos-15 ve macos-26) geçiyor.
- [ ] Şu dosyalarda diff yok: `App/KeelApp.swift`, `App/Navigation/AppNavigation.swift`, `App/Features/Settings/SettingsView.swift`, `project.yml`, `Package.swift`, okuyucular (`Packages/KeelCore/Sources/KeelCore/System` ve `Hardware` altındaki mevcut dosyalar).
- [ ] Yeni bağımlılık yok, Swift Charts import'u yok. Yeni ağ çağrısı, yeni dosya yolu erişimi, yönetici yetkisi ve Keel AI'ya veri akışı yok.
- [ ] PR açıklamasında kapsam dışı listesi ve "ölçülmedi, sahip Mac'te doğrulasın" notu var.
- [ ] Birleştirmeden önce (sahip, Mac'te):
  - Performans ekranı önce/sonra görsel olarak aynı.
  - Menü kapalıyken Keel'in CPU kullanımında fark edilir bir artış yok.

  Artış varsa PR birleşmez ve konu mahkemeye döner.
- [ ] PR'ı ajan birleştirmiyor.

## Kapsam dışı
- Menü çubuğu simgesinde canlı grafik ya da değer (C). Kapsama girenler: `MenuBarExtra` etiketi, `ImageRenderer`, `isInserted`, yeni `Preference` ya da ayar anahtarı. Bunlar için ayrı mahkeme açılır. Ön koşulları:
  - Mac'te Activity Monitor ve Instruments ile enerji ve CPU ölçümü;
  - macOS 14 ve güncel sürümde etiket davranışı (tema, template, Retina);
  - çentikli ekranda genişlik ve gizlenme kontrolü.
- Pencere görünürlüğüne bağlı ölçüm hızı ya da `SystemStatus` döngüsünde herhangi bir değişiklik. Ayrı karar gerekir.
- Bellek geçmişi ve bellek grafiği. "Kullanılan" ile "baskı" arasındaki seçim ve baskı kaynağının (sysctl ya da memorypressure) macOS 14'te doğrulanması ayrı karara kaldı.
- Disk grafiği.
- Swift Charts ya da başka bir çerçeve veya bağımlılık.
- Ölçüm geçmişinin ya da grafik verisinin Keel AI'ya veya cihaz dışına gönderilmesi (PLAN satır 154).
- Yeni okuma kaynağı ya da okuyucu. Eklenirse bu karar geçersiz olur.

---
Not (karar metninin dışında, kaydedecek ajan için):
- `GUNDEM.md` şu iki karara bağlantı veriyor: `2026-10-27-kopya-dosya-bulucu/karar.md` ve `2026-10-28-sahipsiz-artiklar/karar.md`. Ancak bu çalışma ağacında `/home/claude/keel/docs/mahkeme/` altında yalnızca `2026-10-29-menu-cubugu-canli-grafikler` ve `2026-10-29-uygulama-guncelleyici` klasörleri var. Bağlantılar kırık olabilir, kontrol edilmeli.
- Bu kararın sorularını `GUNDEM.md` "Bekleyen insan onayları" bölümüne eklerken, 1. sorunun diğer üç kayıttaki öncelik sorusuyla aynı olduğunu belirten bir not düşülmeli.
- Hiçbir dosyayı değiştirmedim.
