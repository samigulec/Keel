# Mahkeme gündemi

Günlük mahkeme konularını önce buradan, sonra `docs/PLAN.md`'deki `- [ ]`
maddelerinden seçer. Bu dosyayı sen düzenlersin; ajanlar yalnızca
"Ajan önerileri" bölümüne ekleme yapabilir.

## Sıradaki konular (senin eklediklerin, yukarıdan aşağı)

<!-- Örnek: - Menü çubuğuna pil sağlığı göstergesi -->

## Bekleyen insan onayları

Hakim "İNSAN ONAYI GEREKİR: EVET" dediğinde konu buraya düşer. Cevabını
konunun altına yaz; ajanlar cevaplanmış konuyu `/gelistir` sırasına alır.

### Kopya dosya bulucu ([karar](2026-10-27-kopya-dosya-bulucu/karar.md))
1. Faz 2'deki açık maddelerden hangisi önce yapılsın?
2. Adım 0 ölçüm aracını kendi Mac'inde çalıştırmayı kabul ediyor musun?
3. Eşik uygun mu? (en az 20 kopya grubu ve en fazla 1 GB üstü yer)

Cevap:

### Sahipsiz artıklar ([karar](2026-10-28-sahipsiz-artiklar/karar.md))
Karar: yalnızca Aşama 0 (silme yapmayan, salt okunur ölçüm) kabul; silme yapan her aşama reddedildi.
1. Öncelik: Faz 2 açık maddeleri (sahipsiz artıklar, uygulama güncelleyici, menü çubuğu canlı grafikleri, kopya dosya bulucu, LaunchAgent aç/kapat) arasında Aşama 0 şimdi mi yapılsın, yoksa madde gerekçeli notla ertelensin mi (Seçenek A)?
2. Ölçüm: Aşama 0 aracını kendi Mac'inde çalıştırıp çıktıyı elle gözden geçirmeyi kabul ediyor musun? Hangi makine ve macOS sürümü? Setapp, Homebrew Cask, Microsoft Office ya da harici diskte uygulama kurulu mu?
3. Eşik: Aşama 1 mahkemesine gidebilmek için yanlış pozitif eşiği ne olsun? (Hakimin önerisi: 6 konumda elle doğrulanmış yanlış pozitif sıfır; aşılırsa Seçenek A.)
4. Araç biçimi: KeelCore'a eklenecek küçük bir komut satırı aracı mı (hakimin önerisi), yoksa uygulamada yalnızca DEBUG derlemede görünen bir ekran mı?

Cevap:

### Uygulama güncelleyici ([karar](2026-10-29-uygulama-guncelleyici/karar.md))
Karar: yalnızca Aşama 0 (ağa çıkmayan, salt okunur kaynak dağılımı ölçümü) kabul; ağ ile sürüm kontrolü ayrı mahkemeye kaldı, Keel'in kendisi kurması (D), Keel AI'ya gönderme (E) ve Sparkle bağımlılığı reddedildi.
Not: 1. soru, kopya dosya bulucu ve sahipsiz artıklar kayıtlarındaki öncelik sorusuyla aynıdır; tek cevapla üçü birden kapanabilir.
1. Öncelik: Faz 2 açık maddeleri (sahipsiz artıklar, uygulama güncelleyici, menü çubuğu canlı grafikleri, kopya dosya bulucu, LaunchAgent aç/kapat) arasında hangisi önce? Bu madde için (a) Aşama 0 şimdi mi yapılsın, (b) PLAN satır 120'ye gerekçeli notla ertelensin mi (Seçenek A)?
2. Ortak ölçüm: Bu davanın Aşama 0'ı ile sahipsiz artıkların Aşama 0'ı tek bir ölçüm aracında, tek çalıştırmada birleştirilsin mi? (Hakimin önerisi: birleştir.)
3. Ölçüm ortamı: Aracı kendi Mac'inde çalıştırıp çıktıyı gözden geçirmeyi kabul ediyor musun? Apple Silicon mı Intel mi, hangi macOS sürümü? Homebrew kurulu mu? PLAN.md'ye yalnızca toplam sayıların yazılmasını (uygulama adı yok) onaylıyor musun?
4. Eşik: Pay yalnızca HTTPS feed'li Sparkle uygulamaları, payda üçüncü taraf uygulamalar (Apple/sistem hariç); eşik %50, altında kalırsa Seçenek A. Kabul ediyor musun?
5. Ağ ilkesi: Aşama 1'e gelinirse Keel'in, kullanıcı açıkça açtığında ve yalnızca düğmeyle (varsayılan kapalı) satıcıların feed sunucularına istek atmasını ilke olarak kabul ediyor musun? "Hayır" ise madde Seçenek A ile kapanır ve Aşama 0 yapılmaz.

Cevap:

### Menü çubuğunda canlı grafikler ([karar](2026-10-29-menu-cubugu-canli-grafikler/karar.md))
Karar: yalnızca açılan pencerede CPU ve ağ için mini grafik (B) kabul; menü çubuğu simgesinde grafik (C) Mac'te ölçüm şartıyla ayrı mahkemeye kaldı; bellek/disk grafiği, döngü hızı değişikliği ve Swift Charts kapsam dışı.
Not: 1. soru, diğer üç kayıttaki öncelik sorusuyla aynıdır; tek cevapla dördü birden kapanabilir.
1. Öncelik: Faz 2 açık maddeleri (sahipsiz artıklar Aşama 0, uygulama güncelleyici Aşama 0, menü çubuğu canlı grafikleri, kopya dosya bulucu, LaunchAgent aç/kapat) arasında hangisi önce? Bu madde için (a) plan şimdi uygulansın mı, (b) PLAN satır 122'ye gerekçeli erteleme notu mu düşülsün (Seçenek A)?
2. Kapsam: "Menü çubuğunda canlı grafikler" ile (a) açılan pencerede mini grafik (B) yeterli mi (B bitince madde `[x]` olur), yoksa (b) asıl istenen simgenin kendisinde grafik mi (C; madde açık kalır, C için ayrı mahkeme)?
3. Mac'te doğrulama: PR birleşmeden önce kendi Mac'inde Performans ekranının önce/sonra ekran görüntüsünü, menü açık ve kapalıyken Activity Monitor'de Keel'in CPU ve "Energy Impact" değerlerini ve mümkünse Instruments (SwiftUI) ile kapalı pencerede `MenuBarContent` gövdesinin yeniden hesaplanıp hesaplanmadığını kontrol etmeyi kabul ediyor musun? Hangi makine ve macOS sürümü?
4. Görünüm: Grafik yalnızca CPU ve ağ satırlarında, yanında küçük bir "son 1 dk" etiketiyle; bellek ve disk dışarıda. Uygun mu?

Cevap:

### Kullanıcı LaunchAgent'larını aç/kapat ([karar](2026-10-30-kullanici-launchagent-ac-kapat/karar.md))
Karar: DEĞİŞTİRİLEREK KABUL, İNSAN ONAYI GEREKİR: HAYIR. Kayıt, test ve metin düzeltmeleri `/gelistir` ile yapılabilir; aşağıdaki sorular o işi bekletmez, ama satır 144 ancak 1. sorudaki Mac doğrulamasından sonra `[x]` olur.
1. Mac doğrulaması: En az bir macOS 13+ cihazda şu senaryoyu çalıştırmayı kabul ediyor musun? Bir `.user` ajanını Keel'den kapat, `launchctl print gui/<uid>/<label>` ile durduğunu gör, Mac'i yeniden başlat, çalışmadığını gör; Sistem Ayarları > Giriş Öğeleri ve Uzantılar görünümüyle karşılaştır; ajanı aç ve aynı kontrolleri tekrarla; plist'inde `Disabled=true` olan bir ajanda `enable` sonrası yüklenip yüklenmediğini dene; aynı etiketli çift plist varsa davranışını not et. Hangi makine ve macOS sürümünde?
2. §2.7: "Her işlem kaydedilir" ilkesi servis aç/kapatı da kapsıyor mu? (Kararda "evet" diye yorumlandı.)
3. §2.3 / §2.8: Servis korumasının yasak listesiyle yapılması (`com.apple.` ve karakter süzgeci) kabul edilebilir mi, yoksa güvenlik, VPN, yedekleme, MDM ajanları ve Keel'in kendi etiketi için ek uyarı ya da allowlist mi istiyorsun (ayrı mahkeme)? `.system` servislerinin ve fan yardımcısının `osascript` ile root çalıştırması "Root yetkisi MVP'de yok" ilkesiyle nasıl uzlaşsın?
4. Görünürlük: Ayarlar'daki "kayıt klasörünü göster" düğmesi yeterli mi, yoksa uygulama içinde "son değişiklikler" listesi mi istiyorsun (ayrı iş)?
5. Kapsam: Satır 144'ten mevcut işin ötesinde bir şey bekliyor muydun? Cevap "hayır" ise doğrulamadan sonra madde kapanır.

Cevap:

## Ajan önerileri (onaylarsan "Sıradaki konular"a taşı)

- Büyük Dosyalar bulucusunda paket tespiti sabit 16 uzantılık listeye
  dayanıyor; `.rtfd`, sanal makine paketleri gibi bilinmeyen paketlerin içi
  normal klasör sanılabilir. (Kaynak: kopya dosya bulucu kararı, kapsam dışı
  notu)
- `LargeFileRemover` kendi doğrulamasında tüm ev klasörünü izinli kök sayıyor
  ve tarayıcının dışarıda bıraktığı yerleri (gizli klasörler, paket içleri)
  `perform` içinde yeniden kontrol etmiyor; `~/.ssh/...` ya da
  `~/Documents/X.photoslibrary/...` içindeki bir dosya Çöp'e taşınabilir
  (§2.3, §2.4). Bugün tek çağıran yalnızca tarama sonucunu verdiği için bu
  derinlemesine savunma eksiği; testler de bu iki durumu denemiyor.
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/LargeFiles/LargeFiles.swift:267`,
  `allowedRoots: [home]`; dışlamalar yalnızca tarayıcıda, satır 166-186)
- Silme sonrası işlem günlüğü `try?` ile yazılıyor; günlük yazılamazsa dosya
  yine de Çöp'e taşınıyor ve kullanıcıya bir şey söylenmiyor, bu da §2.7
  "Her işlem kaydedilir" ilkesini sessizce çiğner. Raporlarda günlük hatası
  alanı ve bu yol için test yok. (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/Actions/CleanupExecutor.swift:55`;
  aynı kalıp `Uninstaller.swift:143`, `LargeFiles.swift:286`,
  `TrashRestorer.swift:47,69`)
- `SafetyPolicy`'nin "başka diske taşan yol silinmez" kuralı (§2.5,
  `.differentVolume`) için hiç test yok; kural bozulsa testler yeşil kalır.
  Linux'ta test edebilmek için `deviceID` enjekte edilebilir yapılabilir.
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/Safety/SafetyPolicy.swift:94`;
  `Tests/` altında `differentVolume` geçmiyor)
- Keel AI servis kartı `problems` satır sayısını başarısız servis sayısı gibi
  kullanıyor. Servis değişip yalnızca işlem kaydı yazılamazsa kart hata gösterir,
  "Geri al" çıkmaz ve geri almada `undone: false` döner; toplu sistem isteminde
  tek satırlık iptal de sayımı şaşırtır. Kayıt sorunu servis sorunlarından
  ayrılmalı ve test edilmeli. (Kaynak: `App/Features/Assistant/ActionProposals.swift`,
  `changed = items.count - problems.count`; LaunchAgent aç/kapat denetimi)
- Akıllı Tarama "Temizle" sonucu kullanıcıya göstermiyor ve vaat ettiği
  "Temizlik ekranından geri alabilirsin" güvencesi bir sonraki taramada
  kayboluyor. `SmartCareModel.cleanRecommended` raporu `_ =` ile atıyor;
  Akıllı Tarama ekranında `lastReport` / `ReportBanner` yok. Atlanan
  (uygulama açık), başarısız ya da hiç çalışmayan temizlik (`cleanAndWait`
  `phase != .ready` iken sessizce `nil` dönüyor) görünmüyor, yalnızca bulgu
  listesi yenileniyor. "Geri al" ise `CleanupModel.lastReport` içinde; her
  `startScan` bunu ve `lastRestore`'u siliyor. Keel AI'nın
  `scan_cleanable_space` aracı her çağrıda `scanAndWait()` çalıştırıyor
  (AccountSession'daki 600 sn önbelleği yalnızca bağlam toplamada var), yani
  temizlik sonrası sohbette bir soru ya da "Yeniden tara" Geri al düğmesini
  yok ediyor. Ayrıca `selectRecommended()` kullanıcının Temizlik'teki elle
  seçimini ezer. Senaryo: kullanıcı Akıllı Tarama'dan 3 GB temizler, Keel
  AI'ya "disk neden dolu?" der, Temizlik'e gidince Geri al yok; öğeler Çöp'te
  duruyor ama Keel'den dönüş yolu yok (§2.1 geri alınabilirlik güveni, §2.2
  gösterilen bilgi doğru olmalı). Önceki "Geri al çifte tıklama" ve "X GB
  temizlendi" önerilerinden farkı: orada Temizlik ekranının kendisi, burada
  Akıllı Tarama yolu ve taramanın raporu silmesi. Test yok: App katmanı.
  Çözüm yönü: `startScan` `lastReport`'u yalnızca yeni sonuç gelince
  temizlesin (ya da geri alınabilir raporu ayrı tutsun); Akıllı Tarama
  temizlik sonrası özet satırı + atlanan/başarısız sayısı + Geri al
  göstersin; `nil` dönüşü kullanıcıya "şu an taranıyor" desin. Doğrulama:
  `swift` bu ortamda yok; yalnızca kod yolu okunarak doğrulandı, Mac'te
  denenmedi. (Kaynak: `App/Features/SmartScan/SmartCare.swift:272-276`,
  `App/Features/SmartScan/SmartScanView.swift:37-46,74`,
  `App/Features/Cleanup/CleanupModel.swift:45-47,90-98,137-138`,
  `App/Features/Assistant/KeelTools.swift:71-78`,
  `App/Features/Assistant/AccountSession.swift:293-298`,
  `App/Features/Cleanup/CleanupView.swift:28-32`)
- KeelCore, uygulamanın hiç kullanmadığı, API anahtarlı bir ağ yolu
  taşıyor. PLAN "Keel AI ... API anahtarı yok" ve "Bağımlılık sıfır, sade
  ve denetlenebilir" diyor. Oysa `AnthropicBackend` (x-api-key),
  `OpenAICompatibleBackend` (keyfi `baseURL` + Bearer anahtar),
  `ModelCatalog` (anahtarla model listesi), `URLSessionTransport`,
  `URLSessionHTTPClient`, `SSEParser` ve `AssistantEngine` sınıfı
  (`ChatSession` uyumu için) paketin public API'sinde duruyor. `App/`
  altında `AnthropicBackend`, `OpenAICompatibleBackend`, `ModelCatalog`,
  `URLSessionTransport`, `AssistantEngine(` araması sonuç vermedi; yalnızca
  `AITool`, `AssistantEvent`, `ChatSession`, `ModelNames` gibi tipler
  kullanılıyor. Kalıntı, "kendi sağlayıcını getir" dönemindeki ilk Keel AI
  çekirdeğinden (commit 02c21eb). Zarar: bugün tetiklenmiyor; ama ileride bir
  değişiklik motoru bağlarsa araç sonuçları (dosya adları dahil) keyfi bir
  uç noktaya anahtarla gidebilir ve §Keel AI "özet veri, hesap girişi
  sağlayıcının akışında" sözünü sessizce deler; denetim yüzeyi de ~530
  satır (+ AssistantTests'in 320 satırı) fazla. Dokunduğu ilke: PLAN §1
  bağımlılık/sadelik, Keel AI veri akışı (mahkeme zorunlu alanı). Test:
  yalnızca AssistantTests bunu çalıştırıyor, yani kullanılmayan kodu
  korumak için test yazılmış. Çözüm yönü: ya kaldır (AITool, AssistantEvent,
  ChatSession, JSONValue, ModelNames, Usage'ın kullanılan kısmı kalsın) ya
  da PLAN'a "BYO anahtar yolu bilerek tutuluyor" diye yaz. Silinecek parça
  için mahkeme kararı gerekir. Doğrulama: kullanım yalnızca grep ile
  doğrulandı (isim araması); `swift build` bu ortamda yok, silmenin
  derlemeyi bozmayacağı doğrulanmadı. (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/AI/AnthropicBackend.swift:8,70`,
  `Packages/KeelCore/Sources/KeelCore/AI/OpenAICompatibleBackend.swift:9,27,62`,
  `Packages/KeelCore/Sources/KeelCore/AI/ModelCatalog.swift:27-38,66-70`,
  `Packages/KeelCore/Sources/KeelCore/AI/URLSessionTransport.swift:9`,
  `Packages/KeelCore/Sources/KeelCore/AI/AssistantEngine.swift:32`,
  `docs/PLAN.md:20,157`)
- İşlem günlükleri eşzamanlı yazımda satır kaybedebilir. `ActionLog.append`
  ve kopyası `LaunchActionLog.append` her çağrıda yeni bir `FileHandle`
  açıp `seekToEnd()` ve ardından `write` yapıyor; `O_APPEND` yok, kilit ya
  da seri kuyruk yok. İki yazıcı aynı anda EOF'a konumlanırsa ikincisi
  birincinin satırının üzerine yazar. Temizlik, Büyük Dosyalar ve Uygulama
  kaldırma ayrı `Task.detached` içinde çalışıyor ve yalnızca kendi modelinin
  `phase`'ini denetliyor, yani kullanıcı bir temizlik sürerken başka
  ekrandan kaldırma başlatabilir ya da Geri al (`TrashRestorer` aynı
  dosyaya yazar) çalışabilir. Eski günlük kuralı binlerce dosyayı tek tek
  kaydeder (`AgedFilesSource`), yani çakışma penceresi uzun. Senaryo:
  2.000 eski günlük dosyası temizlenirken 4 GB'lık bir dosya Çöp'e atılır;
  `actions.log`'ta bazı satırlar yok, §2.7 "Her işlem kaydedilir" sessizce
  bozulur. Önceki "günlük `try?` ile yazılıyor" önerisinden farkı: orada
  yazma hatası, burada hatasız ama kayıp yazım. Test: `UndoTests`,
  `LaunchActionLogTests` yalnızca sıralı eklemeyi (50 ardışık satır) deniyor;
  eşzamanlı test yok. Çözüm yönü: tek ortak `AppendOnlyJSONLog` yazıcısı
  (iki kopya birleşir), `open(path, O_WRONLY | O_APPEND | O_CREAT, 0o600)`
  ve satırı tek `write(2)` ile yazmak (POSIX, tek yazma için atomik ekleme
  sağlar); test: `DispatchQueue.concurrentPerform` ile 8x200 ekleme sonrası
  1.600 satır beklemek, Linux'ta çalışır. Doğrulama: yarış kod okunarak
  çıkarıldı; `swift` yok, çakışma gerçekte üretilmedi, olasılığı ölçülmedi.
  Günlüğün dosya izni de (varsayılan umask) bu değişiklikte belirlenebilir.
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/Actions/ActionLog.swift:42-60`,
  `Packages/KeelCore/Sources/KeelCore/Startup/LaunchActionLog.swift:63-81`,
  `Packages/KeelCore/Sources/KeelCore/Actions/TrashRestorer.swift:47,69`,
  `Packages/KeelCore/Tests/KeelCoreTests/LaunchActionLogTests.swift:38-45`)
