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
- Üç ekranda "Geri al" düğmesi, geri yükleme sürerken yeniden basılabiliyor ve
  çifte tıklama yanlış "geri yüklenemedi" gösterebiliyor. `undoLastCleanup`,
  `LargeFilesModel.undoLastRemoval` ve `ApplicationsModel.undoLastRemoval`
  yalnızca `phase == .ready` arıyor, ama `await Undo.restore` boyunca `phase`
  değişmiyor ve `lastReport` temizlenmiyor. Banner'daki düğme de devre dışı
  kalmıyor (`ReportBanner`'da `disabled` yok). Senaryo: kullanıcı büyük bir
  uygulamayı ya da dosyayı geri alırken düğmeye iki kez basar. İki `Task.detached`
  aynı `TrashedItem` listesini işler. `TrashRestorer.restore` önce
  `fileExists(inTrash)` ile bakıp sonra `moveItem` çağırdığı için biri kazanır,
  öbürü "Çöp Kutusu'nda artık yok" ya da taşıma hatasıyla düşer. Sonuç:
  `actions.log`'a gerçekte olmayan `failed` "undo:" satırları yazılır ve
  `lastRestore`'u son biten çağrı belirler. Bitiş sırası belirsiz olduğu için
  banner, geri yükleme başarılı olduğu halde "geri yüklenemeyen öğe" diyebilir
  (§2.7 kayıt doğruluğu, §2.1 güvenin dayanağı geri alma). Ek yarış:
  `CleanupModel.startScan` başka bir tarama sürüyorsa 91. satırda erken dönüyor
  ve `lastReport`'u (97) temizlemiyor. Böyle olunca eski banner ve "Geri al"
  yerinde kalır, geri konan öğeler de eski taramanın listesinde görünmez. Test
  durumu: `UndoTests` tek çağrıyı, çakışmayı ve Çöp'te olmayan öğeyi deniyor;
  yeniden girişli ya da iki kez geri alma yok, model katmanı App'te olduğu için
  testsiz. Çözüm yönü: her üç modelde geri alma sırasında bir `isRestoring`
  bayrağı (düğme devre dışı, `guard`), `lastReport`'u geri almanın başında
  temizlemek. `TrashRestorer`'a "zaten orijinal yerinde" durumunu hata değil
  "zaten geri konmuş" saymak ve bunun için KeelCore testi yazmak. Mac'te
  doğrulanmadı; mantık platformdan bağımsız, kod yolu okunarak doğrulandı.
  (Kaynak: `App/Features/Cleanup/CleanupModel.swift:91,97,160-165`,
  `App/Features/LargeFiles/LargeFilesModel.swift:198-203`,
  `App/Features/Applications/ApplicationsModel.swift:261-267`,
  `App/Features/Cleanup/CleanupView.swift:418-424`,
  `App/Features/Applications/ApplicationsView.swift:26`,
  `App/Features/LargeFiles/LargeFilesView.swift:25`,
  `Packages/KeelCore/Sources/KeelCore/Actions/TrashRestorer.swift:53-68`,
  `Packages/KeelCore/Tests/KeelCoreTests/UndoTests.swift`)
- Büyük Dosyalar, bulut senkronizasyonlu klasörleri ayırt etmiyor; "Çöp'e taşı"
  orada yalnızca yerel bir taşıma olmayabilir. `LargeFileScanner.scan` ev
  klasörünün üst düzey klasörlerini (`Library`, `Applications`, `.Trash`
  hariç) tarıyor. Masaüstü, Belgeler ve kullanıcının `~/Dropbox`, `~/OneDrive`
  gibi klasörleri listeye girebiliyor. Boş durum metni "iCloud ... listelenmez"
  diyor (`LargeFilesView.swift:104`). Kod ise yalnızca `Library/Mobile Documents`
  yolunu koruyor (`SafetyPolicy.swift:188`), yani sözün tuttuğu yer
  `~/Library/Mobile Documents`. "Masaüstü ve Belgeler iCloud'da" açıksa ya da
  klasör Dropbox/OneDrive ile eşleşiyorsa, dosyayı Çöp'e taşımak silmeyi
  diğer cihazlara yayabilir ve Geri al yalnızca yerel Çöp'ü kapsar. Kodda
  "senkron/sync/bulut" için hiçbir denetim, uyarı ya da test yok; `grep` yalnızca
  `size()` içindeki "online-only dosyalar boyuta girmez" yorumunu buluyor.
  Dokunduğu ilke: §2.4 (iCloud Drive korunur), §2.2 (onaydan önce doğru bilgi).
  Çözüm yönü: önce bilinçli karar. Senkron kökleri tespit edip (ör.
  `URLResourceKey.isUbiquitousItemKey`, bilinen sağlayıcı klasör adları)
  listede rozet ve onay metninde uyarı göstermek, ya da bu dosyaları bulucudan
  çıkarmak. Boş durum metni de gerçeği söylemeli. Mac'te doğrulanmadı: macOS'un
  Masaüstü/Belgeler'i iCloud açıkken hangi yolda gösterdiği, `isUbiquitousItem`
  değerinin bu dosyalarda ne döndürdüğü ve Çöp'e taşımanın iCloud'a nasıl
  yansıdığı. Test yok: `LargeFilesTests` yalnızca sahte ev klasöründe düz
  dosya, paket ve `~/Library` senaryolarını deniyor.
  (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/LargeFiles/LargeFiles.swift:74,140-146,215`,
  `Packages/KeelCore/Sources/KeelCore/Safety/SafetyPolicy.swift:188`,
  `App/Features/LargeFiles/LargeFilesView.swift:104`,
  `Packages/KeelCore/Tests/KeelCoreTests/LargeFilesTests.swift:12-27`)
- Keel AI'da yeniden açılan eski sohbetin geçmişi, ilk mesaj başarısız ya da
  iptal olursa modele hiç ulaşmadan kayboluyor. `open(_:)` sohbeti ekrana
  yükleyip `restoredTranscript` doldurur (371). `send` bu alanı mesaja ekler ve
  görev başlamadan `nil` yapar (179-181). `session.send` sonradan hata fırlatırsa
  (CLI bulunamadı, giriş gerekiyor, kullanım sınırı) ya da kullanıcı Durdur'a
  basarsa, `catch` dalı (190-199) transkripti geri koymuyor. Başarısız ilk
  çalıştırmada `AccountSession` ne `conversationID`'yi ne de oturumu saklıyor
  (`runClaude`/`runCodex` yalnızca başarıda atıyor). Senaryo: kullanıcı üç
  günlük bir sohbeti açar, mesaj yazar, "yeniden giriş gerekiyor" hatası alır,
  giriş yapıp aynı mesajı tekrar gönderir. Ekranda eski sohbet duruyor, ama
  model onu görmemiştir ve "yukarıdaki dosyayı silelim mi?" gibi bir devam
  sorusuna bağlamsız cevap verir. Kullanıcıya hiçbir şey söylenmiyor. Aynı
  yerde, iptalde çıkan not "Bu mesaj sohbet geçmişine eklenmedi" diyor
  (196), oysa hemen ardından `persist()` kullanıcı mesajını ve notu diske yazıyor
  (`.user` ve `.notice` öğeleri kaydediliyor), yani söz kayıt davranışıyla
  çelişiyor. Dokunduğu ilke: §2 değil; Keel AI kullanıcıya doğru durum
  göstermeli (§2.2 ruhu), silme yok, zarar yok. Test durumu: `AssistantModel`
  App katmanında, test yok. Çözüm yönü: transkripti yalnızca `session.send`
  başarılı olunca tüketmek (hata/iptalde geri koymak), iptal notunu gerçeğe
  uydurmak. Karar mantığı küçük bir saf yapıya (ör. "bekleyen bağlam")
  alınıp KeelCore'da test edilebilir. Mac'te doğrulanmadı; kod yolu okunarak
  doğrulandı.
  (Kaynak: `App/Features/Assistant/AssistantModel.swift:80,176-199,333-343,371`,
  `App/Features/Assistant/AccountSession.swift:127-134,149-151,219-221`)
