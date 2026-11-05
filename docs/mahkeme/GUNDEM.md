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
- İptal edilen süreç "başarılı" dönüyor: `ProcessLines.run` görevi iptal
  edilince boş/kısmi çıktıyla `(status: 0, ...)` veriyor. `onTermination`
  `.cancelled` iken `box.cancel()` süreci sonlandırıyor; `AsyncThrowingStream`
  iptalde `nil` döndüğü için `for try await` döngüsü hatasız biter ve
  `status != 0, !box.wasCancelled` koşulu `finish()`'i hatasız çağırır; `run`
  de `return (0, lines.joined(separator: "\n"))` yapar. Çağıranlar bunu gerçek
  sonuç sayıyor: `SystemControl.overrides` (`result.status == 0` ->
  `parseOverrides("")` -> `[:]`), `appleScript` (`.done("")`) ve
  `CLITool.version/account`. Senaryo 1: Optimizasyon'a ilk girişte macOS
  "Keel, System Events'i denetlemek istiyor" izni sorar; `osascript` yanıt
  beklerken kullanıcı başka sekmeye geçer. `.task` iptal olur, `osascript`
  sonlandırılır, `loginItems()` `.success([])` döner ve
  `refreshLoginItems` `loginItemsLoaded = true`, `loginItemsError = nil`
  yapar: ekran "girişte açılan uygulama yok" der, Keel AI de
  `loginItemsWhenReady()` ile boş liste görür. Aynı iptalle
  `refreshLaunchItems` boş `overrides` ile taranıp `launchItemsLoaded = true`
  yapar ve kapatılmış servisler "açık" görünür. Senaryo 2: Keel AI
  sağlayıcı paneli `.task { refreshAll() }` ile `locate()` çalışırken
  kapatılırsa `whence -ap` ve `--version` çağrıları boş döner,
  `cachedExecutable = fallback` ilk bulunan (eski olabilir) kurulumu oturum
  boyunca kalıcı tutar ve hesap "girişli değil" görünebilir. Ayrıca
  `Box.wasCancelled` 109. satırda kilitsiz okunuyor (`cancel()` kilitle
  yazıyor), `@unchecked Sendable` altında yarış. PLAN §2.2 ruhu (ekranda
  gösterilen durum gerçeği yansıtmalı). Önceki "print-disabled başarısız
  olursa" maddesinden farkı: orada çıkış kodu hatalı; burada iptal kodu
  0'a çeviriyor. Test: `ClaudeCodeTests` yalnızca normal, başarısız ve
  birleşik-stderr çalıştırmayı deniyor; iptal testi yok, `ProcessLines`
  KeelCore'da olduğu için Linux'ta yazılabilir (`sleep 5` çalıştır, görevi
  iptal et, sonucun hata/iptal olduğunu bekle). Çözüm yönü: `run` döngüden
  sonra `try Task.checkCancellation()` atsın (ya da özel iptal durumu
  döndürsün); `refreshLaunchItems`, `refreshLoginItems` ve `locate`
  iptalde durumu yazmasın / önbelleğe atmasın; `wasCancelled` kilitle
  okunsun. Mac'te çalıştırılmadı; bu ortamda `swift` yok, kod yolu
  okunarak doğrulandı (iptalde `nil` dönen `AsyncThrowingStream` davranışı
  Swift belgesinden biliniyor, derleyicide denenmedi). (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/AI/ProcessLines.swift:17-49,71-73,109-113,125-142`,
  `App/Features/Performance/SystemControl.swift:36-40,62-66`,
  `App/Features/Performance/PerformanceModel.swift:81-90,120-128`,
  `App/Features/Optimization/OptimizationView.swift:58-61`,
  `App/Features/Assistant/CLITool.swift:86-100,108-111,127,168-181`,
  `App/Features/Assistant/ProviderPanel.swift:57`,
  `Packages/KeelCore/Tests/KeelCoreTests/ClaudeCodeTests.swift:86-108`)
- Canlı sistem okumaları pencere kapalıyken de sürüyor (enerji/pil).
  `SystemStatus.init` iki saniyelik döngüyü hiç durdurmadan başlatıyor:
  her turda `LiveReading.take` bellek, yük, CPU, çekirdek başına CPU, GPU,
  disk G/Ç (IORegistry) ve ağ (`sysctl` yönlendirme tablosu) okuyor; her
  2. turda (4 sn) `SensorReader.snapshot` SMC ve HID sensörlerini açıyor;
  30 sn'de bir disk ve pil okunuyor. `scenePhase`, pencere görünürlüğü ya da
  popover durumu hiçbir yerde denetlenmiyor (App/ altında `scenePhase`,
  `isVisible`, `occlusion` araması sonuç vermedi). Menü çubuğu simgesi sabit
  (`MenuBarExtra("Keel", systemImage: "gauge.with.dots.needle.33percent")`),
  yani değerler yalnızca ana pencere görünürken ya da popover açıkken
  okunuyor. Senaryo: kullanıcı Keel'i menü çubuğunda açık bırakıp pencereyi
  kapatıyor (ya da menü çubuğu seçeneğini kapatıp pencereyi küçültüyor);
  dizüstünde saatlerce 2 sn aralıkla IOKit/SMC okuması sürüyor, oysa bunları
  kimse görmüyor. Bir bakım uygulaması için pil/enerji tutarsızlığı. PLAN
  §2 ilkesine değmiyor; Faz 2 "Menü çubuğunda canlı grafikler" maddesi
  yapılırsa okuma ihtiyacı değişir, kararı o maddeyle birlikte almak gerekir.
  Gerçek maliyet ölçülmedi (Mac'te Activity Monitor "Energy Impact" /
  Instruments gerekir, doğrulanmadı). Test: `SystemStatus` App katmanında,
  test yok. Çözüm yönü: görünürlüğe bağlı `active` bayrağı (ana pencere
  `NSWindow.didChangeOcclusionState`, popover açık mı); görünmezken döngü
  uyusun ya da çok seyrek (ör. 30 sn) çalışsın; Keel AI araçları `status`
  verisini isterken `refreshNow`-benzeri tek seferlik okuma yapsın. Saf
  kısım (hangi turda hangi iş) küçük bir yapıya alınıp KeelCore'da test
  edilebilir. (Kaynak: `App/SystemStatus.swift:44-46,65-80,201-224`,
  `App/KeelApp.swift:36-72`,
  `Packages/KeelCore/Sources/KeelCore/Hardware/Sensors.swift:87-109`)
- Tam Disk Erişimi uyarısı yalnızca kullanıcı düğmeye basınca yenileniyor ve
  yeniden başlatma gerektiğini söylemiyor. `CleanupView`'da
  `@State hasFullDiskAccess = FullDiskAccess.isGranted` bir kez
  hesaplanıyor; yeniden denetim yalnızca "Tekrar kontrol et" düğmesinde,
  uygulama öne gelince (`didBecomeActive`) denetlenmiyor. Banner metni
  yalnızca "Keel'i aç" diyor. Sistem Ayarları'nda Tam Disk Erişimi verilen
  çalışan bir uygulamanın erişimi yeniden başlatmaya kadar değişmeyebilir
  (macOS "Quit & Reopen" sorar); bu doğrulanmadı, bkz. genel anlatım
  [iBoysoft](https://iboysoft.com/tips/full-disk-access-mac-not-working.html)
  (yalnızca arama sonucu başlığı; sayfa okunmadı). Senaryo: kullanıcı
  izni verip Keel'e döner, "Tekrar kontrol et"e basar, banner kalır ve Çöp
  Kutusu kategorisi hâlâ "Okunamadı: Tam Disk Erişimi gerekiyor" der;
  nedenini anlayamaz. İzin yoklaması ayrıca `~/Library/Safari` yoksa
  `true` dönüyor ("nothing to tell"), yani Safari klasörü olmayan bir
  kullanıcıda Çöp Kutusu okunamasa bile banner hiç çıkmaz (Çöp için
  kategori satırındaki ayrı uyarı kalır). Akıllı Tarama ve Keel AI
  ekranlarında FDA durumu hiç gösterilmiyor (`SmartScan/*.swift` içinde
  "unreadable"/"FullDisk" yok; `optInBytes` de `CareReport.evaluate`
  içinde kullanılmıyor). PLAN Faz 1 "Full Disk Access yoksa onboarding
  ekranı ve yönlendirme" maddesinin zayıf karşılığı; §2 ihlali değil. Düşük
  öncelik. Test: probe App katmanında (`FullDiskAccess`), test yok.
  Çözüm yönü: `NSApplication.didBecomeActiveNotification` ile otomatik
  yeniden kontrol; probe olarak `~/.Trash` (TCC korumalı) kullanmak; metne
  "Verdikten sonra Keel'i kapatıp yeniden aç" eklemek (yeniden başlatma
  gerekliliği Mac'te doğrulanınca). (Kaynak:
  `App/System/FullDiskAccess.swift:8-14`,
  `App/Features/Cleanup/CleanupView.swift:8,25-27,371-395`,
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CleanupScanner.swift:61,104-107`,
  `App/Features/SmartScan/SmartCare.swift:31,255-256`)
