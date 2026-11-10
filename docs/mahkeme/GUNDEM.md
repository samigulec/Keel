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
- Büyük Dosyalar ekranında filtre (tür, konum, yaş, en az boyut) değişince
  seçim temizlenmiyor; görünmeyen dosyalar da onaylanıp Çöp'e taşınıyor.
  `selection` düz bir küme; `kind`, `place`, `age`, `minimumSize` değişince
  budanmıyor, yalnızca yeniden taramada (`scan`) "bulunamayanlar" süzülüyor.
  `selectedFiles`/`selectedBytes`/`removeSelected` süzgece bakmadan
  seçimin tamamını kullanıyor. Onay penceresi yalnızca "N dosya Çöp
  Kutusu'na taşınsın mı?" ve toplam boyutu yazıyor, dosya adı vermiyor.
  Liste de en büyük 200 satırla sınırlı. Senaryo: kullanıcı "Tümü"nde
  4 GB'lık bir videoyu işaretler, sonra "Uygulama verisi" ya da "1 GB"
  süzgecine geçip bir şey daha işaretler; çubukta "2 dosya seçildi" yazar
  ama ekranda biri görünür, ilk dosya görünmeden taşınır. Sayı gösterildiği
  için tam gizli değil, ama §2.2 "önce göster, yalnızca seçilen öğeler"
  ruhuna aykırı: onaylanan şey ekranda yok. Geri al var (zarar sınırlı).
  Test yok (App katmanı). Çözüm yönü: süzgeç değişince seçimi görünür
  olanlarla kesiştirmek ya da `selectedFiles`'ı `visibleFiles` ile
  sınırlamak; alternatif olarak onay penceresinde seçilenleri adıyla
  listelemek. Silme akışına dokunduğu için mahkeme gerekir. (Kaynak:
  `App/Features/LargeFiles/LargeFilesModel.swift:66-70,94,144-146,177-190`,
  `App/Features/LargeFiles/LargeFilesView.swift:51-64,75-85,216-236`)
- Sistem servisleri tek yönetici isteminde `&&` zinciriyle çalışıyor; zincir
  ortada kırılırsa günlük ve kart gerçeği yansıtmıyor. `setLaunchItems`
  `.system` kapsamındaki servislerin betiklerini `{ ...; } && { ...; }`
  diye birleştirip tek `osascript` çağrısı yapıyor. 2. serviste hata olursa
  1. servis zaten değişmiş, 3. ve sonrası hiç denenmemiş oluyor. Ama
  `.failed` dalı hepsini `outcome: .failed` + aynı ileti ile `startup.log`'a
  yazıyor (1. servis için yanlış, 3. için "denenmedi" bilgisi yok) ve
  `problems`'a tek satır ekliyor. Keel AI kartı `changed = items.count -
  problems.count` ile başarılı sayısını tahmin ediyor; bu zincir hatasında
  sayı tesadüfen tutuyor ama hangisinin değiştiği bilinmiyor. Senaryo: iki
  Adobe/Google daemon'u kapatılırken ikincisi "bulunamadı" der; birincisi
  kapalı kalır, günlük "ikisi de failed" yazar, kullanıcı hiçbir şeyin
  değişmediğini sanır. Dokunduğu ilke: §2.7 (kayıt doğruluğu), §2.8 root
  yolu. "Servis kartı problems sayısı" önerisinden farkı: orada kayıt
  yazma hatası ve iptal sayımı, burada zincirin kısmi uygulanması. Karar
  `2026-10-30-kullanici-launchagent-ac-kapat`: `&&` zinciri yalnızca
  güvenlik/yetki açısından anıldı; kısmi başarısızlık ele alınmadı. Test
  yok (App katmanı; betik üretimi `LaunchControl.script` testli ama
  zincir/ayrıştırma değil). Çözüm yönü: her servis için `;` ile ayrı
  çalıştırıp çıkış kodunu `echo "ok <label>"`/`echo "fail <label>"` diye
  yazdırmak, çıktıyı KeelCore'da saf bir fonksiyonla ayrıştırıp servis
  başına sonuç kaydetmek; ayrıştırıcı için Linux'ta test yazılabilir.
  Yönetici yetkisi yoluna dokunduğu için mahkeme gerekir. Mac'te
  doğrulanmadı: `osascript` zincirdeki kısmi çıktıyı ve çıkış kodunu nasıl
  döndürdüğü. (Kaynak: `App/Features/Performance/SystemControl.swift:85-115`,
  `App/Features/Assistant/ActionProposals.swift:168-175`,
  `Packages/KeelCore/Sources/KeelCore/Startup/LaunchControl.swift:53-60`)
- "Sohbet geçmişini bu Mac'te sakla" kapalıyken ve "Geçmişi sil" sonrası da
  Keel AI mesajları sağlayıcı CLI'larının kendi oturum kayıtlarında kalıyor.
  Keel her mesajda `<keel_context>` (dosya/klasör yolları, uygulama adları,
  servis etiketleri) ile birlikte tüm istemi komut satırı argümanı olarak
  Claude Code'a (`-p`, `--session-id`/`--resume`) ve Codex'e (`exec`,
  `resume`) veriyor. İkisi de konuşmayı devam ettirebilmek için oturumu
  yerelde saklıyor. Keel'in yerel ayarı (`persist()`) ve `ChatStore`
  yalnızca Keel'in kendi `Keel/Chats` klasörüne bakıyor; sağlayıcı CLI'ın
  `~/.claude/projects/...` ve `~/.codex/sessions` altındaki kopyası
  (çalışma klasörü `Application Support/Keel/claude`) hiç anılmıyor,
  silinmiyor ve Ayarlar metni bunu söylemiyor. Senaryo: kullanıcı geçmişi
  kapatır ya da siler, ama kişisel dosya adları içeren her mesajın bağlamı
  CLI'ın açık metin kaydında aylarca kalır. Mevcut "dosya adları sağlayıcıya
  gidiyor" önerisinden farkı: orada ne gönderildiği, burada gönderilenin
  yerelde kimin elinde, ne kadar süre kaldığı ve Keel'in "sil" düğmesinin
  buna dokunmadığı. Dokunduğu ilke: Keel AI veri akışı (PLAN "Keel AI"
  bölümü); §2 silme ilkeleri değil. Test yok (App katmanı). Çözüm yönü:
  önce karar: (a) Ayarlar'a "Sağlayıcı CLI'ları da kendi kaydını tutar"
  notu ve yolları göstermek; (b) geçmiş kapalıyken Keel'in kendi
  `previous_conversation` düzenini her mesaja koyup CLI'ı oturumsuz
  çalıştırmak (Claude Code'da `--no-session-persistence`, Codex'te
  `--ephemeral` bayrakları arama sonuçlarında geçiyor; Keel bunları
  kullanmıyor); (c) "Geçmişi sil"de o çalışma klasörüne ait kayıtları da
  silmek. Doğrulanmadı: CLI'ların kayıt yolu ve saklama süresi ile bayrak
  adları yalnızca arama sonucu başlıklarından (belge sayfaları okunamadı,
  izin zaman aşımı); Mac'te `~/.claude/projects` altına gerçekten ne yazıldığı
  denenmedi. Keel AI veri akışına dokunduğu için mahkeme zorunlu.
  (Kaynak: `App/Features/Assistant/AccountSession.swift:63-69,119-134,168-184`,
  `App/Features/Assistant/AssistantModel.swift:331-334`,
  `App/Features/Assistant/CLITool.swift:154-159`,
  `App/Features/Settings/SettingsView.swift:69-76,107-111`)
