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
- Uygulama kaldırıcı, uygulamaya ait arka plan görevinin (LaunchAgent) plist'ini
  Çöp'e taşıyor ama görevi launchd'den çıkarmıyor. `AppLeftoverFinder`
  `~/Library/LaunchAgents` içinde bundle ID ile eşleşen plist'leri "Arka plan
  görevi" diye listeliyor; `Uninstaller.perform` hepsini `moveToTrash` ile
  taşıyor, `launchctl bootout` yok (repoda `bootout` yalnızca `LaunchControl`
  ve `FanHelper`'da). Senaryo: kullanıcı "Sıfırla" (`removesApp == false`)
  der; uygulamanın verisi ve plist'i Çöp'e gider, ama yüklü görev oturum
  kapanana kadar çalışmaya devam eder (KeepAlive ise yeniden başlar) ve az
  önce silinen tercih/destek dosyalarını yeniden yazar; kullanıcı sıfırlamanın
  işe yaramadığını sanır. Tam kaldırmada uygulama gidince görev başlatamaz
  hale gelir, ama launchd kaydı oturum sonuna kadar kalır. Çalışan-uygulama
  denetimi (§2.6 ruhu) yalnızca ana uygulamanın bundle ID'sine bakıyor
  (`NSWorkspace.runningApplications`), yardımcı görevi görmüyor. Dokunduğu
  ilke: §2.2 (gösterilen eylem gerçekle uyuşmalı), §2.6 ruhu. launchd'nin
  silinen plist'e sahip yüklü görevi bıraktığı genel bilgi; Mac'te
  doğrulanmadı, `swift` bu ortamda yok. Test yok: `ApplicationsTests`
  içinde `launchAgents` geçmiyor. Çözüm yönü: planda `.launchAgents`
  öğesi varsa taşımadan önce `gui/<uid>/<Label>` için `bootout` çalıştır
  (kullanıcı alanı, yönetici şifresi gerekmez; `LaunchControl`'ün komut
  üretimi KeelCore'da yeniden kullanılabilir) ya da kartta "çıkış/yeniden
  oturum gerekir" uyarısı göster; komut üretimi Linux'ta test edilir. Mahkeme
  gerekir (silme akışı). (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/Applications/AppLeftovers.swift:58`,
  `Packages/KeelCore/Sources/KeelCore/Applications/Uninstaller.swift:129-165`,
  `Packages/KeelCore/Sources/KeelCore/Startup/LaunchControl.swift:53-60`,
  `Packages/KeelCore/Tests/KeelCoreTests/ApplicationsTests.swift`)
- Yeniden açılan eski sohbetin geçmişi, son mesaj uzunsa modele hiç
  gönderilmiyor ve kullanıcıya söylenmiyor. `ChatStore.transcript` mesajları
  yeniden eskiye doğru geziyor ve `length + line.count > 6_000` olunca
  `break` ediyor. En yeni mesajın kendisi 6.000 karakterden uzunsa (uzun bir
  Keel AI cevabı ya da kullanıcının yapıştırdığı metin) ilk turda duruyor ve
  sonuç boş dize oluyor. `AssistantModel.send` yine de boş metni
  `<previous_conversation>\n\n</previous_conversation>` içine sarıp
  gönderiyor ve `restoredTranscript`'i tüketiyor. Senaryo: kullanıcı uzun bir
  dosya listesi cevabı olan sohbeti açıp "ilkini silelim mi?" diye soruyor;
  model hiçbir bağlam görmüyor ve bağlamsız cevap veriyor. Önceki "ilk mesaj
  başarısız olursa geçmiş kayboluyor" önerisinden farkı: orada gönderim
  hatası, burada başarılı gönderimde bile geçmişin sessizce boş kalması.
  Karar "en yeni mesajı kırp, hiç yoksa uyar" olmalı; şimdi uzun mesaj
  tüm geçmişi siliyor. Dokunduğu ilke: Keel AI veri akışı (sözleşmeye göre
  yalnızca özet veri gider; bu boş bağlam o sözü bozmuyor, doğruluğu
  bozuyor), §2 değil. Test yok: `ChatStore` App katmanında,
  `Tests/` altında `transcript` geçen test yok. Çözüm yönü: son mesajı
  `maxCharacters`'e kırpıp dahil etmek, sonuç boşsa `<previous_conversation>`
  bloğunu hiç eklememek; `transcript`'i KeelCore'a taşıyıp "tek uzun mesaj",
  "kısa mesajlar", "notice atlanır" testlerini yazmak (Linux'ta çalışır).
  Mac'te doğrulanmadı; kod yolu okunarak doğrulandı. (Kaynak:
  `App/Features/Assistant/ChatStore.swift:80-90`,
  `App/Features/Assistant/AssistantModel.swift:178-182,371`)
- Performans ekranındaki "En çok işlemci kullananlar" kartı, tam liste gibi
  sunuluyor ama sistemin en çok CPU kullanan süreçlerini göremeyebilir.
  `ProcessCPU.sample` `guard pid > 0` ile `kernel_task`'ı (pid 0) açıkça
  atıyor ve `proc_pidinfo(PROC_PIDTASKINFO)` başarısız olan her süreci
  sessizce bırakıyor; belge yorumu "kullanıcının inceleyebildiği süreçler"
  diyor, ama kartta (`CardTitle` yalnızca "% bir çekirdeğe göre" der) bu
  sınır yok. Senaryo: Mac ısınıyor ve fanlar yükseliyor, sebep
  `kernel_task` ya da root altında çalışan `mds_stores`/`WindowServer`;
  kart başka (kullanıcı) süreçleri sıralıyor ve kullanıcı yanlış uygulamayı
  kapatıyor. Aynı kök: sınır `ProcessMemory.samples` için de geçerli ama
  orada liste yalnızca GUI uygulamaları. Ayrıca `lastProcessSample`
  ekrandan çıkınca korunuyor; 10 dk sonra ekrana dönüşte ilk yenileme 10
  dakikalık ortalamayı anlık değer gibi gösteriyor (sonraki tur düzeliyor).
  Root süreçlerinin okunamaması genel bilgi, Mac'te doğrulanmadı. Test:
  `SystemReadersTests` yalnızca `usage` hesabını deniyor ve fixture'da
  `kernel_task`'ı pid 1 ile (gerçekte launchd) yazmış; `sample()` için
  test yok. Çözüm yönü: kartın altına "Yalnızca senin süreçlerin; sistem
  süreçleri okunamaz" notu (ya da okunamayan süreçlerin toplamını "diğer"
  satırıyla göstermek, `host_statistics` toplamıyla farkı hesaplayarak),
  ekrana her girişte `lastProcessSample`'ı sıfırlamak, fixture'ı düzeltmek.
  PLAN §2'ye değmiyor, salt okunur. (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/System/ProcessCPU.swift:36-61,70-90`,
  `App/Features/Performance/PerformanceModel.swift:22,72-79`,
  `App/Features/Performance/PerformanceView.swift:92-98,755`,
  `Packages/KeelCore/Tests/KeelCoreTests/SystemReadersTests.swift:148-164`)
- Uygulama önbellekleri kuralı, adında nokta olmayan klasörlerin sahibini
  bilmiyor; bu yüzden o klasörler için "çalışan uygulamanın önbelleğine
  dokunulmaz" denetimi hiç çalışmıyor. `ChildrenSource.owner(forName:)`
  `.bundleIDFromName` modunda adı "." içermeyen klasöre `nil` veriyor;
  `CleanupScanner.scan` ve `CleanupExecutor.perform` yalnızca `owner != nil`
  ise `runningApp(owning:)` bakıyor. Senaryo: JetBrains IDE açıkken (indeks
  önbelleği `~/Library/Caches/JetBrains/...`) ya da Bundle ID'siyle değil
  adıyla klasör açan herhangi bir uygulama çalışırken "Uygulama önbellekleri"
  taranıyor; klasör `catalog` hariç tutma listelerinde yok, owner `nil`,
  kart "Çalışıyor, atlandı" demeden öğeyi listeliyor ve onayda Çöp'e
  taşıyor (varsayılan seçili kategori). Uygulama indeksi yeniden kurar ya da
  bozuk durumda kalır. Hariç tutma listeleri bu açığı tek tek elle
  kapatma denemesi (`Google`, `Firefox`, `BraveSoftware`...). Ayrıca denetim
  büyük/küçük harfe duyarlı: `runningApp` `Set.contains` ile
  karşılaştırıyor, `CleanupModel.refreshRunningApps` Bundle ID'leri
  olduğu gibi tutuyor; `Uninstaller` ve `LargeFileRemover` ise
  `lowercased()` kullanıyor, tutarsız. Dokunduğu ilke: §2.6. Mac'te
  doğrulanmadı (JetBrains yolu genel bilgi, `swift` bu ortamda yok); kod yolu
  okunarak doğrulandı. Test: `CleanupScannerTests` ve `CleanupExecutorTests`
  yalnızca noktalı `com.spotify.client` ile deniyor; noktasız klasör ve harf
  farkı için test yok. Çözüm yönü: `ScanContext`'e çalışan uygulamaların
  adlarını da ekleyip (LargeFiles'taki `runningNames` gibi) noktasız klasör
  adını bunlarla eşleştirmek, karşılaştırmayı `lowercased()` yapmak, iki
  durumu Linux'ta test etmek. Mahkeme gerekir (silme akışı, §2.6).
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/Cleanup/CandidateSource.swift:97-103`,
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CleanupScanner.swift:66,99-102`,
  `Packages/KeelCore/Sources/KeelCore/Actions/CleanupExecutor.swift:65`,
  `App/Features/Cleanup/CleanupModel.swift:167-173`,
  `Packages/KeelCore/Tests/KeelCoreTests/CleanupScannerTests.swift:53`)
- "Eski indirmeler" kartı, klasörlerin yaşını yalnızca klasörün kendi
  tarihinden hesaplıyor; içinde yakın zamanda çalışılmış bir klasör "90
  günden uzun süredir açılmamış" diye öneriliyor. `ChildrenSource` Downloads
  altındaki her çocuk için `FileActivity.lastActivity(of:)` çağırıyor; bu,
  öğenin kendi değişiklik tarihi, klasöre eklenme tarihi ve Spotlight "son
  açılma" tarihinin en büyüğü. Klasörün değişiklik tarihi yalnızca doğrudan
  çocuklar eklenip silinince ya da yeniden adlandırılınca değişir; derindeki
  bir dosyayı düzenlemek değiştirmez. Senaryo: kullanıcı 4 ay önce indirdiği
  bir proje arşivini Downloads'a açmış ve hâlâ içinde çalışıyor (alt klasörde
  dosya düzenleniyor); klasör 90 günü aşmış görünüyor, kart (§2.2 gösterilen
  eylem gerçekle uyuşmalı) yanlış bilgiyle listeliyor. Etki sınırlı: kategori
  varsayılan seçili değil ve Çöp'e gidiyor (geri alınabilir), ama yanlış
  yaşla sunulan öğe kullanıcının güvenini zedeliyor. Test: tek test yalnızca
  tek dosyayı deniyor (`old-installer.dmg`); eski klasör içinde yeni dosya
  durumu yok. macOS'ta Spotlight'ın klasör için `kMDItemLastUsedDate`
  davranışı doğrulanmadı. Çözüm yönü: öğe klasörse (ya da paketse) en yeni
  alt dosya değişiklik tarihini `DirectorySizer` taramasıyla birlikte
  toplayıp `lastActivity`'ye katmak; testi Linux'ta yazmak (eski klasör +
  yeni iç dosya, `lastActivity` enjekte edilmediği için gerçek tarihlerle).
  Mahkeme gerekir (silme adayı seçimi). (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CandidateSource.swift:89-92`,
  `Packages/KeelCore/Sources/KeelCore/Scanning/FileActivity.swift:12-36`,
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CleanupCatalog.swift:145`,
  `Packages/KeelCore/Tests/KeelCoreTests/CleanupScannerTests.swift:95`)
