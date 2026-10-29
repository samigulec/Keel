# Karar: Uygulama güncelleyici (PLAN.md §5 Faz 2, satır 120)

**KARAR:** DEĞİŞTİRİLEREK KABUL. Bu karar yalnızca Aşama 0'ı kabul ediyor: ağa çıkmayan, salt okunur bir kaynak dağılımı ölçümü. Aşağıdakiler bu kararla **reddedildi**:
- Aşama 1, yani ağ ile sürüm kontrolü (Seçenek B ve C'nin ağ kısmı). Ölçüm sonucu ve doğrulanmış Sparkle şemasıyla ayrı bir mahkemede yeniden görülür.
- Seçenek D: Keel güncellemeyi indirip kurar.
- Seçenek E: sonuç Keel AI'ya gider.
- Sparkle çerçevesini bağımlılık olarak almak.

**İNSAN ONAYI GEREKİR:** EVET. Nedenleri:
- Faz 2 öncelik sorusu iki davadır cevapsız. Kopya dosya bulucu (2026-10-27) ve sahipsiz artıklar (2026-10-28) kararları bu soruyu sahibe bıraktı. `GUNDEM.md` "Bekleyen insan onayları" bölümünde ikisinin "Cevap:" satırı hâlâ boş. Bu dava aynı soruya bağlı. Beş jürinin beşi de öncelik kararı insana ait olmadan Aşama 1'e geçilmemesini istiyor.
- Aşama 1'de kurulu uygulama bilgisi (IP ile birlikte hangi uygulamaların kurulu olduğu) satıcı sunucularına gider. Bu, Kural 4'teki "kullanıcı verisinin cihaz dışına gönderilmesi" maddesine girer. Keel'in "ağa çıkmayan temizlik uygulaması" konumunu değiştirip değiştirmemek (Bilinmeyen 5) bir ürün kararıdır ve ajanlar bunu veremez.
- Aşama 0'ın tek değeri gerçek bir Mac'te ölçüm yapmasıdır. Bunu yalnızca sahip yapabilir ya da izin verebilir.

Sahip aşağıdaki soruları yanıtlamadan ajanlar kod yazmaz.

**Sahibe sorular:**
1. **Öncelik (üç davanın ortak sorusu):** Faz 2'de açık maddeler şunlar: sahipsiz artıklar, uygulama güncelleyici, menü çubuğu canlı grafikleri, kopya dosya bulucu ve LaunchAgent aç/kapat. Hangisi önce yapılsın? Bu madde için iki seçenek var:
   - (a) Aşama 0 şimdi yapılır.
   - (b) Madde, PLAN satır 120'ye gerekçeli bir erteleme notu düşülerek ertelenir (Seçenek A).
2. **Ortak ölçüm:** Bu davanın Aşama 0'ı ile sahipsiz artıklar davasının Aşama 0'ı aynı envanteri okuyor (`AppInventory`, Caskroom, Setapp ve Office gibi kaynaklar). İkisi tek bir ölçüm aracında, tek bir çalıştırmayla birleştirilsin mi? Benim önerim birleştirmek. Böylece kod tekrarı olmaz ve sahibin Mac'inde ölçüm bir kez yapılır.
3. **Ölçüm ortamı:** Aracı kendi Mac'inizde çalıştırıp çıktıyı gözden geçirmeyi kabul ediyor musunuz?
   - Hangi makinede (Apple Silicon mı Intel mi) ve hangi macOS sürümünde çalışacak?
   - Homebrew kurulu mu?
   - PLAN.md'ye yalnızca toplam sayıların yazılmasını onaylıyor musunuz? Uygulama adları repoya girmez.
4. **Eşik:** Aşama 1 mahkemesine gidebilmek için ne kadar kapsam gerekli? Ürün jürisi şunu önerdi: "üçüncü taraf uygulamaların en az yarısı kontrol edilebilir olmalı". Benim önerim bunu sıkılaştırıyor. Paydada yalnızca üçüncü taraf uygulamalar olsun (Apple ve sistem uygulamaları hariç). Payda yalnızca **HTTPS feed'i olan Sparkle** uygulamaları sayılsın, çünkü Aşama 1'in ağ kontrolü yalnızca onları kapsar. Homebrew Cask uygulamaları ağsız "güncel mi" bilgisi veremediği için paya girmez. Eşik %50 olsun; altında kalırsa Seçenek A'ya dönülür. Kabul ediyor musunuz?
5. **Ağ ilkesi (Aşama 1'e gelinirse):** Keel'in, kullanıcı açıkça açtığında ve yalnızca bir düğmeyle, satıcıların feed sunucularına istek atmasını ilke olarak kabul ediyor musunuz? Ağ kontrolü varsayılan olarak kapalı olacak. Cevap "hayır" ise ölçüm sonucu ne olursa olsun madde Seçenek A ile kapanır. Bu durumda Aşama 0 yapılmamalı; birleştirme kabul edildiyse yalnızca sahipsiz artıklar kısmı yapılır.

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 4 | HAYIR |
| Sıradan Mac kullanıcısı | KOŞULLU | 3 | HAYIR |
| Kıdemli Swift mühendisi | KOŞULLU | 3 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KOŞULLU | 3 | HAYIR |

Sonuç: 5 KOŞULLU, 0 RED, veto yok.

## Gerekçe

**Oyların tartılması.** Oylar oybirliğiyle KOŞULLU. Koşulların kesiştiği yer çok net. Beş jüri de şu beş noktada birleşiyor:
- (1) Önce ağsız ölçüm yapılmalı.
- (2) İnsan öncelik ve ağ kararını vermeden Aşama 1'e geçilmemeli.
- (3) D reddedilmeli.
- (4) E reddedilmeli.
- (5) Sparkle çerçevesi alınmamalı.

Güvenlik jürisi ve macOS jürisi (güven 4) Aşama 1 için ağır ve somut teknik şartlar koydu:
- **Bağlantı anında IP kontrolü.** Hedef adres istek atılırken çözümlenip yerel ve özel ağ aralıkları reddedilmeli. Yalnızca metin süzgeci yetmez, çünkü DNS yeniden bağlama ve yönlendirmeler bu süzgeci aşar.
- **Güvenli XML ayrıştırma.** Dış varlık (XXE) ve DTD işleme kapalı olmalı, boyut ve derinlik sınırı konmalı.
- **Kimlik bilgisi sızmamalı.** Ephemeral oturum kullanılmalı, User-Agent sabit olmalı, çerez tutulmamalı.
- **Kayıt zorunlu.** Ağ kontrolleri `ActionLog`'a öneri olarak değil, koşul olarak yazılmalı.

Bu şartların bir kısmı, özellikle bağlantı anında IP kontrolü, `URLSession` ile nasıl karşılanacağı belli olmayan tasarım sorularıdır. Appcast şeması da hâlâ doğrulanmadı (dosya, "Doğrulanmadı" bölümü). Bu yüzden Aşama 1'i bu kararda koşullu olarak bile onaylamadım. Onaylasaydım, sahip öncelik sorusunu yanıtladığı anda ajanlar doğrulanmamış bir şema üzerinden ağ kodu yazmaya başlayabilirdi. Bu, çoğunluğa karşı bir karar değil. Güvenlik jürisi, Swift jürisi ve ürün jürisi koşullarında "Aşama 1'e geçmeden önce ölçüm ve insan kararı" sırasını zaten istiyor. Ben yalnızca bu sıranın ikinci basamağını ayrı bir mahkemeye bağladım. Önceki iki dava da aynı biçimde kapandı. Tutarlılık da bunu gerektiriyor.

**Savcının en güçlü argümanı (kabul edildi): ölçülmemiş kapsam yanlış güven üretir.** Kullanıcıların uygulamalarının kaçı Sparkle, kaçı Homebrew, kaçı hiçbiri, bilinmiyor (Bilinmeyen 3). Bu bilinmeden "Güncelleme var" rozeti, rozeti olmayan uygulamaları sessizce "güncel" gösterir. Sıradan kullanıcı jürisi bunu kendi ağzından doğruladı: "Bir uygulamanın rozeti yoksa onun güncel olduğunu sanarım." Bu argüman Aşama 0'ı ön şart yapıyor ve eşiğin baştan belirlenmesini gerektiriyor (Soru 4).

Savcının "doğrulanmamış temel" itirazı da kabul edildi: appcast alan adları, iTunes Lookup ve Caskroom yolu doğrulanmadı. Aşama 1 mahkemesinin ön şartlarına bu yüzden "şema resmî belgeden doğrulanır" maddesi kondu. Savcının Seçenek A (erteleme) önerisi ise şimdilik **reddedildi**. Gerekçe şu: Aşama 0 ağsız ve silmesiz, maliyeti düşük. Ölçüm yapılmazsa A kararı da tahmine dayanır. Sahip Soru 5'e "hayır" derse A zaten kendiliğinden devreye girer.

**Savunmanın en güçlü argümanı (kabul edildi): Aşama 0 ucuzdur ve ertelense bile karar verdirecek veriyi üretir.** Savunma ağ kontrolünü bile Sparkle ile sınırladı; App Store'u ve kurmayı kapsam dışı bıraktı. Bu öz-kısıtlama, jürinin oybirliğiyle KOŞULLU vermesinin temel nedeni. Savunmanın Aşama 1 tasarımının çekirdeği bir sonraki mahkemeye yön olarak bırakıldı ama yeterli bulunmadı. Bulunmamasının iki gerekçesi var:
- "Yalnızca HTTPS ve tanımlayıcı başlık yok" önlemleri, macOS jürisinin gösterdiği iki açığı kapatmıyor: `URLSession` varsayılan User-Agent'ının sistem bilgisi sızdırması ve metin tabanlı SSRF süzgecinin yetersizliği.
- "Rozet bağlantısı satıcının alan adına açılır" iddiası, güvenlik jürisinin belirttiği gibi, feed içindeki `link` ve `enclosure` adreslerinin farklı alan adına işaret edebileceğini hesaba katmıyor.

**Reddedilen seçenekler:**
- **D:** §2.4 (`.app` içi korunan yol), §2.6 (çalışan uygulamaya dokunulmaz) ve §2.8 (yönetici yetkisi MVP'de yok) ile çelişiyor. `SafetyPolicy`'de bir "üzerine yazma" eylem türü yok. macOS jürisine göre App Management koruması da engel. Beş jüri de D'ye karşı.
- **E:** Yeni bir Keel AI veri akışı. PLAN satır 154'teki "yalnızca özet sistem verileri" ilkesi kapsamında ayrı bir karar gerekir. Sahipsiz artıklar davasındaki D seçeneğiyle aynı gerekçe.
- **Sparkle çerçevesi:** PLAN §1'deki "sıfır bağımlılık" çizgisini bozar ve yeni bir saldırı yüzeyi getirir. CVE iddiası dosyada kaynaklı ama macOS jürisi bağımsız doğrulayamadı. Karar bu iddiaya dayanmıyor, bağımlılık ilkesine dayanıyor.

**Kayıt düzeltmeleri:**
- Dosya Caskroom için yalnızca `/opt/homebrew/Caskroom` diyor. Intel Mac'lerde yol `/usr/local/Caskroom` (macOS jürisi). Aşama 0 iki yolu da okur.
- Dosya Sparkle tespiti için "`SUFeedURL` veya framework" diyor. Feed'in kodda üretildiği ya da defaults ile geçersiz kılındığı durumlar var. Bu yüzden "framework var ama Info.plist'te feed yok" ayrı bir sınıf olarak sayılmalı ve kontrol edilebilir kapsamına girmemeli.
- `AppInventory.swift` satırlarını doğruladım: `standardRoots` 47-52, `scan` 57-86, `read` 89-125, makbuz kontrolü 99. Dosyadaki yaklaşık numaralar doğru aralıkta. Envanter `InstalledApp.Source` olarak yalnızca `appStore`, `apple` ve `other` değerlerini tanıyor.

## Uygulama planı
(Yalnızca sahip 1-5 numaralı soruları yanıtlar, önceliği bu maddeye verir ve Soru 5'e "evet" derse uygulanır. Hiçbir adımda ağ kodu, silme, `.app` yoluna yazma ya da `SafetyPolicy`, entitlements veya `project.yml` değişikliği yoktur.)

1. **Saf kaynak sınıflandırıcı**
   - Dosyalar: yeni `Packages/KeelCore/Sources/KeelCore/Applications/UpdateSourceProbe.swift`.
   - `InstalledApp` ve `InstalledApp.Source` **değişmez**. Böylece `App/` içindeki `switch`'ler ve mevcut testler etkilenmez.
   - Yeni değer tipi `UpdateSource`. Değerleri: `sparkle(feed: .https | .insecure | .missing)`, `homebrewCask`, `appStore`, `apple`, `other`.
   - Girdi:
     - Bir `.app` URL'si ile o uygulamanın Info.plist sözlüğü.
     - `Contents/Frameworks/Sparkle.framework` var mı?
     - `_MASReceipt` var mı?
     - Caskroom içindeki `.app` adları kümesi.
   - Sınıflandırma kuralları:
     - `SUFeedURL` değerinin yalnızca **şeması** sınıflandırılır. URL'nin kendisi rapora yazılmaz, hiçbir istek atılmaz.
     - `http`, `file` ve şemasız değerler `.insecure` sayılır.
     - Framework var ama `SUFeedURL` yoksa sonuç `.missing` olur.
     - Öncelik sırası: `appStore` → `apple` → `sparkle` → `homebrewCask` → `other`.
     - Hem Cask hem Sparkle olan uygulama Sparkle sayılır ve ayrıca "çift kaynak" sayacına eklenir.
   - Test: yeni `Packages/KeelCore/Tests/KeelCoreTests/UpdateSourceProbeTests.swift`. Geçici dizinde sahte `.app` paketleriyle tablo testi yapılır. Vakalar:
     - HTTPS feed, HTTP feed, `file:` feed, boş feed
     - framework var ama feed yok
     - makbuzlu uygulama, `com.apple.*` uygulaması
     - Caskroom'da bulunan uygulama, Caskroom'da bulunmayan uygulama
     - çift kaynak
     - bozuk ya da eksik Info.plist
   - Sembolik link olan Caskroom girdisi takip edilmez (§2.5) ve bunun da testi yazılır.

2. **Caskroom okuyucu**
   - Dosya: aynı dosya.
   - `caskroomApps(roots:)` fonksiyonu varsayılan olarak `/opt/homebrew/Caskroom` ve `/usr/local/Caskroom` köklerini alır. Kökler parametre olarak verilir ki Linux'ta fixture ile sınanabilsin.
   - İki derinlikten fazla inilmez, sembolik link takip edilmez, okunamayan kök "okunamadı" olarak işaretlenir.
   - Test: geçici dizinde iki kök, biri yok; yinelenen cask; sembolik link.

3. **Dağılım raporu**
   - Dosya: aynı dosya.
   - `UpdateSourceReport` değer tipi şunları içerir:
     - her sınıf için sayı,
     - "üçüncü taraf" paydası (`apple` ve `isSystem` hariç),
     - "kontrol edilebilir" sayısı (yalnızca `sparkle(.https)`),
     - oran,
     - okunamayan kökler,
     - `status: .ok | .unsure(reason)`.
   - Uygulama adı ya da bundle ID yalnızca açıkça istenen yerel ayrıntı çıktısında bulunur. Toplam sayıların bulunduğu raporda yer almaz.
   - Test: oran hesabı, sıfır payda (`.unsure`), Apple ve sistem uygulamalarının paydadan düşmesi.

4. **Ölçüm aracı**
   - Biçim Soru 2'ye ve sahipsiz artıklar kararındaki Soru 4'e bağlıdır. Varsayılan öneri, `Package.swift`'e eklenecek küçük bir komut satırı hedefidir. Yeni bir **dış** bağımlılık değildir; uygulamaya dokunmaz.
   - Birleştirme kabul edilirse aynı araç sahipsiz artıklar raporunu da üretir.
   - Araç yalnızca okur ve standart çıktıya yazar. Dosya yazmaz, ağa çıkmaz.
   - Test: aracın çekirdeği 3. adımdaki saf fonksiyondur. Araç ince bir sarmalayıcıdır ve ayrı mantık içermez.

5. **Sonucun kaydı**
   - Dosya: `docs/PLAN.md` satır 120. Bu adım sahip aracı kendi Mac'inde çalıştırdıktan sonra yapılır.
   - Toplam sayılar, oran, makine ve macOS sürümü yazılır. Uygulama adı yazılmaz.
   - Oran eşiğin altındaysa Seçenek A gerekçesi aynı satıra yazılır ve madde kapanır. Eşiğin üstündeyse "Aşama 1 mahkemesi bekleniyor" notu düşülür.

**Aşama 1 mahkemesinin ön şartları.** Bunlar bu kararın uygulama adımı değildir, bir sonraki dava dosyasının içermesi gerekenlerdir:
- Aşama 0 sonucu eşiğin üstünde olmalı.
- Sparkle appcast şeması ve karşılaştırma kuralı (`sparkle:version` ile `CFBundleVersion` karşılaştırılır) resmî belgeden alıntıyla doğrulanmış olmalı.
- Bağlantı anında IP kontrolünün `URLSession` ile nasıl yapılacağı yazılı bir tasarımla gösterilmeli. Yapılamıyorsa alternatifi gösterilmeli.
- Foundation `XMLParser`'ın Linux ve macOS'ta dış varlık ve DTD davranışı belgelenmeli.
- `HTTPClient` soyutlamasının `AIError`'dan nasıl ayrılacağı belirtilmeli.
- Homebrew için "güncel mi" yöntemi yazılı olarak seçilmeli. `brew` alt süreci seçilirse ayrıca gerekçelendirilmeli.
- Bu davanın jüri koşulları (güvenlik 1-9, macOS 1-6, kullanıcı 1-7, Swift 1-7, ürün 1-7) ön şart sayılır.

## Kabul kriterleri
- [ ] `swift test --package-path Packages/KeelCore` geçiyor (Linux). Mevcut `ApplicationsTests` ve AI testleri değişmeden geçiyor.
- [ ] `InstalledApp`, `InstalledApp.Source`, `AppInventory.read` ve `App/` altındaki hiçbir dosya değişmedi.
- [ ] Yeni kodda `URLSession`, `HTTPClient`, `Process` ya da ağ ve alt süreç çağrısı yok. Yeni kod dosya sistemine yalnızca okuma çağrılarıyla erişiyor; Çöp'e taşıma, `removeItem`, `moveItem` ya da yazma çağrısı yok.
- [ ] `SafetyPolicy.swift`, `Support/Keel.entitlements`, `project.yml` ve Keel AI araçları (`KeelTools.swift`) değişmedi.
- [ ] Yeni dış bağımlılık yok. `Package.swift`'te yalnızca, sahip onaylarsa, yerel bir komut satırı hedefi eklendi.
- [ ] Sınıflandırma tablo testi en az şu vakaları kapsıyor: HTTPS feed, HTTP feed, `file:` feed, framework var ama feed yok, makbuz, `com.apple.*`, iki Caskroom kökü, sembolik link, çift kaynak, bozuk Info.plist.
- [ ] Rapor, sıfır paydada `.unsure` döndürüyor ve "kontrol edilebilir" sayısına yalnızca `sparkle(.https)` giriyor (testle).
- [ ] Toplam sayıların bulunduğu raporda uygulama adı, bundle ID ve feed URL'si yok (testle).
- [ ] PLAN.md satır 120'ye yalnızca toplam sayılar ve sonuç notu yazıldı.

## Kapsam dışı
- Her türlü ağ isteği: Sparkle feed çekme, iTunes Lookup, Homebrew JSON API. Bunlar Aşama 1 mahkemesine kaldı.
- Arayüz: "Güncelleme var" rozeti, "kontrol edilemedi" grubu, ayar anahtarı, onay ekranı.
- Seçenek D: indirme, kurma, `.app` değiştirme, çalışan uygulamayı kapatma, App Management izni, yönetici yetkisi.
- Seçenek E: güncelleme bilgisinin `get_installed_apps` ya da başka bir Keel AI aracına eklenmesi.
- Sparkle çerçevesinin ya da başka bir dış bağımlılığın eklenmesi. Keel'in kendi güncellemesi (Faz 4) bu davanın konusu değil; Sparkle bağımlılık kararı o fazda ayrıca görülür.
- Mac App Store için sürüm kontrolü. Resmî bir kaynak doğrulanmadı.
- Setapp, Microsoft AutoUpdate, GoogleUpdater ve Electron gibi kendi güncelleyicisi olan uygulamaların ayrıca tanınması. Aşama 0'da bunlar `other` sayılır, Aşama 1 mahkemesinde ele alınır.
- Ortak `Networking` katmanının çıkarılması ve `ModelCatalog.swift`'e dokunulması.

---

*Not: Bu karar metni dosyaya yazılmadı. Kaydedilmesi gerekiyorsa yeri `/home/claude/keel/docs/mahkeme/2026-10-29-uygulama-guncelleyici/karar.md` olur. Sorular, `GUNDEM.md`'de (şu an `origin/claude/mahkeme-2026-10-28` dalında) "Bekleyen insan onayları" altına eklenmeli. Sahipsiz artıklar ve kopya dosya bulucu kayıtlarıyla birlikte, Faz 2 öncelik sorusunun üç davada da aynı soru olduğu ve tek bir cevapla kapanabileceği belirtilmeli.*
