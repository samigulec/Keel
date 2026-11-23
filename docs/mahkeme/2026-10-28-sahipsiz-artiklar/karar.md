# Karar: Sahipsiz artıklar bulucu (PLAN.md Faz 2, satır 119)

**KARAR:** DEĞİŞTİRİLEREK KABUL. Yalnızca Aşama 0 kabul edildi: silme yapmayan, salt okunur bir ölçüm. Silme yapan her aşama (Aşama 1, Seçenek B, C, D) bu kararla **reddedildi**. Bunlar ölçüm sonucuyla birlikte ayrı bir mahkemede yeniden görülür.
**İNSAN ONAYI GEREKİR:** EVET. Nedenleri:
- Kopya bulucu kararı (2026-10-27) Faz 2 açık maddelerinin sırasını kullanıcıya bıraktı. Beş jürinin beşi de kullanıcı önceliği verilmeden kod yazılmamasını istiyor.
- Aşama 0'ın tek amacı gerçek bir Mac'te, gerçek kullanıcı verisiyle ölçüm yapmak. Bunu ancak sahip yapabilir ya da izin verebilir.
- Aşama 1'e geçiş eşiği önceden ve sahiple birlikte belirlenmeli.
- Aşama 1'e gelinirse `SafetyPolicy` korunan kökleri değişecek. Bu da Kural 4 kapsamında.

Sahip bu soruları yanıtlamadan ajanlar kod yazmaz.

**Sahibe sorular:**
1. **Öncelik:** Faz 2 açık maddeleri şunlar: sahipsiz artıklar, uygulama güncelleyici, menü çubuğu canlı grafikleri, kopya dosya bulucu ve satır 144. Aşama 0 şimdi mi yapılsın? Yoksa madde ertelensin mi? Ertelenirse PLAN satır 119'a gerekçeli bir erteleme notu düşülür (Seçenek A).
2. **Ölçüm:** Aşama 0 aracını kendi Mac'inizde çalıştırıp çıktıyı elle gözden geçirmeyi kabul ediyor musunuz? Çıktı cihazdan çıkmaz. Hangi makine ve macOS sürümünde çalışacak? Setapp, Homebrew Cask, Microsoft Office ya da harici diskteki uygulamalar kurulu mu? Bunlar jürinin işaret ettiği yanlış pozitif kaynakları.
3. **Eşik:** Aşama 1 mahkemesine gidilebilmesi için yanlış pozitif eşiği ne olsun? Benim önerim şu: önerilen 6 konumda elle doğrulanmış yanlış pozitif **sıfır** olmalı. Eşik aşılırsa Seçenek A'ya dönülür.
4. **Araç biçimi:** Ölçüm, pakete eklenecek küçük bir komut satırı aracıyla mı yapılsın (benim önerim; uygulamaya hiç dokunmaz)? Yoksa uygulama içinde yalnızca DEBUG derlemede görünen bir ekranla mı?

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 3 | HAYIR |
| Sıradan Mac kullanıcısı | RED | 4 | HAYIR |
| Kıdemli Swift mühendisi | KOŞULLU | 4 | HAYIR |
| Ürün yöneticisi ve rakip analisti | RED | 4 | HAYIR |

Sonuç: 3 KOŞULLU, 2 RED, veto yok.

## Gerekçe

**Oyların tartılması.** Beş jüri, aralarında haberleşmeden şu iki noktada birleşiyor:
- (a) Bugünkü envanterle silme kodu yazılmamalı.
- (b) Salt okunur bir ölçüm, ileride verilecek kararın ön şartı.

İki RED oyu da ölçümü dışlamıyor. Kullanıcı jürisi "yalnızca ölçüm amaçlı, hiçbir şey silmeyen bir rapor ileride denenebilir" diyor. Ürün yöneticisi "kullanıcı önceliği verirse ve Aşama 0 yanlış pozitifin sıfıra yakın olduğunu gösterirse ayrı mahkemeyle yeniden değerlendirilsin" diyor. Yani RED oyları silme yüzeyine karşı. Bu karar da o yüzeyi tümüyle reddediyor.

KOŞULLU oyların Aşama 1 için koyduğu şartlar çok ve ağır:
- envanteri NSWorkspace ve LaunchServices ile genişletmek,
- TeamID ile eşleştirme,
- `SafetyPolicy`'ye korunan kökler eklemek,
- yaş eşiği,
- FDA (Full Disk Access) ile ve onsuz sınama.

Bunların hiçbiri ölçüm verisi olmadan doğru boyutlandırılamaz. Bu yüzden kararın kapsamı, KOŞULLU ve RED oylarının kesiştiği yere, yani Aşama 0'a çekildi. Bu, çoğunluğa (KOŞULLU) karşı bir karar değil, onun daraltılmış hâli. RED oylarının "şimdi silme yok" isteği de tümüyle karşılanıyor.

**Savcının en güçlü argümanı (kabul edildi): yokluk çıkarımı.** Bugünkü `owner(of:)` dar eşleştirme için yazılmış. Ters yöne çevrilince "eşleşmedi" sonucu "silme adayı" anlamına geliyor. Kaynak envanter `AppInventory` ise yalnızca `/Applications` ve `~/Applications` altına bakıyor (`AppInventory.swift:45-84`, bir klasör derinliği). Bunu kodda doğruladım.

macOS uzmanı bu tabloya dosyada olmayan somut bir örnek ekledi: Office'in `UBF8T346G9.Office` biçimli Group Container'ı. `owner(of:)` yalnızca şu biçimleri tanıyor: `key == id`, `hasPrefix(id + ".")` ve `hasSuffix("." + id)` (`AppLeftovers.swift:103-109`). Bu yüzden Office kuruluyken bile o klasör sahipsiz çıkar.

Savcının ölçümsüz bir "sahipsiz" etiketinin onayı biçimsel hâle getirdiği tespiti de doğru. Bu nedenle silme kodu bu kararda yok.

**Savunmanın en güçlü argümanı (kabul edildi): Aşama 0 ucuz ve bilgi üretir.** Aşama 0 hiçbir şey taşımıyor ve yeni bağımlılık istemiyor. KeelCore içinde saf bir fonksiyon olarak Linux'ta test edilebiliyor. Bu ölçüm yapılmazsa, savunmanın dediği gibi, bu madde hakkındaki her karar (A dahil) tahmine dayanır.

Savunmanın Aşama 1 önerisi ise **reddedildi**. Gerekçesi şu: önerinin kendi güvencesi olan Spotlight çapraz kontrolü sınanmadı, eşik keyfi kaldı, korunan kökler eksik. Savunma da Aşama 1'in kendine özgü değerinin "küçük" olduğunu kabul ediyor, çünkü Caches zaten Temizlik bölümünde.

**Reddedilen öteki öneriler:**
- **D seçeneği** (Akıllı Tarama ve Keel AI): yol adları bile kurulu ya da kaldırılmış uygulamaları ele verir (PLAN satır 154). Ayrı veri akışı kararı gerekir.
- **Savcının "görülmüş uygulama geçmişi" alternatifi (risk 10a):** Değerli bir fikir, ama Keel kurulmadan önce kaldırılmış uygulamaları kapsamıyor ve kalıcı yeni bir durum dosyası getiriyor. Bu karara alınmadı. Aşama 1 mahkemesinde seçenek olarak yeniden değerlendirilmeli.

**Kayıt düzeltmesi (doğrulandı).** `dosya.md` içindeki `SafetyPolicy` satır numaraları yanlış. Dosya 207 satır. `standardAllowedRoots` 163'te, `standardProtectedRoots` 175'te, `evaluate` 57'de. Dosyanın verdiği 226-268, 332-341 ve 344-366 geçersiz. Korunan listede Safari, Calendars, AddressBook, CloudDocs ve `group.com.apple.*` yok; bu tespit doğru. İleriki mahkeme bu satırları esas almalı.

## Uygulama planı
(Yalnızca sahip 1-4 numaralı soruları yanıtlayıp önceliği bu maddeye verirse uygulanır. Hiçbir adım silme, Çöp'e taşıma ya da `SafetyPolicy` değişikliği içermez.)

1. **Saf sınıflandırıcı**
   - Dosyalar: yeni `Packages/KeelCore/Sources/KeelCore/Applications/OrphanScan.swift`. `AppLeftovers.swift`'te yalnızca `owner(of:)`, `stripSuffix` ve `locations` için gerekiyorsa görünürlük ayarı yapılır, davranış değişmez.
   - Girdi: konum başına dizin listesi. Fonksiyon dosya sisteminden bağımsızdır; konum, girdi adı, boyut ve değişiklik tarihi parametre olarak verilir. Ayrıca kurulu bundle ID kümesi ve bir `BundleIDLocator` alınır.
   - Çıktı `OrphanReport` türündedir. İçinde şunlar bulunur:
     - `candidates` (doğrulanmış adaylar),
     - `unverified` (yalnızca envantere göre eşleşmeyenler, tanı amaçlı),
     - ret nedenleriyle birlikte elenenlerin sayımı: Apple, ID biçiminde olmayan ad, TeamID biçimi, kurulu sahip,
     - `unreadable` konumlar,
     - `status: .ok | .unsure(reason)`.
   - Kurallar:
     - Yalnızca bundle ID biçimli adlar (en az iki nokta) aday olabilir. Ada göre eşleştirme yok.
     - `com.apple.*` ve `group.com.apple.*` elenir.
     - `TEAMID.Ad` biçimi hiçbir zaman aday olmaz, ayrı sayılır.
     - En uzun eşleşme kuralı korunur.
     - Envanter boşsa ya da locator "bilinmiyor" diyorsa `candidates` boş kalır ve `status` `.unsure` olur.
   - Her girdi için "Aşama 1 kapsamında mı?" bayrağı bulunur. Kapsamdaki konumlar: Caches, Logs, Saved Application State, HTTPStorages, WebKit, Cookies.
   - Test: adım 4.

2. **Locator soyutlaması**
   - Dosya: `OrphanScan.swift` içinde `BundleIDLocator` protokolü.
   - Linux ve varsayılan uygulaması `.unknown` döndürür.
   - macOS uygulaması `#if os(macOS)` arkasında `NSWorkspace.urlsForApplications(withBundleIdentifier:)` kullanır. Yalnızca public API; özel LaunchServices sembolleri yasak.
   - Test: Linux stub'ı ile `candidates` boş, `status` `.unsure` döner.

3. **Ölçüm aracı (sahibin 4 numaralı soruya vereceği yanıta bağlı)**
   - Önerilen biçim: `Packages/KeelCore/Package.swift` içine dış bağımlılığı olmayan bir `keel-orphan-report` executable hedefi ve `Sources/keel-orphan-report/main.swift`.
   - Araç 13 konumu okur. Boyutu `DirectorySizer` ile, değişiklik tarihini dosya özniteliklerinden alır. `AppInventory` ve macOS locator ile raporu stdout'a tablo ve JSON olarak yazar.
   - Okunamayan klasörü "taranamadı" diye raporlar. Dosya yazmaz, ağa çıkmaz, `FileRemover`'ı çağırmaz.
   - `project.yml` ve `App/` değişmez.
   - Test: araç ince bir kabuktur; mantığın tamamı 1. adımdaki testlerde sınanır.

4. **Testler**
   - Dosya: yeni `Packages/KeelCore/Tests/KeelCoreTests/OrphanScanTests.swift`.
   - Durumlar:
     - Sahipsiz ID biçimli girdi `unverified` listesine girer. Locator "yok" derse `candidates` listesine de girer.
     - Kurulu uygulamanın dosyası (plist, savedstate, binarycookies, ByHost UUID) çıkmaz.
     - İç içe ID'de `com.x.app.pro.helper` girdisi, `com.x.app.pro` kuruluyken çıkmaz.
     - `com.apple.*` ve `group.com.apple.*` çıkmaz.
     - `UBF8T346G9.Office` aday olmaz ve TeamID sayımına girer.
     - `Google` gibi ID biçiminde olmayan adlar ve `genericNames` aday olmaz.
     - Envanter boşsa sonuç `.unsure` olur ve `candidates` boş kalır.
     - Locator bilinmiyorsa sonuç `.unsure` olur.
     - Okunamayan konum `unreadable` listesine girer. Boş sonuç `.ok` ve "temiz" sayılmaz.
     - Aşama 1 kapsam bayrağı yalnızca 6 konumda `true` olur.

5. **PLAN notu**
   - Dosya: `docs/PLAN.md` satır 119.
   - Eklenecek not: "Aşama 0: salt okunur ölçüm (karar 2026-10-28). Silme ayrı mahkeme." Madde `[ ]` olarak kalır.
   - Test: yok, belge değişikliği.

## Kabul kriterleri
- [ ] `swift test --package-path Packages/KeelCore` geçiyor. Mevcut `ApplicationsTests` (`findsOnlyTheAppsOwnFiles`, `genericNamesDoNotMatchByName` vb.) değişmeden geçiyor.
- [ ] `OrphanScanTests` adım 4'teki her durumu kapsıyor.
- [ ] Yeni kodda `FileRemover`, `trashItem`, `removeItem`, `moveToTrash` ve `ActionLog` yazımı yok (grep ile denetlenir).
- [ ] `SafetyPolicy.swift`, `Uninstaller.swift`, `App/`, `project.yml`, `SmartCare`, `KeelTools` ve `AssistantModel` değişmemiş.
- [ ] `Package.swift`'e dış bağımlılık eklenmemiş. Varsa tek değişiklik yerel executable hedefi.
- [ ] Locator bilinmiyorken ya da envanter boşken `candidates` boş ve `status == .unsure`.
- [ ] Ölçüm aracı ağa çıkmıyor, diske yazmıyor, çıktısı yalnızca stdout'a gidiyor.
- [ ] Sahip, ölçüm sonucunu ve elle doğrulanmış yanlış pozitif listesini gördü. Aşama 1 için yeni bir mahkeme açıldı ya da Seçenek A uygulandı. Bu kararla Aşama 1'e geçilmez.

## Kapsam dışı
- Her türlü silme ve Çöp'e taşıma: `OrphanRemover`, sahipsiz öğeler için `UninstallPlan` ve arayüzde silme düğmesi.
- `SafetyPolicy` korunan köklerine ekleme yapmak: Safari, Calendars, AddressBook, CloudDocs, `group.com.apple.*`. Bu, Aşama 1 mahkemesinin ve insan onayının konusu.
- Application Support, Containers, Group Containers, Preferences, LaunchAgents ve `/Library` altı için aday üretmek. Bunlar ölçümde yalnızca tanı amacıyla sayılır.
- Yaş eşiğinin uygulanması. Ölçüm yalnızca değişiklik tarihini raporlar, eşik verisi bundan çıkar.
- TeamID ve kod imzası ile eşleştirme ve Spotlight (NSMetadataQuery) çapraz kontrolü. Bunlar Aşama 1'in ön şartları.
- "Görülmüş uygulama geçmişi" alternatifi.
- Seçenek D: Akıllı Tarama, `KeelTools`, `AssistantModel`, Keel AI'ya yol göndermek.
- `dosya.md` içindeki satır numaralarını düzeltmek. Hakim hiçbir dosyayı değiştirmedi; düzeltme bu kararın Gerekçe bölümüne kaydedildi.
