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
- Güvenlik politikası bir `.app` paketinin kendisini de reddediyor; bu yüzden Çöp
  Kutusu'ndaki ve Downloads'taki uygulamalar Temizlik listesinde hiç görünmüyor ve
  Keel'den boşaltılamıyor. `SafetyPolicy.isInsideAppBundle` yolun bileşenlerini
  üst klasörden başlayarak gezip bileşenin kendisini de katıyor. Bir `Foo.app`
  içinde `Contents/Info.plist` varsa `evaluate` `.insideAppBundle` döner. Tarayıcı
  bu öğeyi `skipped` listesine koyuyor, boyuta da katmıyor. Arayüz ise `skipped`
  içinden yalnızca `.appRunning` olanları gösteriyor (`skipNote`). Rapor satırı
  "güvenlik kuralı izin vermedi" diyor ama hangi öğe olduğunu söylemiyor.
  Senaryo: kullanıcı Keel'in Uygulamalar ekranıyla 4 GB'lık bir uygulamayı Çöp'e
  atıyor, sonra Temizlik'te "Çöp Kutusu" kategorisini seçip boşaltıyor. Uygulama
  Çöp'te kalıyor, kategori toplamı onu saymıyor ve kullanıcı bunu fark edemiyor.
  Aynı şey Downloads'taki eski `.app`/`.pkg` kurulum paketleri için de geçerli
  ("Eski indirmeler" listesi eksik kalıyor). PLAN §2.4 yalnızca paketlerin İÇİNİ
  korur; paketin kendisinin reddedilmesi niyetli mi, belli değil. Dokunduğu
  ilke: §2.2 "önce göster" (gösterilen toplam ve liste eksik). Güvenlik açısından
  zararsız, yani fazla koruyucu. Test durumu: `SafetyPolicyTests` bu davranışı
  Downloads içinde `.insideAppBundle` olarak sabitliyor, Çöp Kutusu kategorisiyle
  hiçbir test yok. Çözüm yönü: önce bilinçli karar verilir. Paketin kendisi Çöp
  Kutusu'nda kalıcı silinebilsin diye `.deletePermanently` + `isInsideTrash`
  durumunda yalnızca paket İÇİ reddedilebilir; ya da `.denied` atlananlar
  arayüzde "N öğe güvenlik kuralıyla atlandı: Foo.app" diye adıyla listelenir.
  Hangisi seçilirse seçilsin Çöp Kutusu'nda `.app` olan bir test yazılır.
  Mac'te doğrulanmadı: gerçek Çöp'te bir uygulamanın bu yolu izlemesi.
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/Safety/SafetyPolicy.swift:75-77,131-141`,
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CleanupScanner.swift:264-267`,
  `App/Features/Cleanup/CleanupView.swift:246-253,431`,
  `Packages/KeelCore/Sources/KeelCore/Cleanup/CleanupCatalog.swift:148-158`,
  `Packages/KeelCore/Tests/KeelCoreTests/SafetyPolicyTests.swift:130-135`)
- Keel AI "Girişte açılmasın" kartı ve Optimizasyon'daki "Kaldır" düğmesi, yolu
  bilinmeyen (`missing value`) giriş öğeleri için de geri alınabilir diyor, ama
  bunlar geri eklenemiyor. `LoginItemScript.add` yol boşsa nil döner, yani
  eklenemez; `PerformanceModel.restoreLoginItem` bu durumda sessizce çıkıyor.
  Kart ise öğeyi seçerken yolu hiç denetlemiyor, alt notu "Geri alınabilir." ve
  `apply` sonucu `canUndo: true`. Senaryo: model yolu olmayan bir giriş öğesini
  ("Ghost") öneriyor, kullanıcı onaylıyor, öğe System Events'ten silinir. Sonra
  "Geri al" basılınca "Geri eklenemedi" çıkar; öğe kalıcı kaybolmuştur. Optimizasyon
  ekranı "Geri ekle" düğmesini saklıyor ama "Kaldır" öncesi uyarı yok. Ayrıca
  `list` betiği `hidden` özelliğini okumuyor, `add` her zaman `hidden:false` yazıyor:
  gizli açılan bir öğe geri alınca pencereyle açılır, "eski hâlinde" sözü tutmaz.
  Dokunduğu ilke: §2.2 (onaydan önce verilen bilgi yanlış), geri alınabilirlik
  güvencesi. Test durumu: `loginItems` testi `add(...) == nil` ve `remove` metnini
  deniyor, kart/`canUndo` mantığı App'te olduğu için testsiz; `hidden` hiç
  denenmiyor. Çözüm yönü: `resolve` yolu boş öğeleri `refused` ("geri eklenemez")
  yapsın ya da kartta açıkça uyarsın; `canUndo` yalnızca yolu olanlar için true
  olsun; `list` betiği `hidden`'ı da okuyup `LoginItem`'a eklesin (parse testiyle).
  Mac'te doğrulanmadı: System Events'in `hidden` özelliğini ve `missing value`
  yolunu gerçekte nasıl döndürdüğü.
  (Kaynak: `Packages/KeelCore/Sources/KeelCore/Startup/LoginItems.swift:20-28,47-50`,
  `App/Features/Performance/PerformanceModel.swift:136-152`,
  `App/Features/Assistant/ActionProposals.swift:62,119-122,178-184,224-229`,
  `App/Features/Optimization/OptimizationView.swift:329-340`,
  `Packages/KeelCore/Tests/KeelCoreTests/StartupAndFanTests.swift:101-113`)
- "Geçmişi sil" yalnızca okunabilen sohbetleri siliyor; çözülemeyen sohbet
  dosyaları diskte sonsuza kadar kalıyor. `ChatStore.list()` `try?` ile
  çözemediği dosyayı sessizce atlıyor. `deleteAllChats` ve `save` içindeki
  50 sohbet sınırı (`dropFirst(limit)`) yalnızca bu listeye bakıyor. Ayarlar
  "Sohbet geçmişi sayısı"nı da buradan gösteriyor. Senaryo: `SavedChat`'e ileride
  zorunlu bir alan eklenir ya da kullanıcı eski sürüme döner; eski dosyalar
  çözülemez, listede ve sayaçta görünmez, "Tüm sohbet geçmişi silinsin mi?"
  onayından sonra bile `~/Library/Application Support/Keel/Chats` altında kalır
  (içinde kullanıcının yazdıkları ve modelin dosya adı içeren yanıtları olabilir).
  Önem düşük: bugün tetikleyen bir hata yok, şema değişikliğinde ortaya çıkar.
  Dokunduğu ilke: §2.7 ruhu / Keel AI veri akışında kullanıcıya verilen silme
  güvencesi; §2.1-2.5 silme ilkeleri değil (Keel'in kendi verisi). Test durumu:
  `ChatStore` App katmanında, test yok. Çözüm yönü: `deleteAllChats` klasördeki
  tüm `*.json` dosyalarını silsin (listeden bağımsız); sınır budaması da çözülemeyen
  dosyaları yaşa göre temizlesin; `ChatStore`'u KeelCore'a taşıyıp çözülemeyen
  dosyalı bir test yazmak mümkün. Mac'te doğrulanmadı ama mantık platformdan
  bağımsız.
  (Kaynak: `App/Features/Assistant/ChatStore.swift:47-52,55-60,62-64`,
  `App/Features/Assistant/AssistantModel.swift:374-378`,
  `App/Features/Settings/SettingsView.swift:70-76,107`)
