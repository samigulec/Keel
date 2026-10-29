# Dava dosyası: Menü çubuğunda canlı grafikler

## Soru
PLAN.md Faz 2 açık maddesi "Menü çubuğunda canlı grafikler" yapılsın mı? Yapılacaksa kapsam nedir: yalnızca açılan pencerede mi, menü çubuğu simgesinin kendisinde mi?

## Mevcut durum
Yapılan işler:
- `App/KeelApp.swift:68-72`: `MenuBarExtra("Keel", systemImage: "gauge.with.dots.needle.33percent", isInserted: .constant(menuBarVisible))` kullanılıyor, stil `.window`. Etiket statik bir SF Symbol. Simgede canlı veri yok.
- `App/MenuBar/MenuBarContent.swift:5-106`: Açılan pencere 260 pt genişliğinde. Şunları gösteriyor:
  - CPU, bellek ve disk için `StatRow` (başlık + tek değer + `ProgressBar`, satır 18-31).
  - Sıcaklık ve fan metni (33-42).
  - Ağ metni "↓ x ↑ y" (44-51, 81-87).
  - "Keel'i aç" ve "Çıkış" düğmeleri.
  - Grafik yok, geçmiş verisi kullanılmıyor.
- `App/SystemStatus.swift` ölçümü yapan tek kaynak, `@MainActor @Observable`:
  - 2 sn'lik döngü (satır 44, 66-79). Disk ve pil 30 sn'de bir (`slowEvery = 15`), sıcaklık 4 sn'de bir (satır 75).
  - Ölçümler `Task.detached(priority: .utility)` ile ana iş parçacığı dışında yapılıyor (128-130). Her iş türünden aynı anda en fazla biri çalışıyor (97-126).
  - Geçmiş dizileri zaten var (satır 35-42): `cpuHistory`, `gpuHistory`, `diskReadHistory`, `diskWriteHistory`, `networkInHistory`, `networkOutHistory`, `cpuTemperatureHistory`. Uzunluk `historyLength = 30` (satır 9), yani yaklaşık 60 sn.
  - Bellek için geçmiş dizisi yok. `memory` yalnızca son değeri tutuyor (satır 15, 137).
  - Döngü uygulama açıldığında başlıyor ve hiç durmuyor. Pencere ya da menü kapalıyken de çalışıyor. Pencere görünürlüğüne göre hız ayarı yok (`grep` ile doğrulandı).
- `App/Features/Performance/PerformanceView.swift:154-179`: `Sparkline` görünümü 30 çubuk çiziyor, yüksekliği 56 pt. Dosyaya özel (`private struct`), menü çubuğundan kullanılamıyor. Performans ekranı CPU/GPU/disk/ağ/sıcaklık için kullanıyor (satır 341, 366, 469-470, 510-511, 548).
- Ölçüm okuyucuları `Packages/KeelCore/Sources/KeelCore/System` ve `Hardware` altında: `CPUReader`, `MemoryReader`, `NetworkReader`, `StorageReader`, `GPUReader`, `SensorReader`. Hepsi salt okur. Ölçümün kendisi (host_statistics, getifaddrs, IOKit) `#if os(macOS)` arkasında.
- Test durumu: `Packages/KeelCore/Tests` altında menü çubuğu ya da geçmiş (ring buffer) için test yok. Geçmiş mantığı `SystemStatus.appending` (satır 196-198) içinde, `App/` katmanında, yani Linux'ta test edilemiyor.
- `Preference.menuBarVisible` (`App/Navigation/AppNavigation.swift:12`) menü çubuğu simgesini açıp kapatıyor. `SettingsView.swift:32` anahtarı. Başka menü çubuğu ayarı yok.

Yazılmayanlar:
- Simge üzerinde canlı değer ya da grafik yok.
- Menü çubuğuna özel güncelleme hızı yok.
- Menü çubuğu için ayrı bir `Package.swift` hedefi ya da bağımlılık yok.

Eski kararlar:
- `docs/mahkeme/` altında bu konuyla ilgili karar yok. Mevcut üç kayıt kopya dosya bulucu (2026-10-27), sahipsiz artıklar (2026-10-28) ve uygulama güncelleyici (2026-10-29).
- Üçünde de aynı soru sahibe bırakıldı: Faz 2 açık maddelerinden hangisi önce? Bu madde o listede açıkça geçiyor (`GUNDEM.md:25`, `:35`). `GUNDEM.md` "Cevap:" satırları boş.
- Güncelleyici kararının (satır 3-12) kalıbı: "ölçülmemiş şeyi önce ölç, öncelik insana ait". Aynı ilke bu davada da geçerli olabilir. Bu bir tahmin, kararı hakime ait.

## İlgili kurallar
PLAN.md §2 güvenlik ilkeleri bu özelliğe doğrudan değmiyor. Özellik salt okunur, silme yok, yeni yol yok, ağ yok. Dolaylı olarak ilgili olanlar:
- §2.8: Root yok. Mevcut okuyucular root gerektirmiyor. Yeni bir okuma kaynağı eklenirse bu korunmalı.
- §1 "Bağımlılık: mümkün olduğunca sıfır". Swift Charts sistem çerçevesi (macOS 13+), yeni dış bağımlılık sayılmaz. Bu yorum doğrulanmadı, hakime ait.
- §1 "Minimum macOS 14": Bu sürümde `MenuBarExtra` olgun sayılıyor.
- §4 "Menü çubuğu durum göstergesi": `App/MenuBar/` altında.
- CLAUDE.md: Mantık `KeelCore`'da, arayüz `App/`'te, `project.yml` proje ayarı için. Mahkeme zorunluluğu: "yeni özellik ya da yol haritası maddesi" (bu dava). Silme, `SafetyPolicy`, yönetici yetkisi ve Keel AI veri akışına dokunmuyor.
- PLAN §5 Faz 1 satır 111 "Menü çubuğu: CPU / RAM / disk boş alanı" ve Faz 2 satır 118 "ağ hızı" tamamlandı. Bu madde onların grafikli devamı.
- Keel AI veri akışı: Bu özellik geçmiş verisini Keel AI'ya göndermiyor. Gönderilmesi ayrı bir karar gerektirir (PLAN satır 154).

## Dış araştırma
- Stats (exelban, MIT lisanslı) menü çubuğu monitörlerinin başlıca rakibi. README'de "en verimsiz modüller Sensors ve Bluetooth", kapatmak bazı durumlarda CPU ve güç kullanımını %50'ye kadar azaltabilir deniyor. Widget türleri ve güncelleme aralığı README'de belirtilmiyor, doğrulanmadı. Kaynak: https://cdn.jsdelivr.net/gh/exelban/stats@master/README.md
- Keel'de sensörler zaten 4 sn'de bir okunuyor (`SystemStatus.swift:75`). Stats'ın bu uyarısı Keel için de geçerli olabilir, ölçülmedi.
- Menü çubuğu öğelerinin sürekli yeniden çizilmesi maliyetli olabiliyor. Control Center, saat ayırıcıları saniyede bir yanıp sönerken yaklaşık %3 CPU kullanmış, kapatınca yaklaşık %0,1'e inmiş. Topluluk bildirimi, resmi ölçüm değil. Kaynak: https://mjtsai.com/blog/2023/10/04/control-center-in-macos-always-using-cpu
- Bu bulgu SwiftUI tabanlı menü çubuğu etiketinin sık güncellenmesinin maliyetli olabileceğini düşündürüyor. Keel'in kendi `MenuBarExtra` etiketi için ölçülmedi, doğrulanmadı.
- `MenuBarExtra` etiketinde özel görünüm (grafik) kullanımının sınırları (yazı tipi boyutu, dinamik görsel, `ImageRenderer` ile görüntü üretme) Apple forumlarında ve topluluk yazılarında tartışılıyor. Arama sonuçları doğrulanmadan bırakıldı, hiçbir sayfa açıp okumadım. Doğrulanmadı. Bakılacak kaynaklar:
  - https://developer.apple.com/forums/thread/726565
  - https://developer.apple.com/forums/thread/688917
  - https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI
  - https://developer.apple.com/documentation/swiftui/menubarextra
- iStat Menus ve CleanMyMac menü çubuğunun grafik biçimi ve güncelleme hızı araştırılmadı, doğrulanmadı.
- Enerji etkisi için Keel'e özel ölçüm yok (Instruments / Activity Monitor "Energy Impact"). Linux ortamında yapılamıyor.

## Seçenekler

**A. Hiç yapmamak / ertelemek.**
- Ne: PLAN.md satır 122'ye gerekçeli erteleme notu. Menü çubuğu bugünkü gibi kalır (çubuklar + metin).
- Dosyalar: `docs/PLAN.md`.
- Büyüklük: çok küçük.
- Not: Mevcut pencere zaten CPU/RAM/disk/ağ/sıcaklığı gösteriyor, ayrıntılı grafikler Performans ekranında var. Eksik olan yalnızca menü çubuğuna özel grafik.

**B. Yalnızca açılan pencerede mini grafikler (simge değişmez).**
- Ne:
  - `Sparkline` ortak bileşene taşınır, `MenuBarContent` içinde CPU, ağ ve (isteğe bağlı) disk satırlarına küçük grafik eklenir.
  - Mevcut geçmiş dizileri kullanılır. Bellek geçmişi için `SystemStatus`'a yeni bir dizi eklenir.
  - Pencere yalnızca kullanıcı menüyü açınca çizilir. Ek ölçüm yükü yok, döngü aynı.
- Dosyalar: `App/MenuBar/MenuBarContent.swift`, `App/Features/Performance/PerformanceView.swift` (Sparkline taşınır) ya da `App/DesignSystem/Components.swift`, `App/SystemStatus.swift`.
- Büyüklük: küçük (yaklaşık 100-150 satır).
- Test: Görsel kısım `App/`'te, Linux'ta test edilemez. Geçmiş kırpma mantığı `KeelCore`'a (ör. `RollingHistory`) alınırsa Linux testi yazılabilir, bu eklenirse orta.

**C. Menü çubuğu simgesinde canlı grafik (ör. CPU mini çubuk grafiği, ağ oku).**
- Ne:
  - `MenuBarExtra` etiketi statik simge yerine canlı görünüm olur (SwiftUI görünümü ya da `ImageRenderer` ile üretilmiş `NSImage`).
  - Kullanıcı hangi göstergenin görüneceğini seçer. Ayarlara anahtar eklenir.
  - Güncelleme hızı düşünülmeli. Simge her 2 sn'de yeniden çiziliyor olur, pencere kapalıyken de.
- Dosyalar: `App/KeelApp.swift`, `App/MenuBar/` altında yeni etiket görünümü, `App/Features/Settings/SettingsView.swift`, `App/Navigation/AppNavigation.swift` (`Preference`), `App/SystemStatus.swift`.
- Büyüklük: orta. Asıl belirsizlik teknik: etiket görünümünün sınırları ve enerji maliyeti doğrulanmadı.
- Risk: Menü çubuğu simgesi sürekli güncellenir. Enerji ve CPU maliyeti Mac'te ölçülmeden bilinmiyor. Çentikli ekranlarda menü çubuğu alanı sınırlı, simge genişliği sorun olabilir (doğrulanmadı).

**D. B + C'nin kademeli yolu: önce B, simge grafiği ayrı karar.**
- Ne: Önce B uygulanır. C için, Mac'te ölçümle (Activity Monitor / Instruments) menü çubuğu etiketinin enerji maliyeti belirlenir, sonra ayrı mahkeme kurulur.
- Ek: Pencere kapalıyken ölçüm hızını düşürmek (ör. 2 sn yerine 5-10 sn) de bu aşamaya eklenebilir. Bu `SystemStatus` döngüsünü değiştirir, Performans ekranını da etkiler.
- Dosyalar: B'dekiler + (isteğe bağlı) `SystemStatus.swift`.
- Büyüklük: B kadar, C ayrı.

## Bilinmenekler
1. Faz 2 öncelik sorusu cevapsız (`GUNDEM.md`, 3 davada). Bu madde sahip tarafından öncelikli sayılıyor mu?
2. "Canlı grafik" ile kastedilen nedir? Açılan penceredeki mini grafik mi (B), menü çubuğu simgesinin kendisi mi (C)? PLAN satırı bunu ayırmıyor.
3. Menü çubuğu etiketinde dinamik grafik (SwiftUI görünümü ya da `ImageRenderer`) macOS 14'te güvenilir mi, hangi kısıtlar var? Apple dokümantasyonundan doğrulanmadı.
4. Menü çubuğu etiketini 2 sn'de bir güncellemenin Keel'e ait enerji ve CPU maliyeti nedir? Mac'te ölçülmeden bilinmiyor.
5. Ölçüm döngüsü şu an menü ya da pencere kapalıyken de 2 sn'de bir çalışıyor. Bu özelliğin yükünü artırması beklenmiyor (B için), ama C'de görünür olacak. Yapılacaksa döngü hızı pencere durumuna bağlansın mı?
6. Çentikli (notch) ekranlarda menü çubuğu öğesi genişliği ve simgenin gizlenme riski doğrulanmadı.
7. Bellek için geçmiş verisi yok. Eklenirse "kullanılan bellek" mi, "bellek baskısı" mı grafiğe girer? PLAN satır 54'ün çizgisine göre baskı daha anlamlı olabilir (yorum, karar hakime ait).
8. Rakiplerin (iStat Menus, CleanMyMac) widget biçimleri ve güncelleme aralıkları incelenmedi.
9. Geçmiş mantığının (`SystemStatus.appending`) `KeelCore`'a taşınıp taşınmayacağı: CLAUDE.md "mantık KeelCore'da" der, ama bugünkü kod `App/`'te. Taşınırsa mevcut Performans ekranı da etkilenir.

Dosya yolları (okunanlar):
- /home/claude/keel/docs/PLAN.md
- /home/claude/keel/docs/mahkeme/GUNDEM.md
- /home/claude/keel/docs/mahkeme/2026-10-29-uygulama-guncelleyici/karar.md
- /home/claude/keel/App/KeelApp.swift
- /home/claude/keel/App/MenuBar/MenuBarContent.swift
- /home/claude/keel/App/SystemStatus.swift
- /home/claude/keel/App/Features/Performance/PerformanceView.swift
- /home/claude/keel/App/Navigation/AppNavigation.swift
- /home/claude/keel/App/Features/Settings/SettingsView.swift

Not: README.md'yi ayrıca okumadım (CLAUDE.md ve PLAN.md yeterliydi). Hiçbir dosyayı değiştirmedim.
