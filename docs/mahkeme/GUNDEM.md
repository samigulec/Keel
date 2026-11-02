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
- Fan yardımcısı kuruluyken "Keel kapanınca fanlar otomatiğe döner" sözü
  yalnızca aynı oturumda ayarlanan hızlar için doğru. `handBackFansOnQuit`
  bellekteki `fanSetting`'e bakıyor; bu alan her açılışta nil başlıyor ve
  yalnızca başarılı `setFans` ile doluyor. Keel fanlar elle ayarlıyken çökerse,
  zorla kapatılırsa ya da yeniden açılıp kapatılırsa hiçbir istek yazılmıyor,
  fanlar yeniden başlatmaya kadar sabit kalıyor. Oysa Performans ekranı (elle
  durumu SMC'den okuyor) "Keel kapanınca macOS'e döner", Ayarlar da "Kurulu:
  ... Keel kapanınca otomatiğe döner" diyor: kullanıcıya yanlış güvence. PLAN
  Faz 2 fan yardımcısı maddesinin sözü; §2 ihlali değil. `willTerminate`
  bildiriminin çökme/SIGKILL'de gelmediği genel bilgi, Mac'te doğrulanmadı.
  Karar mantığı App'te olduğu için test yok. Çözüm yönü: Keel'in son
  uyguladığı fan ayarını UserDefaults'a yazmak, kapanışta ve açılışta
  "Keel ayarladı ve SMC hâlâ elle" ise otomatiğe dönmek (başka araçların
  ayarına dokunmadan); kararı KeelCore'da saf bir fonksiyona alıp test etmek.
  (Kaynak: `App/Features/Performance/PerformanceModel.swift:160,189-192,200`,
  `App/Features/Performance/PerformanceView.swift:699`,
  `App/Features/Settings/SettingsView.swift:55`)
- Temizlik sonucu "X GB temizlendi" diyor ama öğeler yalnızca Çöp Kutusu'na
  taşındı; Çöp boşaltılana kadar diskte yer açılmaz. `CleanupReport.freedBytes`
  `removed` toplamı (Çöp'ten kalıcı silinenler dahil). Kullanıcı bandı görüp
  disk doluluğuna bakınca değişiklik görmez; Akıllı Tarama'daki "Disk
  neredeyse dolu" bulgusu da aynen kalır. Büyük Dosyalar ve Uygulamalar
  ekranları aynı durumu doğru söylüyor ("Çöp Kutusu'na taşındı"), yani ekranlar
  arasında tutarsızlık da var. Karışık raporda (Çöp + önbellek) "Geri al"
  düğmesi görünüyor ama kalıcı silinen kısmın geri alınamayacağı yazmıyor
  (§2.1 güveninin dayanağı Çöp'e taşıma; §2.2 gösterilen bilgi doğru olmalı).
  Metin App katmanında, test yok. Çözüm yönü: rapora Çöp'e taşınan ve kalıcı
  silinen baytları ayrı alanlarla koymak; metin "X GB Çöp Kutusu'na taşındı;
  Çöp boşaltılınca yer açılır" olsun, kalıcı silinen varsa ayrıca belirtilsin.
  (Kaynak: `App/Features/Cleanup/CleanupView.swift:410,428-433`,
  `App/Features/Assistant/AssistantView.swift:404`,
  `Packages/KeelCore/Sources/KeelCore/Actions/CleanupExecutor.swift:15,89`,
  `App/Features/LargeFiles/LargeFilesView.swift:334`)
- Akıllı Tarama sağlık puanı PLAN'daki sözle uyuşmuyor ve kendi içinde
  tutarsız. PLAN §3: formül "disk doluluğu + temizlenebilir alan + bellek
  baskısı" ve arayüzde "Bu puan nasıl hesaplanır?" ile gösterilecek. Kodda
  sekiz girdi var (önbellek, disk, eski dosyalar, kullanılmayan uygulamalar,
  bellek, ısı, pil, başlangıç servisleri) ve arayüzde formülü ya da kesintileri
  gösteren hiçbir yer yok ("nasıl hesaplan" aranınca sonuç yok; halka yalnızca
  "sağlık" yazıyor). Ayrıca eşikler çelişiyor: halka 85+ yeşil
  (`ScoreRing.color`), başlık ise 90 altında "Mac'in fena değil; N konu
  ilgilenmeni bekliyor" diyor; 85-89 arası yeşil halka + "fena değil".
  Okunamayan girdi (disk/bellek nil, servis listesi yüklenmedi) hiç kesinti
  yaratmıyor, yani veri yokken puan 100'e yakın ve "çok iyi durumda" çıkıyor.
  Puan mantığı (`CareReport.evaluate`) saf bir fonksiyon ama App'te; CLAUDE.md
  "mantık KeelCore'da" kuralına aykırı ve test yok. Çözüm yönü: fonksiyonu
  KeelCore'a taşıyıp kesinti listesini (neden, puan) döndürmek, arayüzde
  göstermek, eşikleri tek yerde tanımlamak, eksik girdiyi "ölçülemedi" diye
  işaretlemek ve eşik/kesinti testleri yazmak. (Kaynak:
  `App/Features/SmartScan/SmartCare.swift:43-173`,
  `App/Features/SmartScan/SmartScanView.swift:93-103,207-251`,
  `docs/PLAN.md:58`)
