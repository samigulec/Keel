# Dava dosyası: Uygulama güncelleyici (PLAN.md §5 Faz 2, satır 120)

## Soru
Keel, kurulu üçüncü taraf uygulamaların güncel olup olmadığını bulmalı (ve güncellemeye yardım etmeli) mi; evet ise hangi kaynaklarla, hangi yetkiyle ve ağ gizliliği/güvenlik sınırlarıyla?

## Mevcut durum
- Güncelleme kodu yok. Repoda "Sparkle", feed ya da güncelleme kontrolü geçen kod yok. Tek geçiş `docs/PLAN.md:164` (Faz 4, Keel'in kendi güncellemesi). `project.yml` içinde Sparkle paketi yok. `Package.swift` hedefleri: KeelSystemShims, KeelCore, test. Dış bağımlılık sıfır.
- Envanter: `Packages/KeelCore/Sources/KeelCore/Applications/AppInventory.swift`. `standardRoots` yalnızca `/Applications` ve `~/Applications` (satır ~45-50). `scan` bir klasör derinliği iner, sembolik link takip etmez (satır ~52-84). `read(_:)` (satır ~87-125) şunları çıkarır: `CFBundleIdentifier`, sürüm (`CFBundleShortVersionString`, yoksa `CFBundleVersion`), kaynak, mimari, salt-okunur-birim bayrağı.
- App Store tespiti: `Contents/_MASReceipt/receipt` var mı diye bakar (`AppInventory.swift` ~satır 100). `Source` değerleri: `.appStore`, `.apple` (com.apple.* öneki), `.other`. Sparkle, Homebrew Cask ya da Setapp ayrımı yok.
- Sparkle tespiti için gereken bilgi (`SUFeedURL`, `SUPublicEDKey`, `Contents/Frameworks/Sparkle.framework`) şu an okunmuyor. `read()` yalnızca birkaç plist anahtarını alıyor.
- `AppArchitecture.swift`: Mach-O başlığından Intel/Universal/Apple Silicon okur. Güncelleme sürümünün mimarisini bilmenin yolu değil, yalnızca kurulu olanı söyler.
- Uygulama arayüzü: `App/Features/Applications/ApplicationsModel.swift` (envanter `AppInventory.scan` satır ~100, çalışan uygulama kontrolü satır ~144-147, `quit` satır ~275) ve `ApplicationsView.swift`. Çalışan uygulamayı `NSWorkspace.shared.runningApplications` ile bulur; güncelleyici de aynı kontrolü kullanabilir.
- Ağ: KeelCore'daki tek ağ kodu Keel AI içinde. `AI/ModelCatalog.swift:12-25` içinde `HTTPClient` protokolü ve `URLSessionHTTPClient`; `AI/URLSessionTransport.swift`. Linux'ta `AIError.unsupportedPlatform` fırlatıyor. Güncelleyici için tekrar kullanılabilecek bir enjekte edilebilir HTTP soyutlaması var, ama AI'ya özel hata türüne bağlı.
- Yetki: `Support/Keel.entitlements` sandbox'sız. Yalnızca `automation.apple-events` var. Ağ istemcisi için ek entitlement gerekmez (sandbox yok). Hardened runtime'da `Contents/Frameworks` yazımı vb. ayrıca doğrulanmadı.
- Keel AI: `App/Features/Assistant/KeelTools.swift:90` içinde `get_installed_apps` aracı var (en büyük, 90+ gün kullanılmamış, Intel). Uygulama adı/sürüm listesi AI'ya gidiyor. Güncelleme sonucu AI aracına eklenirse PLAN §5 Keel AI "Yalnızca özet sistem verileri gönderilir" ilkesi (`docs/PLAN.md:154`) devreye girer.
- Silme/Çöp yolu: güncelleme kendiliğinden silme yapmaz, ama `.app` üzerine yazmak/taşımak `SafetyPolicy` (`Safety/SafetyPolicy.swift`, `evaluate` satır 57) alanına girer. `.app` içi PLAN §2 madde 4'te korunan yol; üzerine yazma bu politikanın tanımladığı bir eylem türü değil. Bu bir boşluk.
- Testler: `Packages/KeelCore/Tests/KeelCoreTests/ApplicationsTests.swift` envanter ve artık eşleştirmeyi sınıyor. Güncelleyiciye ait test yok. Not: bu ortam Linux; macOS'a özgü kod doğrulanamaz, saf ayrıştırıcılar (appcast XML, sürüm karşılaştırma) Linux'ta test edilebilir.

## İlgili kurallar
- PLAN §1: Dağıtım App Store dışı, Developer ID + notarization, sandbox yok. Bağımlılık "mümkün olduğunca sıfır" (`PLAN.md:20`).
- §2.2 "Önce göster, sonra onayla": tarama salt okunur; değiştiren her işlem kullanıcı onayından sonra.
- §2.3 izin listesi; §2.4 `.app` içi korunan yol; §2.6 çalışan uygulamaya dokunulmaz (güncelleme için uygulamanın kapalı olması gerekir).
- §2.7 "Her işlem kaydedilir": `~/Library/Logs/Keel/` (`Actions/ActionLog.swift`). Bir güncelleme indirme/kurma eylemi de kayda geçmeli.
- §2.8 Root yok (MVP). Sparkle'sız `/Applications` altına yazma ya da pkg kurulumu yönetici yetkisi isteyebilir; Faz 3'e kadar ertelenir.
- §3 satır 53: `.app` içinden dosya silmek imzayı bozar; aynı mantık, yerinde yama yapmanın yasaklı olduğunu gösterir.
- §5 Keel AI: kullanıcı onaylamadan hiçbir şey yapılmaz; dosya içeriği asla gönderilmez.
- Faz 4 (`PLAN.md:164`): Sparkle ile Keel'in kendi güncellemesi. İlişki: Keel bir gün Sparkle'ı bağımlılık olarak alırsa, aynı feed ayrıştırma bilgisi bu özelliğe yardımcı olabilir, ama Sparkle çerçevesi başka uygulamaların güncellemesini yönetmek için tasarlanmamış (aşağıya bak).
- CLAUDE.md: yeni özellik, yeni bağımlılık ve mimari karar mahkeme zorunlu. Yeni ağ yüzeyi ve olası Keel AI veri akışı da kapsamda.
- Önceki mahkemeler: `docs/mahkeme/` altında bu konuya ait karar yok (README tablosu boş). Bağlam: kopya dosya bulucu (2026-10-27) ve sahipsiz artıklar (2026-10-28, `origin/claude/mahkeme-2026-10-28`) kararları Faz 2 öncelik sırasını insana bıraktı; ikisi de "İNSAN ONAYI GEREKİR: EVET". Sahipsiz artıklar kararı yalnızca Aşama 0 ölçümü kabul etti ve jüri "ölçmeden kod yazma" dedi. `GUNDEM.md` Bekleyen insan onayları: öncelik sorusu (hangi Faz 2 maddesi önce) hâlâ cevapsız. Bu dava da aynı öncelik sorusuna bağlı.

## Dış araştırma
Doğrulananlar:
- Latest (açık kaynak, GPL-3.0, yazar mangerlahn; "max-langer" yazımı yanlış, repo `github.com/mangerlahn/Latest`) yalnızca Mac App Store ve Sparkle kullanan uygulamaları destekliyor. Yazar boş zamanında geliştiriyor. Kaynak: https://www.github.com/mangerlahn/Latest . Latest'in Homebrew cask'i, Sparkle appcast'ten sürüm okuyor (`livecheck ... strategy :sparkle`) ve `auto_updates true` işaretli: https://mirror.iscas.ac.cn/homebrew-bottles/api/cask-source/latest.rb
- CleanMyMac Updater: uygulamaları günceller; App Store uygulamalarını ve macOS'u KURAMAZ (MacPaw Store ve Setapp sürümleri listeler ama seçilemez; App Store sürümü hiç listelemez). Kurulamayan uygulamada onay kutusu yerine bilgi simgesi var ("güncellemeyi nereden kuracağınızı gösterir"). "Hepsini seç" kurulamayanları atlar. Güncelleme bilgisinin nereden geldiğini açıklamıyor. Smart Insights için macOS Tahoe 26 ve Apple Intelligence gerekiyor. Kaynak: https://macpaw.com/support/cleanmymac/knowledgebase/updater
- mas-cli: `mas outdated` varsayılanı iTunes Search API'ye sorup kurulu sürümle karşılaştırır (uygulama başına ~7 ms, Apple Account gerekmez), ama "yanlış pozitif/negatif" üretebilir (API sürümü tutarsızlığı, geç tutarlılık). `--accurate` kipi bir App Store indirmesi başlatıp meta veriden sürümü okur ve iptal eder (~175 ms, hesap gerekir, 100+ uygulamada takılabilir, diyalog açabilir). Kurulu uygulama verisi Spotlight'tan gelir. `--check-min-os` varsayılan: yalnızca bu macOS ile uyumlu sürümler raporlanır. `update/upgrade` root ve oturum açık Apple hesabı ister. Kaynak: https://github.com/mas-cli/mas
- Homebrew Cask: `auto_updates true` uygulamanın kendini güncellediğini belirtir; `sha256` zorunlu (`:no_check` istisna, genellikle `version :latest`); `livecheck` Sparkle için feed'in `minimumSystemVersion` alanını kontrol eder; resmi macOS cask'leri Gatekeeper gerekliliklerini sağlamalı. Kaynak: https://docs.brew.sh/Cask-Cookbook (sayfanın son ~24 bin karakteri okunmadı).
- Sparkle güvenlik geçmişi: bir sürümde (tartışma başlığı "2.6.3", metinde düzeltme "2.6.2" diye geçiyor, tutarsız) imzalı bir güncellemeyi başka bir yük ile değiştirmeye izin veren (EdDSA/DSA kontrolünü aşan) açık düzeltildi; HTTPS ile sunan uygulamalar hemen etkilenmez çünkü saldırgan önce sunucuyu ya da bir CA'yı ele geçirmeli. Kaynak: https://github.com/sparkle-project/Sparkle/discussions/2551 . Ayrıca CVE-2026-47122: Sparkle ≤2.9.1'de `<bundleId>-spki` Mach servisi, aşama 1 bittikten sonra herhangi bir yerel süreçten bağlantı kabul ediyor, takım kimliği/imza kontrolü yok; CVSS 4.2; "bilinen yama yok". Kaynak: https://app.opencve.io/cve/CVE-2026-47122 . Çıkarım: Sparkle çerçevesini üçüncü taraf uygulamaların güncellemesini yürütmek için bağımlılık almak, bu tür bir saldırı yüzeyini Keel'e taşır (bu bir çıkarımdır, kaynak bunu söylemiyor).
- iTunes Search/Lookup API: bundleId ile sorgu örneği Apple geliştirici forumunda geçiyor (`itunes.apple.com/lookup?bundleId=...`), ama Apple'ın resmi destek durumu için o forum iletisi cevapsız. Kaynak: https://developer.apple.com/forums/thread/744181 . Apple'ın arşiv dokümanı yalnızca "promo content" kullanım koşullarını döndürdü (rozet, ikon vb.); lookup ayrıntısı alınamadı.

Doğrulanmadı / erişilemedi:
- Sparkle appcast şeması (`sparkle:version`, `sparkle:shortVersionString`, `sparkle:edSignature`, `sparkle:minimumSystemVersion`, `enclosure`), `SUFeedURL` ve `SUPublicEDKey` anahtarları ve HTTPS gereklilikleri: resmi sayfalar (sparkle-project.github.io/documentation/ ve /publishing/) izin zaman aşımı nedeniyle okunamadı. Bu alan adları genel bilgiden (doğrulanmadı). Latest ve Homebrew cask Sparkle appcast'ten sürüm okuduğu için "appcast'i HTTP ile çekip sürüm okumak" yaklaşımının var olduğu doğrulandı; şema ayrıntısı doğrulanmadı.
- iTunes Lookup oran sınırı (~20 istek/dk/IP olarak biliniyor), `version`, `minimumOsVersion`, `kind=mac-software` alanları: doğrulanmadı. `performance-partners.apple.com/search-api` sayfası okunamadı.
- MacUpdater'ın çalışma biçimi: arama sonuçları yalnızca üçüncü taraf bir yazıya işaret etti, okunmadı; doğrulanmadı. Kendi veritabanı (kürate edilmiş katalog) kullandığı yönündeki bilgi doğrulanmadı.
- Homebrew cask JSON API (`formulae.brew.sh/api/cask.json`) sayfası okunmadı. Kataloğun indirilebilir olduğu genel bilgi (doğrulanmadı). Homebrew kurulu değilse `brew` yoktur; cask ile kurulan uygulamaların hangileri olduğunu bulmak için `/opt/homebrew/Caskroom` okunur (doğrulanmadı).
- Mac App Store için Apple'ın resmi, belgelenmiş bir "bu uygulamanın güncellemesi var mı" API'si olduğuna dair kanıt bulunamadı. mas-cli'nin iki yöntemi (arama API'si ya da indirme başlatıp iptal) bunun yokluğuna işaret ediyor (çıkarım). `--accurate` yöntemi `StoreKit`/özel sistem davranışına dayanıyor olabilir; doğrulanmadı.
- Setapp uygulamalarının güncelleme yolu: doğrulanmadı.

Güvenlik riskleri (kaynaklı bulgulara ve genel bilgiye dayanarak; açıkça işaretli):
- Ağ gizliliği: her sorgu hangi uygulamaların kurulu olduğunu üçüncü tarafa (Apple, uygulama satıcıları, GitHub) sızdırır; IP + uygulama listesi. Sparkle için her satıcının feed sunucusuna ayrı istek gider (genel bilgi, doğrulanmadı: appcast URL'si uygulamanın Info.plist'inde). Bu PLAN §5 Keel AI "yalnızca özet sistem verileri" ilkesinden daha geniş bir veri dışarı akışı.
- İndirme bütünlüğü: feed HTTP ise MITM mümkün; Sparkle imzası uygulamanın kendi gömülü ortak anahtarına karşı doğrulanır, yani Keel o anahtarı doğrulamadan indirip yüklerse yalnızca "uygulamanın kendi Sparkle'ı" korur. Keel'in kendi başına kurması durumunda, imza ve notarization doğrulaması (kod imzası takım kimliğinin mevcut uygulamayla aynı olması, `spctl` değerlendirmesi) Keel'in sorumluluğuna geçer (genel bilgi, doğrulanmadı).
- Yetki: `/Applications` kullanıcıya yazılabilir olabilir ama sahibi root olan uygulamalar yönetici yetkisi ister. Çalışan uygulamanın üzerine yazmak §2.6'ya aykırı.

## Seçenekler

### Seçenek A: Hiç yapmamak / ertelemek
- Yapılacak: `docs/PLAN.md` satır 120'ye gerekçeli erteleme notu. Dosya: yalnızca PLAN.md.
- Büyüklük: çok küçük.
- Etki: Keel zaten uygulamaların kendi güncelleyicisini kullanıyor; Keel ağ yüzeyi eklemez. Dezavantaj: rakiplerde (CleanMyMac Updater, MacUpdater, Latest) olan bir özellik eksik kalır; Faz 2 maddesi açık kalır.

### Seçenek B: Salt okunur "Güncelleme durumu" (yalnızca tespit, kurma yok), kullanıcı isteğiyle
- Yapılacak: saf KeelCore katmanı: (1) `AppInventory.read` içine kaynak ayrımı (Sparkle: `SUFeedURL`; Homebrew Cask: Caskroom; App Store: mevcut makbuz), (2) appcast XML ayrıştırıcı ve sürüm karşılaştırıcı (Linux'ta test edilebilir), (3) enjekte edilebilir `HTTPClient` ile kontrol (AI'ya özel hata türü ayrılmalı). Arayüz: Uygulamalar ekranında "Güncelleme var" rozeti ve "Satıcının sitesini aç / App Store'u aç" düğmesi. Güncellemeyi Keel yapmaz.
- Dosyalar: `AppInventory.swift`, yeni `Applications/UpdateCheck.swift` ve testi, `ApplicationsModel/View`, muhtemelen yeni `Settings` anahtarı. `SafetyPolicy`, silme ve entitlements değişmez.
- Büyüklük: orta (yaklaşık 600-900 satır + test).
- Riskler: ağ gizliliği (satıcı sunucularına istek); yanlış pozitif/negatif (sürüm karşılaştırması, `minimumSystemVersion`, kanal/beta). App Store için güvenilir kaynak belirsiz (aşağıda); bu kaynak kapsam dışı bırakılabilir. Ağa çıkış varsayılan kapalı + açık onay ile yapılabilir; sonuç Keel AI'ya gönderilmez.

### Seçenek C: Yalnızca Sparkle ve Homebrew Cask için kontrol; kurulumu mevcut araca devret
- Yapılacak: B'nin alt kümesi. App Store uygulamaları için sadece "App Store'u aç" (kontrol yok). Homebrew için kullanıcıya `brew upgrade --cask <ad>` komutunu göster/kopyala; Keel çalıştırmaz.
- Dosyalar: B ile aynı, daha az.
- Büyüklük: küçük-orta (yaklaşık 400-600 satır).
- Bu, CleanMyMac'in "kurulamayanlar için bilgi simgesi" yaklaşımına benziyor.

### Seçenek D: Keel güncellemeyi kendisi indirip kurar
- Yapılacak: B + indirme, imza/notarization/takım kimliği doğrulama, çalışan uygulamayı kapatma, `.app` değiştirme (taşıma/yerine koyma), geri alma. Sparkle'ı çerçeve olarak ya da kendi yükleyicimizle.
- Dosyalar: yeni `Updater/` modülü, `SafetyPolicy` yeni eylem türü, `Keel.entitlements`/hardened runtime ayarı, `project.yml`, ActionLog, Geri Al.
- Büyüklük: büyük (1500+ satır), yönetici yetkisi senaryosu (§2.8 ile çelişir), yeni saldırı yüzeyi (Sparkle CVE örneği). PLAN §2 ile en çok gerilim burada. Faz 3'e bağlı.

### Seçenek E: Keel AI ile birleştirme (isteğe bağlı eklenti)
- Yapılacak: B/C sonrası `get_installed_apps` çıktısına "güncel değil" listesi eklemek.
- Etki: uygulama adları/sürümleri zaten araca gidiyor ama yeni bilgi ("hangi uygulama eski") ağ sonucuna bağlı olur. Ayrı veri akışı kararı gerekir (sahipsiz artıklar kararında Seçenek D benzer şekilde reddedildi).

## Bilinmeyenler
1. Öncelik: GUNDEM'deki "Faz 2 açık maddelerinden hangisi önce?" sorusu hâlâ cevapsız; bu madde diğer açıklarla yarışıyor.
2. Mac App Store için hangi kaynak güvenilir? iTunes Lookup resmi olarak "destekleniyor" mu, oran sınırı ve doğruluk (mas-cli kendi README'sinde yanlış sonuç uyarısı veriyor) belirsiz. Erişilemeyen Apple belgesi doğrulanmalı. Bulunmazsa App Store uygulamaları kapsam dışı olur (CleanMyMac gibi).
3. Kullanıcının uygulamalarının kaçı Sparkle, kaçı Homebrew, kaçı App Store, kaçı hiçbiri? Kapsam oranı ölçülmedi. Kapsam düşükse özellik "yarım yanlış güven" riski taşır (PLAN koruma notundaki ilkeyle benzer). Sahipsiz artıklar kararındaki gibi bir salt okunur ölçüm (kaynak dağılımı, ağsız: yalnızca Info.plist okuma) önce yapılabilir; bu yapılmadı.
4. Sparkle appcast şeması ve imza doğrulama ayrıntıları (resmi sayfalar okunamadı).
5. Keel'in "ağa hiç çıkmayan temizlik uygulaması" imajı kullanıcı için önemli mi? Ağ kontrolü varsayılan kapalı olmalı mı? İnsan kararı.
6. Hardened runtime + Developer ID altında başka uygulamanın `.app` paketini değiştirmek (App Management izni, macOS 13+ "Uygulama Yönetimi" gizlilik izni) gerekir mi? Doğrulanmadı; D seçeneği için kritik.
7. Setapp, Microsoft AutoUpdate, Electron `electron-updater`, Chrome/Edge/Firefox gibi kendi arka plan güncelleyicilerinin (GoogleUpdater, LaunchAgent olarak sistemde görünür; bkz. test fixture'ı `SystemReadersTests.swift:96-106`) tespiti: yanlış "güncel değil" raporu riski.
8. Beta/kanal ayrımı ve `minimumSystemVersion` (Homebrew cask'in de uyguladığı) kontrolünün Keel'de nasıl ele alınacağı. Intel/Universal uygulama için yeni sürümün Apple Silicon olup olmadığı feed'den çıkmaz.
9. Faz 4'te Keel'in kendi Sparkle'ı eklenirse bağımlılık kararı (PLAN §1 "sıfır bağımlılık") aynı mahkemede ele alınmalı mı? Bu davada yalnızca ilişkisi not edildi.

Dosyalar (okunan): /home/claude/keel/docs/PLAN.md, /home/claude/keel/CLAUDE.md, /home/claude/keel/Packages/KeelCore/Sources/KeelCore/Applications/AppInventory.swift, /home/claude/keel/Packages/KeelCore/Sources/KeelCore/Applications/AppArchitecture.swift, /home/claude/keel/Packages/KeelCore/Sources/KeelCore/AI/ModelCatalog.swift, /home/claude/keel/Packages/KeelCore/Package.swift, /home/claude/keel/Support/Keel.entitlements, /home/claude/keel/App/Features/Applications/ApplicationsModel.swift, /home/claude/keel/App/Features/Assistant/KeelTools.swift. Not: satır numaralarının bir kısmı yaklaşık (işaretli "~"); kod bu oturumda baştan sona satır satır doğrulanmadı.
