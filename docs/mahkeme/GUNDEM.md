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
- Keel AI, hesap sağlayıcılarına (Claude/ChatGPT) kişisel dosya ADLARINI
  ve klasörlerini gönderiyor; PLAN "özet sistem verisi, içerik asla" der
  ama ad/klasör özet değil. `largeFilesSummary` her büyük dosyanın adını
  ve klasörünü (Documents/Desktop dahil, 30 adede kadar), `cleanupSummary`
  Downloads/Çöp öğelerinin yollarını yazıyor; `KeelContext.gather` bunları
  her mesaja otomatik ekliyor. Kullanıcıya gönderilecekleri gösteren ya da
  kapatan bir ayar yok; Ayarlar metni yalnızca "içerik gönderilmez" diyor.
  Ad gizleme (tür+boyut+yaş) ya da açık onay mahkemelik. (Kaynak:
  `App/Features/Assistant/KeelTools.swift:228-229,435-437`,
  `App/Features/Assistant/AccountSession.swift:293-298,312-314`,
  `App/Features/Settings/SettingsView.swift:80`)
- Fan kontrolü yönetici şifresiyle root olarak `Bundle.main.executablePath`
  çalıştırıyor; Keel kullanıcının yazabildiği bir konumdaysa (DerivedData,
  ~/Applications, sürükle-bırak kurulum) dosya şifre isteminden önce
  değiştirilirse istem "Keel" der, root'ta başka ikili çalışır (§2.8).
  Yardımcı kurulumu da aynı yolu root'a ait kopyaya çevirip kalıcı LaunchDaemon
  yapıyor. Çalıştırmadan önce kod imzası/sahiplik doğrulaması yok; App
  katmanı olduğu için testi de yok. (Kaynak:
  `App/Features/Performance/SystemControl.swift:116-122,139-144`,
  `Packages/KeelCore/Sources/KeelCore/Hardware/FanHelper.swift:93`)
- `launchctl print-disabled` başarısız olursa `overrides` sessizce `[:]`
  döndürüyor; `refreshLaunchItems` yine `launchItemsLoaded = true` yapıyor ve
  tarayıcı `overrides[label] ?? plist["Disabled"] ?? false` ile kullanıcının
  kapattığı servisleri "açık" gösteriyor. Keel AI de `item.isDisabled ==
  enable` süzgecinde bu yanlış duruma güvenip "değiştirilecek bir şey yok"
  diyor. Hata kullanıcıya hiç söylenmiyor; `overrides` hata yolu için test
  yok. (Kaynak: `App/Features/Performance/SystemControl.swift:62-65`,
  `App/Features/Performance/PerformanceModel.swift:83-89`,
  `Packages/KeelCore/Sources/KeelCore/Startup/LaunchItems.swift:81`,
  `App/Features/Assistant/ActionProposals.swift:103`)
- Keel AI "Girişte açılmasın" kartı, kullanıcı iptal edince bile başarılı
  görünüyor. `apply` yalnızca `.failed` sonucunu hata sayıyor;
  `removeLoginItem` `.cancelled` döndürürse sorun listesi boş kalıyor, kart
  "N uygulama artık girişte açılmayacak" diyor ve Geri al düğmesi çıkıyor,
  oysa hiçbir şey değişmedi. Fan dalı `.cancelled` durumunu ayrı ele alıyor,
  bu dal almıyor; `PerformanceModel` de `startupMessage`'ı `.cancelled` için
  nil olan `errorMessage` ile dolduruyor. İptalin gerçekte hangi koşulda
  oluştuğu Mac'te doğrulanmadı. Onay sonrası sessiz yanlış durum (§2.2).
  App katmanı olduğu için test yok. (Kaynak:
  `App/Features/Assistant/ActionProposals.swift:181-184`,
  `App/Features/Performance/SystemControl.swift:13-17,42`,
  `App/Features/Performance/PerformanceModel.swift:139-143`)
- Geri alma başarısız olsa bile Keel AI temizlik kartı "Geri alındı; öğeler
  eski yerlerinde" yazıyor. `undoProposal` önce `undoableProposals` kaydını
  siliyor, sonra `Undo.restore` sonucuna bakmadan `undoneProposals.insert(id)`
  yapıyor. Tüm öğeler başarısız olsa da (Çöp boşaltılmış, eski yerde aynı
  adlı öğe var) kart geri alındı diyor, Geri al düğmesi kayboluyor ve yeniden
  denenemiyor; hata yalnızca sohbetteki ayrı bildirimde kalıyor (§2.1
  güveninin dayanağı geri alınabilirlik). Test yok. (Kaynak:
  `App/Features/Assistant/AssistantModel.swift:406-413`,
  `App/Features/Assistant/AssistantView.swift:398-401`)
- Temizlik onayı eski tarama sonucuna dayanıyor; `CleanupExecutor.perform`
  silmeden önce yaş/boyut/değişiklik koşulunu yeniden denetlemiyor, yalnızca
  çalışan uygulamayı ve `SafetyPolicy`'yi kontrol ediyor. Öğeler yola göre
  eşleşiyor ve taramanın yaşına bakılmıyor; tarama ile onay arasında aynı
  yola yeni bir dosya konursa o da onaylanmış sayılıp Çöp'e taşınabilir.
  Onaylanan ile silinen ayrışabiliyor (§2.2 "yalnızca seçilen öğeler").
  Yürütücü testlerinde bu senaryo yok. (Kaynak:
  `Packages/KeelCore/Sources/KeelCore/Actions/CleanupExecutor.swift:46-98`,
  `App/Features/Cleanup/CleanupModel.swift:137-150`)
