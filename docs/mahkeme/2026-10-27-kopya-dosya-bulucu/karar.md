# Karar: Kopya dosya bulucu (PLAN §5 Faz 2, satır 124)

**KARAR:** DEĞİŞTİRİLEREK KABUL (Seçenek B, daraltılmış hâliyle ve şartlara bağlı. C ile D reddedildi.)
**İNSAN ONAYI GEREKİR:** EVET. Kural 4'teki maddelerin hiçbiri doğrudan devreye girmiyor: yeni bağımlılık yok, `SafetyPolicy` kuralları değişmiyor, kalıcı silme yok, veri cihaz dışına çıkmıyor. Yine de iki karar yalnızca kullanıcıya ait ve ikisi de henüz verilmedi:
1. Faz 2'deki açık maddeler arasında öncelik sırası.
2. Adım 0 ölçümünün kullanıcının kendi Mac'inde, kendi ev klasöründe çalıştırılması ve eşiğin onaylanması.

Kullanıcı bu ikisini yazılı olarak bildirmeden ajanlar Adım 0 dahil hiçbir kod yazmaz.

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 4 | HAYIR |
| Sıradan Mac kullanıcısı | KOŞULLU | 3 | HAYIR |
| Kıdemli Swift mühendisi | KOŞULLU | 4 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KOŞULLU | 3 | HAYIR |

Sonuç: 5 KOŞULLU, veto yok. Jürilerin koşulları büyük ölçüde örtüşüyor. Kararın şartları bu ortak noktaların toplamıdır. Çeliştikleri yerlerde (öneri etiketi, ölçüm eşiği) daha sıkı olan seçildi.

## Gerekçe

**Neden RED değil?** PLAN §2'deki ilkelerin hiçbiri ihlal edilmiyor. Bu tespit güvenlik jürisinin (güven 4) değerlendirmesine dayanıyor ve kodla da tutarlı:
- Silme `FileRemover.moveToTrash` ile Çöp'e gidiyor.
- `SafetyPolicy` değişmiyor.
- Geri alma `TrashRestorer` ile zaten var.

Kullanıcı jürisinin anlattığı ihtiyaç gerçek: tekrar indirilmiş DMG, PDF ve video dosyaları. Bu iş için yeni bağımlılık da gerekmiyor.

**Neden doğrudan KABUL değil?** Savunmanın önerisinde dört boşluk var. Beş jürinin dördü bunları bağımsız olarak aynı şekilde tespit etti:
1. Kalan kopyanın içeriği silme anında doğrulanmıyor.
2. Bulut kuralı kod olarak yazılmamış.
3. Politika kopyalanıyor.
4. Paket tespiti uzantı listesine dayanıyor.

**Savcının en güçlü argümanı: Risk 3, "hayatta kalacak kopya da silme anında doğrulanmalı".** Kabul edildi. Bu davanın en önemli güvenlik noktası budur. Savunma yeniden doğrulamada "boyut ve değişiklik tarihi"ni yeterli saydı. Güvenlik jürisinin belirttiği gibi tarih ve boyut içeriği kanıtlamaz. Tarama ile onay arasında değişen bir kopya bu kontrolden geçer ve kullanıcının tek gerçek kopyası "yedeği var" güvencesiyle Çöp'e gider. Bu nedenle bayt bayt karşılaştırma `DuplicateRemover` içinde, arayüzden bağımsız olarak zorunludur. Silinecek dosyalar koruyucu kopya olarak sayılamaz. Savcının ikinci güçlü noktası olan "X GB kazanılır" iddiası da kabul edildi. PLAN §3'teki "uydurma sayı" kuralı burada da geçerlidir. macOS jürisine göre APFS'te paylaşılan blokları sorgulamanın public bir yolu yok. Bu yüzden kazanç yalnızca "en fazla" ifadesiyle ve klon uyarısıyla gösterilir.

**Savcının reddedilen kısmı:** Savcı "önce kanıtlanmalı" dediği üç şeyden biri olarak gerçek kazancın ölçülebilmesini istedi. Bu teknik olarak mümkün değil. Bunun yerine savcının kendi sunduğu geri çekilme yolu benimsendi: özellik "en fazla" kazançla ve dürüst bir etiketle sunulur.

**Avukatın en güçlü argümanı: "Adım 0, ucuz ve salt okunur bir ölçüm. Sonuç küçükse madde dürüstçe kapatılır".** Kabul edildi. Beş jürinin dördü ölçümü şart koştu. Bu yaklaşım "yap" ile "yapma" arasındaki tartışmayı kanıtla çözüyor. Avukatın bayt bayt karşılaştırma önerisi de kabul edildi. CryptoKit, Linux ve swift-crypto sorununu bağımlılık eklemeden ortadan kaldırıyor ve çakışma riski bırakmıyor.

**Avukatın reddedilen iddiaları:**
- "Faz 2'de açık duran tek madde" iddiası olgu olarak yanlış. `docs/PLAN.md` içinde 119, 120, 122 ve 144. satırlar da açık.
- "Yeni güvenlik yüzeyi açılmaz" iddiası yanlış. Yeni bir silici, yeni bir silme yüzeyidir.
- "Varsayılan orijinal önerisi" (en eski ya da en kısa yol) reddedildi. Güvenlik jürisi ve kullanıcı jürisi, önceden işaretlenen bir seçimin onayı anlamsız bir tıklamaya dönüştürdüğünü söyledi. İlk sürümde öneri etiketi de olmayacak, böylece "hangisi orijinal" ürün sorusu hiç açılmıyor.
- `ATTR_CMNEXT_*` / `fcntl` ile klonları ayırt etme denemesi bu kararın kapsamında değil (macOS jürisinin koşulu).

**Ürün jürisinin öncelik şartı nasıl ele alındı?** Ürün jürisi, mahkemenin önceliği yazılı olarak belirlemesini ve bu belgelenmeden kodlamaya geçilmemesini istedi. Mahkeme şartın amacını kabul ediyor, ancak öncelik sırasını kullanıcı adına belirlemiyor. Faz 2'deki maddeler arasındaki sıra bir ürün sahibi kararıdır ve kullanıcı henüz tercih bildirmedi. Bir ajanın ya da mahkemenin bu boşluğu kendi tahminiyle doldurması, kullanıcının onayını uydurmak olur. Mahkemenin yazılı değerlendirmesi şöyledir:
- Kopya bulucunun diğer açık maddelere (sahipsiz artıklar, uygulama güncelleyici, menü çubuğu grafikleri, LaunchAgent aç/kapat) karşı **kendiliğinden bir önceliği yoktur**.
- Önceliği ancak iki koşul birlikte sağlanırsa kazanır: kullanıcı onu seçer ve Adım 0 aşağıdaki eşiği geçer.

Bu nedenle `İNSAN ONAYI GEREKİR: EVET` yazıldı. Kod yazılmadan önce kullanıcıya şu sorular sorulur:
- (a) Faz 2'deki açık maddelerden hangisi önce yapılsın?
- (b) Adım 0'ı kendi Mac'inizde çalıştırmayı kabul ediyor musunuz?
- (c) Önerilen eşik uygun mu?

Önerilen eşik ürün jürisinin teklifinden uyarlandı. Klonlar ayırt edilemediği için "ayrışmış kopya" ölçülemez, bu yüzden eşik ölçülebilir hâle getirildi. Ölçüm 1 MB üstündeki dosyaları kapsar. Özelliğe devam edilmesi için üç koşulun tamamı sağlanmalıdır:
- "En fazla" kazanç en az 1 GB olmalı.
- En az 20 kopya grubu bulunmalı.
- İptal edilebilir tam tarama süresi kullanıcının kabul edebileceği bir sürede bitmeli. Süre kaydedilir, karar kullanıcınındır.

Eşik geçilmezse Seçenek A uygulanır: madde PLAN'da "yapılmayacak (ölçüm: ...)" notuyla kapatılır.

## Uygulama planı

Bu plan yalnızca kullanıcı (a), (b) ve (c) sorularını yanıtladıktan ve kopya bulucuyu sıraya aldıktan sonra yürürlüğe girer.

0. **Adım 0: ölçüm (birleşmez).**
   - Adım 1'deki salt okunur `DuplicateFinder` ve bunu çağıran geçici bir ölçüm aracı ayrı bir dalda yazılır. Ölçüm aracında silme yolu yoktur. Bulut ve paket kuralları ölçümde de uygulanır.
   - Kullanıcı aracı kendi Mac'inde iki durumda çalıştırır: iCloud "Masaüstü ve Belgeler" açıkken ve kapalıyken (mümkünse).
   - Dava klasörüne yalnızca toplam sayılar yazılır: grup sayısı, "en fazla" bayt, süre ve en yüksek bellek kullanımı. **Dosya yolları ve adları repoya yazılmaz.**
   - `swift build` ve `swift test` Linux'ta denenir.
   - Eşik geçilmezse süreç burada durur ve PLAN satır 124 "yapılmayacak" notuyla kapatılır.

1. **Ortak politika.** `LargeFileRemover.policy(home:)` içindeki yapılandırma ortak bir türe taşınır. Ad önerisi: `UserFilesPolicy`, konum `Safety/` altında.
   - `LargeFileRemover` ve `DuplicateRemover` bu türü kullanır.
   - Korunan yol listesinin içeriği birebir aynı kalır. `SafetyPolicy.swift` dosyasına dokunulmaz.
   - Dosyalar: `LargeFiles/LargeFiles.swift`, yeni `Safety/UserFilesPolicy.swift`.
   - Test: Her iki silicinin politikasının aynı izinli kökü ve aynı korunan kökleri ürettiği doğrulanır. Mevcut 7 `LargeFilesTests` testi değişmeden geçer.

2. **Ortamdan soyutlama.** Bulut ve paket tespiti bir protokolün arkasına alınır (örneğin `FileTraits`). Linux testleri sahte bir uygulamayla koşar.
   - macOS uygulaması `isUbiquitousItem`, `ubiquitousItemDownloadingStatus` ve `isPackageKey` kullanır. Yedek kural olarak klasörde `Contents/Info.plist` bulunup bulunmadığına bakılır.
   - Bilinen bulut kökleri varsayılan olarak atlanır: `~/Dropbox`, `~/OneDrive*`, `~/Google Drive`. `~/Library/CloudStorage` zaten `Library` kuralıyla dışarıda.
   - iCloud ile senkronlanan `~/Desktop` ve `~/Documents` varsayılan olarak atlanır ve bu durum kullanıcıya bildirilir.
   - Dosyalar: yeni `Duplicates/FileTraits.swift`.
   - Test: Dataless ya da senkronlu olarak işaretlenen bir dosya listelenmez ve **hiç açılmaz**. Sahte uygulama okuma çağrılarını sayar ve sayının 0 olduğu doğrulanır.

3. **`DuplicateFinder`, salt okunur.**
   - Kök kuralları `LargeFileScanner` ile aynıdır: `Library`, `Applications`, `.Trash`, gizli dosyalar ve sembolik linkler dışarıda kalır.
   - Paket tespiti 2. adımdaki genel kurala göre yapılır. Paket içindeki dosyalar gruplanmaz.
   - Asgari boyut 1 MB'dır.
   - Gruplama kademeleri: önce boyut, sonra baştaki ve sondaki blokların bayt karşılaştırması, sonra tam bayt karşılaştırma. Gruplamayı hızlandırmak için standart kütüphaneyle yazılmış kriptografik olmayan bir özet kullanılabilir. Son karar her zaman bayt bayt karşılaştırmayla verilir.
   - Aynı (birim, inode) çiftine sahip adlar tek öğe sayılır ve birbirinin kopyası olarak sunulmaz. Farklı birimlerdeki dosyalar aynı gruba girmez.
   - Tarama iptal edilebilir.
   - Dosyalar: `Duplicates/DuplicateFinder.swift`.
   - Testler: gerçek kopyalar gruplanır; boyutu aynı ama içeriği farklı dosyalar gruplanmaz; hard link kopya sayılmaz; bilinmeyen uzantılı bir paketin içindeki aynı dosyalar listelenmez; 1 MB altı dosyalar atlanır; sembolik link ve gizli dosya atlanır.

4. **`DuplicateRemover`.** Girdi, grup başına açıkça belirtilen bir koruyucu kopya ve silinecek dosyaların listesidir. Koruyucu kopya, aynı çağrıdaki silinecekler kümesinin dışında olmak zorundadır. Bir grubun tamamı seçilmişse işlem reddedilir. Her dosya için silme anında şu kontroller yapılır:
   - Dosya var mı, `UserFilesPolicy` ve `SafetyPolicy.evaluate` izin veriyor mu?
   - Sembolik link çözülmüş gerçek konum neresi? Normal dosya mı?
   - Üst klasörlerden biri paket mi? Yol `~/Library` altında mı? (İkisi de reddedilir.)
   - Dosya bulut dosyası mı? (Reddedilir.)
   - Dosya koruyucu kopyayla aynı birimde mi, farklı inode'da mı?
   - Koruyucu kopya var mı, politikadan ve sembolik link çözümünden geçiyor mu?
   - Dosya ile koruyucu kopyanın **içeriği bayt bayt aynı mı**?

   Kontrollerden biri başarısız olursa o dosya atlanır. Sonra `FileRemover.moveToTrash` çalışır. `ActionLog`'a her atlama, ret ve başarılı silme yazılır. Başarılı silmelerde doğrulanan koruyucu kopyanın yolu da kayda geçer. Geri alma için `TrashedItem` döndürülür.
   - Dosyalar: `Duplicates/DuplicateRemover.swift`, `Tests/.../DuplicatesTests.swift`.
   - Testler (her biri ret beklenir): koruyucu kopya kaybolmuş; koruyucu kopya aynı boyutta ama farklı içerikte; silinecek dosya taramadan sonra değişmiş; grubun tamamı seçilmiş; iki dosya birbirini koruyucu olarak göstermiş; koruyucu ile aday aynı inode'da; korunan yol, `.app` içi, sembolik link ya da başka disk; paket içi; `~/Library` altı. Ayrıca başarılı Çöp'e taşıma ve `ActionLog` kaydı (koruyucu yol dahil) test edilir.

5. **Kazanç metni.** KeelCore'da tek bir biçimlendirici olur. Çıktı her zaman "en fazla ~X (APFS klonları yer açmayabilir)" biçimindedir.
   - Test: Çıktıda "en fazla" ve klon uyarısı vardır. "Kazanılır" ya da kesin bir GB iddiası yoktur.

6. **Arayüz.**
   - Yeni dosyalar: `App/Features/Duplicates/DuplicatesModel.swift` ve `DuplicatesView.swift`. `LargeFilesModel`'deki fazlar kullanılır (idle, scanning, ready, removing, undo, reveal).
   - Bağlantı yalnızca `RootView.swift`, `KeelApp.swift` ve kenar çubuğu üzerinden yapılır.
   - Hiçbir dosya önceden seçili gelmez. "Hepsini seç" ya da grup bazında toplu işaretleme yoktur. Öneri etiketi yoktur.
   - Kullanıcı her grupta koruyucu kopyayı kendisi belirler.
   - Onay ekranı Çöp'e gidecek dosyaların sayısını, yollarını ve boyutlarını listeler.
   - TCC izni olmayan klasörler atlanır ve kullanıcıya bildirilir.
   - Test: Mantığın tamamı KeelCore'da olduğu için Linux testleriyle kapsanır. Arayüz kullanıcının Mac'inde elle denenir.

7. **Belgeler.** PLAN satır 124 işaretlenir (ya da A seçildiyse not düşülür). `docs/mahkeme/README.md` karar tablosuna bu karar eklenir.

## Kabul kriterleri
- [ ] Kullanıcının öncelik tercihi ve eşik onayı yazılı olarak dava klasöründe kayıtlı. Kod bundan sonra başladı.
- [ ] Adım 0'ın toplam sonuçları dava klasöründe; dosya yolu ya da adı içermiyor. Eşik geçildi. Ölçüm aracı birleştirilmedi.
- [ ] `swift test --package-path Packages/KeelCore` Linux'ta geçiyor. Mevcut 7 `LargeFilesTests` testi değiştirilmeden geçiyor.
- [ ] `Package.swift` dosyasına yeni bağımlılık eklenmedi. CryptoKit ve swift-crypto kullanılmadı.
- [ ] `Safety/SafetyPolicy.swift` değişmedi. Korunan yol listesi tek yerde tanımlı ve iki silici de onu kullanıyor (testli).
- [ ] Uygulama planının 2-5. adımlarında sayılan testlerin tamamı var ve geçiyor.
- [ ] Koruyucu kopyanın varlık ve bayt bayt içerik kontrolü `DuplicateRemover` içinde yapılıyor, arayüze bağlı değil.
- [ ] Dataless, senkronlu ve bulut dosyaları taramada hiç açılmıyor (sahte uygulamada okuma sayısı 0).
- [ ] Paket tespiti uzantı listesine dayanmıyor.
- [ ] Arayüzde ve kodda "kazanılır" ya da kesin kazanç ifadesi yok, klon uyarısı her yerde var.
- [ ] `SmartCare.swift`, `KeelTools.swift` ve `AssistantModel.swift` değişmedi.
- [ ] Önceden seçim, "hepsini seç" ya da grup bazında toplu işaretleme yok. Onay ekranında yollar listeleniyor.

## Kapsam dışı
- **Seçenek C:** uygulama verisi, harici diskler, benzer görsel. **Seçenek D:** APFS klonuna çevirme. İkisi de reddedildi. D gündeme gelirse PLAN ile çeliştiği için insan onayı gerektirir.
- Akıllı Tarama (`SmartCare`) ve Keel AI (`KeelTools`, `AssistantModel`) entegrasyonu. Ayrı mahkeme kararı gerekir. Kopya grup bilgisi ve yollar Keel AI'ya hiçbir koşulda gönderilmez.
- `ATTR_CMNEXT_*` / `fcntl` ile klon ayrımı ve bu yoldan ürün metnine kesin kazanç yazılması.
- "Orijinal" önerisi ve otomatik koruyucu seçimi. Ürün kararı olarak ayrı ele alınır.
- swift-crypto ya da herhangi bir dış bağımlılık.
- `LargeFileScanner`'daki paket tespiti zayıflığının (sabit uzantı listesi) giderilmesi. Gerçek bir sorun, ancak ayrı bir düzeltme olarak ele alınmalı, bu işe karıştırılmamalı.
- Faz 2'deki diğer açık maddeler ve aralarındaki sıralama. Bu kullanıcının kararıdır.

---

Karar şu dosyalara dayanıyor: `/home/claude/keel/docs/mahkeme/2026-10-27-kopya-dosya-bulucu/dosya.md`, `iddianame.md`, `savunma.md`, `oylar.md`; `/home/claude/keel/docs/PLAN.md` (Faz 2 açık maddeleri: satır 119, 120, 122, 124, 144); `/home/claude/keel/Packages/KeelCore/Sources/KeelCore/LargeFiles/LargeFiles.swift` (`policy` satır 267, `packageExtensions` satır 121).
