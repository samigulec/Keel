# Dava dosyası: Kopya dosya bulucu

## Soru
Keel'e, içeriği aynı olan dosyaları bulup gösteren ve kullanıcı onayıyla Çöp Kutusu'na taşıyan bir özellik eklenmeli mi, eklenirse hangi kapsam ve sınırlarla?

## Mevcut durum
- Kopya bulucu yok. Repoda "kopya/duplicate" araması yalnızca PLAN.md:124, mahkeme README'si ve ajan tanımlarında çıkıyor. İçerik karması (CryptoKit, SHA vb.) kullanan kod da yok. `Package.swift` bağımlılıksız (yalnızca kendi `KeelSystemShims` hedefi var).
- En yakın örnek `LargeFileScanner` (`Packages/KeelCore/Sources/KeelCore/LargeFiles/LargeFiles.swift:67-221`).
  - Ev klasörünü gezer. `Library`, `Applications` ve `.Trash` atlanır (satır 74).
  - Gizli dosyalar, paketler (`packageExtensions`, satır 121) ve `standardProtectedRoots` atlanır (satır 161-185).
  - Sembolik linkler ve klasörler listelenmez (satır 193-194).
  - İsteğe bağlı olarak `~/Library` altındaki uygulama verilerine de bakar. Apple'ın verileri (`com.apple.*`, `MobileSync` vb.) hariçtir (satır 82-116).
  - Boyut için `totalFileAllocatedSize` kullanır (satır 213-220).
- `LargeFileRemover` (satır 245-342) silmeyi yapar. Her dosya için şunlar kontrol edilir:
  - Dosya hâlâ var mı.
  - `SafetyPolicy.evaluate`.
  - Sembolik linkler çözülerek gerçek konum.
  - Library içinde ise uygulama verisi mi, "essential" (program/veritabanı) mi, uygulaması açık mı.
  - Hâlâ normal dosya mı.
  - Sonra `FileRemover.moveToTrash` çalışır, `ActionLog`'a yazılır ve `TrashedItem` geri alma için döner.
- `LargeFileRemover.policy` (satır 267-273) izin verilen kök olarak tüm `home`'u alır. Korunanlar `standardProtectedRoots` + `Applications` + `.Trash`'tir. `SafetyPolicy` (`Safety/SafetyPolicy.swift:57-99`) şunları reddeder:
  - Korunan yollar.
  - `.app` içi.
  - Farklı diskteki öğe.
  - İzinli kökün kendisi.
- Geri alma `TrashRestorer` (`Actions/TrashRestorer.swift:33-88`) ile yapılır. Eski yerde aynı adlı öğe varsa geri koymaz.
- Arayüz kalıbı: `App/Features/LargeFiles/LargeFilesModel.swift`. Fazlar `idle/scanning/ready/removing`, `Task.detached` ile tarama, seçim, `removeSelected`, `undoLastRemoval`, `reveal`, `open`. Model şu yerlerde bağlı:
  - `App/KeelApp.swift:11,26`
  - `App/Navigation/RootView.swift:7,99`
  - `SmartScan/SmartCare.swift`
  - Asistan: `KeelTools.swift:55,223`, `AssistantModel.swift:93`
- Testler: `LargeFilesTests.swift` 7 test içeriyor. Bunlar tarama, Çöp'e taşıma ve reddetme, uygulama verisi, açık uygulama, essential dosya, kaybolmuş dosya ve sahip eşleştirmeyi kapsıyor.

## İlgili kurallar
- PLAN §2.1: Kalıcı silme yok, her şey `trashItem` ile Çöp'e gider.
- §2.2: Tarama salt okunur. Silme yalnızca onaydan sonra ve yalnızca seçilenler için olur.
- §2.3: Allowlist, tek kapı `SafetyPolicy`.
- §2.4: Korunan yollar (`/System`, `.app` içi, iCloud Drive, Fotoğraflar/Mail/Mesajlar, Keychain).
- §2.5: Sembolik link takip edilmez, başka diske taşan yol silinmez.
- §2.6: Çalışan uygulamanın verisine dokunulmaz.
- §2.7: Her işlem `~/Library/Logs/Keel/` altında kaydedilir.
- §1: Bağımlılık "mümkün olduğunca sıfır".
- §5 Faz 2: "- [ ] Kopya dosya bulucu" açık madde. "Büyük ve eski dosyalar bulucu" ve "Geri al" tamamlanmış.
- §5 Faz 4 sonu: Koruma (zararlı yazılım) bilinçli olarak dışarıda tutuldu. İlke: yarım yapılan, yanlış güven verir.
- CLAUDE.md: Yeni özellik ve silme işi mahkeme için zorunlu. `SafetyPolicy`'ye dokunulursa da zorunlu.
- Eski karar: `docs/mahkeme/README.md` karar tablosu boş. Bu konu daha önce yargılanmadı.

## Dış araştırma
- APFS klonları (doğrulandı, [Eclectic Light](https://eclecticlight.co/2023/04/22/should-you-remove-duplicate-files/)):
  - Finder kopyaları ve çoğu uygulama kopyası aynı APFS biriminde klondur. Klonlar veri bloklarını paylaşır.
  - Klon silinince çoğunlukla neredeyse hiç yer açılmaz. Yalnızca ayrışmış blokların yeri açılır.
  - Klonları gerçek kopyalardan ayırmanın resmi bir yolu yok. Yardımcı programlar yer kazandırmayan "kopyaları" önerebilir.
  - Hard link'ler ayrı bir durum: aynı inode'a giden farklı isimler.
  - Sonuç: "X GB kazanılır" iddiası yanlış olabilir.
- Rakipler:
  - Gemini 2 (MacPaw) ve CleanMyMac kopya bulucu sunuyor ([Gemini 2 App Store](https://apps.apple.com/app/id1090488118)). Çalışma ayrıntıları okunmadı, doğrulanmadı.
  - Hyperspace silmek yerine kopyaları klona çeviriyor ([TidBITS](https://tidbits.com/2025/03/19/appbits-hyperspace-reclaims-space-used-by-identical-files/)). Boyut eşleşmesinden sonra üç kriptografik karma kullanıyor. Varsayılan olarak uygulama paketlerini ve iCloud/bulut dosyalarını yok sayıyor. Aynı anda tek APFS birimiyle çalışıyor. Bu bilgiler okuyucu özetine dayanıyor, tam doğrulanmadı.
- Teknik:
  - Karma için macOS'ta CryptoKit var (sıfır bağımlılık ilkesiyle uyumlu). `KeelCore` Linux'ta test ediliyor. CryptoKit Linux'ta yok, swift-crypto ayrı bağımlılık olur. Alternatif: Linux'ta Glibc/elle SHA-256 ya da karmayı `#if os(macOS)` arkasına almak. Doğrulanmadı, `swift build` ile denenmedi.
  - Standart kütüphane ile boyut + kısmi karma + tam karma kademeli karşılaştırma yapılabilir. Bayt bayt karşılaştırma bağımlılık gerektirmez.
- Sandbox: Keel App Store dışı dağıtılıyor (PLAN §1). Ev klasörünü okumak için izin sorunu beklenmiyor. Korunan klasörler (Belgeler, Masaüstü, İndirilenler) için macOS'un TCC izin istemleri çıkabilir, Full Disk Access onboarding'i zaten var (Faz 1). Doğrulanmadı.

## Seçenekler

**A. Hiç yapmamak / ertelemek.** PLAN'da maddeyi `- [ ]` bırakmak ya da "yapılmayacak" notuyla kapatmak.
- Dosya değişmez. Büyüklük: sıfır.
- Gerekçe olarak ileri sürülebilecekler: klon sorunu, yanlış yer kazanç iddiası, sırada başka açık maddeler (sahipsiz artıklar, uygulama güncelleyici, canlı menü çubuğu grafikleri, LaunchAgent aç/kapat).

**B. Dar kapsamlı sürüm: yalnızca kullanıcının kendi dosyaları, gerçek kazanç gösterilir.**
- Kapsam: Ev klasörü, `Library` hariç (yani `LargeFileScanner` ile aynı kök kuralları). Uygulama verisi, paketler, gizli dosyalar, sembolik linkler, iCloud ve bulut dosyaları dışarıda. Asgari boyut (örn. 1 MB). Aynı inode'a (hard link) giden dosyalar tek sayılır. Boyut → kısmi karma → tam karma kademesi. Klonlar çözülemiyorsa kazanç "en fazla" diye gösterilir.
- Yeni dosyalar: `KeelCore/Duplicates/DuplicateFinder.swift` ve `DuplicateRemover.swift` (Large Files'taki `LargeFileRemover` kalıbıyla, aynı `LargeFileRemover.policy` mantığı), `DuplicatesTests.swift`, `App/Features/Duplicates/DuplicatesView.swift` ve `DuplicatesModel.swift`.
- Değişen dosyalar: `RootView.swift`, `KeelApp.swift`, sidebar. İsteğe bağlı olarak `KeelTools.swift`.
- Kurallar:
  - Her gruptan en az bir kopya korunur. Kullanıcı hepsini seçemez, "hepsini seç" işlemi yoktur.
  - Silmeden hemen önce `FileRemover` yeniden doğrulama yapar: dosya hâlâ var mı, boyut ve karma hâlâ aynı mı.
  - `SafetyPolicy`, `ActionLog` ve `TrashRestorer` (geri al) yeniden kullanılır.
  - `SafetyPolicy` kodunun kendisi değişmez.
- Büyüklük: orta (yaklaşık 4-6 dosya, 600-900 satır, 10-15 test).

**C. Geniş kapsamlı sürüm: B + uygulama verisi, harici diskler, yinelenen fotoğraf/benzer görsel.**
- `SafetyPolicy` ve kök kuralları genişler, "benzer görsel" için ayrıca algı karması gerekir. Büyüklük: büyük. Güvenlik yüzeyi geniş (iCloud, Fotoğraflar kütüphanesi, harici diskler).

**D. Silme yerine klona çevirme (Hyperspace yaklaşımı).**
- Kopyalar APFS klonuyla değiştirilir (`clonefile`). Yer kazanılır, dosya kaybolmaz. Ancak mevcut ilkelere ("Çöp Kutusu'na taşı", "Geri al") uymaz, yeni bir geri alma yolu ve `SafetyPolicy` ilkesi gerekir. Büyüklük: büyük, PLAN ile çelişir, karar insana ait olur.

## Bilinmeyenler
- Kullanıcının makinesinde gerçek kopya oranı: Büyük ve Eski Dosyalar bulucusu gerçek veride kaç aynı boyutlu dosya gösteriyor? Bu ölçülmedi.
- Klon ile gerçek kopyayı ayırmanın uygulanabilir bir yolu var mı? Dosya sistemi düzeyinde (örn. `ATTR_CMNEXT_*` ya da `fcntl` ile paylaşılan blok sorgusu) doğrulanmadı. Yoksa "kazanılan alan" yalnızca üst sınır olarak gösterilebilir.
- Karma kitaplığı: macOS'ta CryptoKit, Linux CI'da (swift test) ne kullanılacak? Linux'ta CryptoKit yok. Derleme denenmedi.
- Büyük ev klasörlerinde tarama süresi ve bellek/G/Ç yükü (kısmi karma ile) ölçülmedi.
- Hangi dosyanın "orijinal" olarak korunacağı (en eski, en kısa yol, Belgeler dizini) ürün kararı. Kod bunu belirleyemez.
- Keel AI'nın yeni aracı görmesi gerekir mi? Görürse yalnızca dosya adları/yollar gider, içerik gitmez (PLAN "Keel AI" bölümü). Bu da mahkemede değerlendirilmeli.
- PLAN.md'de sıradaki diğer açık maddelere göre öncelik. Kullanıcının tercihi bilinmiyor.
