# Dava dosyası: Kullanıcı LaunchAgent'larını aç/kapat (PLAN.md Faz 2, satır 144)

## Soru
Satır 144'teki açık madde, kodda zaten çalışan `launchctl` tabanlı başlangıç kontrolünün üstüne bir şey ekleyecek mi, yoksa madde fiilen yapılmış sayılıp kapatılacak mı? Eklenecekse ne?

## Mevcut durum

Ana bulgu: `~/Library/LaunchAgents` için listeleme, aç/kapat, Keel AI kartı ve geri alma kodu mevcut ve PLAN'da `[x]` işaretli maddelerin içinde. Satır 144, ayrı bir özellik olarak yalnızca bu mevcut işin tekrarı gibi duruyor. İddia ettiğim "eksikler" aşağıda ayrı listelendi.

**KeelCore (Linux'ta test edilir)**
- `Packages/KeelCore/Sources/KeelCore/Startup/LaunchItems.swift`
  - `:5-35` `LaunchItem`; `Scope` = `.user` (`~/Library/LaunchAgents`), `.allUsers` (`/Library/LaunchAgents`), `.system` (`/Library/LaunchDaemons`).
  - `:40-53` `LaunchItemScanner.scan` üç klasörü de okur; `:66-84` plist ayrıştırır. `isDisabled = overrides[label] ?? plist["Disabled"] ?? false` (`:81`): launchctl override'ı plist'in `Disabled` anahtarına baskın.
- `Packages/KeelCore/Sources/KeelCore/Startup/LaunchControl.swift`
  - `:9-24` `parseOverrides` (`launchctl print-disabled` çıktısı).
  - `:27-29` kullanıcı kapsamı `gui/<uid>`, sistem `system`.
  - `:32-34` yönetici yalnızca `.system` için gerekli. Yani `.user` ve `.allUsers` şifresiz, kullanıcı olarak çalışır.
  - `:37-49` `refusal`: `com.apple.` önekli olanlar ve beklenmedik karakterli etiketler reddedilir (`isPlainLabel`: ASCII harf/rakam + `._-@+`, en fazla 200).
  - `:54-61` kapatma: `launchctl disable <hedef> && { launchctl bootout <hedef> 2>/dev/null; true; }`. Açma: `launchctl enable <hedef> && { launchctl bootstrap <domain> '<plist yolu>' 2>/dev/null; true; }`. Plist dosyasına dokunulmaz (`:3-5` yorumu).
  - `:65-85` `ShellCommand`: tek tırnak kaçışı, AppleScript yöneticisi.
- Testler: `Packages/KeelCore/Tests/KeelCoreTests/StartupAndFanTests.swift:11-60` (override ayrıştırma, override'ın plist'e baskınlığı, Apple/garip etiket reddi, `.system` ve `.allUsers` için tam script dizesi), `SystemReadersTests.swift:87-` (kullanıcı LaunchAgent okuma). `.user` kapsamı için `script(...)` çıktısını sabitleyen bir test yok (yalnızca `.system` ve `.allUsers` var); mantık aynı olduğu için küçük bir boşluk.

**Uygulama (`App/`, yalnızca Mac'te derlenir)**
- `App/Features/Performance/SystemControl.swift:62-66` `overrides(domain:)`; `:71-94` `setLaunchItems`: reddedilenleri atlar, kullanıcı kapsamlıları `/bin/sh -c` ile tek tek çalıştırır, sistem kapsamlıları tek yönetici isteminde toplar. Hata satırları döner.
- `App/Features/Performance/PerformanceModel.swift:81-90` `refreshLaunchItems`; `:102-110` `setLaunchItems` (işlem sonrası yeniden tarar); `:37-38` `activeLaunchItems` (RunAtLoad/KeepAlive ve kapalı olmayan).
- `App/Features/Optimization/OptimizationView.swift:171-281` "Arka plan servisleri" kartı: her satırda açma/kapama anahtarı (`:250-265`), kapsam etiketi (`:267-273`), Apple servisleri için "macOS" rozeti, sistem servislerinde kilit simgesi; `:231` açıklama metni.
- Keel AI: `App/Features/Assistant/ActionProposals.swift:93-107` (`disable_startup`/`enable_startup`, Apple servislerini reddeder, zaten o durumda olanı atlar), `:170-176` uygula, `:218-223` geri al. Kullanıcı kartı onaylamadan hiçbir şey değişmez (`:164`).
- `App/Features/Assistant/KeelTools.swift:298-305` AI'ya özet: etiket, kapsam, başlama türü.

**PLAN ile çakışma**
- Satır 129-131 `[x]` "Başlangıç kontrolü: `launchctl disable/enable`" (Apple servisleri hariç, sistem servisleri yönetici şifresiyle).
- Satır 140-141 `[x]` Optimizasyon bölümü: "arka plan servisleri tek yerde".
- Satır 142-143 `[x]` Keel AI eylem kartları: "servis/giriş öğesi kapatma".
- Satır 56 (§3 tablosu) bu işi "Kullanıcı LaunchAgent'larını aç/kapat + Login Items için Sistem Ayarları'na derin link" diye tarif eder. Derin link da var: `OptimizationView.swift:237` `openLoginItemsSettings`. Bu maddeler Ekim 2026 başında (`cde407e`, `c47bf12`) birleşti; satır 144 sonradan kalmış gibi duruyor (git geçmişinden tahmin, doğrulanmadı).

**Koddan tespit edilen, gerçekten eksik olanlar**
1. İşlem günlüğü yok: `ActionLog` (`Actions/ActionLog.swift`) yalnızca silme (`Removal`) için ve `App/` içinde hiç kullanılmıyor (grep boş). Başlangıç servisi aç/kapat hiçbir yere kaydedilmiyor. PLAN §2.7 "Her işlem kaydedilir" der; bu aç/kapat işlemi için karşılanmıyor. (Kuralın "taşındı" odaklı olduğu, aç/kapatı kapsayıp kapsamadığı yoruma açık.)
2. `LaunchControl`/`SystemControl.setLaunchItems` mantığının bir kısmı `App/` içinde (komut çalıştırma, hata ayrıştırma), yani Linux'ta test edilemiyor. Komut dizesi üretimi ise KeelCore'da ve testli.
3. Hata mesajı ham: `launchctl disable` başarısız olursa mesaj `clean()` ile kabuk çıktısından gelir (`SystemControl.swift:52-58`); kullanıcıya anlamlı çeviri yok.
4. `.user` kapsamı için `bootout`/`bootstrap` ve `enable`/`disable` davranışının gerçek Mac'te (özellikle Ventura+ Background Items ile) doğrulanması: kodda yorum var ama CI'da çalışmaz. Repoda Mac'te yapılmış bir doğrulama kaydı bulamadım.
5. SMAppService ile kayıtlı (uygulamanın kendi ana bilgisayar/Login Item) arka plan öğeleri `~/Library/LaunchAgents` içinde olmadığı için taranmıyor ve `launchctl disable` bunları Sistem Ayarları'ndaki anahtarla senkron tutmayabilir (doğrulanmadı, aşağıya bkz.).
6. Yalnızca etiket/dosya adına göre listeleme: aynı etiketle iki plist (örn. hem `~/Library` hem `/Library/LaunchAgents`) varsa `id` yol olduğu için ayrı satır olur ama override etikete göre tek anahtardır (`LaunchItems.swift:81`). Kod bu durumu ele almıyor ve test de yok (gözlem, gerçek etkisi doğrulanmadı).

## İlgili kurallar

`docs/PLAN.md` §2:
- 1. Hiçbir şey kalıcı silinmez: bu iş silme yapmaz; plist dosyası değişmez. Geçerli değil, ama "geri alınabilirlik" ruhuna uyar (anahtar tersine çevrilir).
- 2. Önce göster, sonra onayla: kartta anahtar görünür; Keel AI kartı onay ister (`ActionProposals.swift:164`). Arayüzde anahtar tek tıkla anında uygular (onay penceresi yok).
- 3. İzin listesi: `SafetyPolicy` yalnızca dosya silme/taşıma içindir; launchctl yolu `SafetyPolicy`'den geçmiyor. Koruma `LaunchControl.refusal` ile (yasak listesi: `com.apple.` + karakter süzgeci). Bu, "allowlist, yasak listesi değil" ilkesine biçimsel olarak ters; ilke dosya yolları için yazılmış, yoruma açık.
- 7. Her işlem kaydedilir: yukarıdaki eksik 1.
- 8. Root yetkisi MVP'de yok / Faz 3: `.system` kapsamı yönetici şifresiyle zaten yapılıyor (`osascript ... with administrator privileges`), bu madde `.user` ile sınırlıysa root gerektirmez.
- 6. Çalışan uygulamanın önbelleğine dokunulmaz: kapatma `bootout` ile çalışan ajanı sonlandırır; ilke önbellek içindir, doğrudan ilgili değil. Kullanıcıya "kapatınca çalışan süreç durur" uyarısı arayüzde yok (`:231` metni "Mac yeniden başlasa da kapalı kalır" der, durdurmadan söz etmez).

`docs/PLAN.md` §3 satır 56: bu işi tarif eden orijinal öneri. §5 satır 129-131, 140-143: ilgili `[x]` maddeler. §5 satır 144: açık madde.

`CLAUDE.md`: yönetici yetkisine ve silmeye dokunan her değişiklik için mahkeme zorunlu. Bu iş silme değil; yönetici yetkisi `.system` kapsamda zaten kullanılıyor. Ek kural yok.

## Dış araştırma

Arama aracı yalnızca bağlantı listesi döndürdü, sayfaları açıp doğrulamadım. Bu yüzden aşağıdakiler **doğrulanmadı**:
- `launchctl disable/enable <domain>/<label>` ve `bootout`/`bootstrap` kullanımı üzerine topluluk notları: [b0gdanw gist](https://gist.github.com/b0gdanw/c99e5b2eefad19932554a713384dcc70), [mole.fit rehberi](https://mole.fit/blog/how-to-disable-startup-programs-on-mac). Üçüncü taraf, resmî değil.
- macOS 13+ Background Items Management (Sistem Ayarları > Genel > Giriş Öğeleri ve Uzantılar) ile `launchctl disable` override veritabanının ilişkisi: kodda `LaunchControl.swift:3-5` yorumu "System Settings'in anahtarlarıyla aynı yol" diyor; Apple belgesinde bunu doğrulayan bir kaynak bulmadım. **Doğrulanmadı.**
- `launchctl enable`'ın plist içindeki `Disabled=true` anahtarını geçersiz kılıp kılmadığı: kodun varsayımı (`LaunchItems.swift:81`, test `overrideWinsOverPlist`) bu yönde; Apple dokümanından doğrulanmadı. launchctl man sayfası (`man launchctl`) Mac'te okunmalı.
- Rakipler: CleanMyMac "Optimization > Login Items / Launch Agents" bölümünde ajanları listeler ve kapatma/kaldırma sunar; Stats bunu yapmaz; AppCleaner yalnızca kaldırma sırasında ilgili plist'leri gösterir. Bunlar eğitim bilgisidir, bu oturumda kaynakla doğrulanmadı.

## Seçenekler

**A. Maddeyi kapat, ek iş yapma (ertele/yapılmış say).**
- Ne yapılır: PLAN satır 144 `[x]` yapılır ya da satır silinir; yanına "satır 129-131 ve 140-143 ile karşılandı" notu düşülür.
- Dosyalar: yalnızca `docs/PLAN.md`.
- Büyüklük: çok küçük. Risk: eksik 1 (günlük) ve eksik 4 (Mac doğrulaması) açık kalır; bunlar zaten başka maddelerin konusu.

**B. Yalnızca eksik 1'i kapat: aç/kapat işlemlerini `ActionLog`'a yaz.**
- Ne yapılır: `ActionLog`'a aç/kapat için bir giriş türü (yeni `Removal` değeri ya da ayrı kayıt biçimi) eklenir; `SystemControl.setLaunchItems` (veya `PerformanceModel.setLaunchItems`) sonuçları yazar. Gerekirse `ActionLog.Entry.Outcome`'a "disabled/enabled" eklenir.
- Dosyalar: `Packages/KeelCore/Sources/KeelCore/Actions/ActionLog.swift`, `.../Startup/LaunchControl.swift` (kayıt üretimi, testli), `App/Features/Performance/PerformanceModel.swift` veya `SystemControl.swift`, `StartupAndFanTests.swift` / `ActionLog` testleri.
- Büyüklük: küçük-orta (yaklaşık 100-150 satır + test). `ActionLog` biçimini değiştirmek mevcut `actions.log` okuyucularını (geri al ekranı vb.) etkileyebilir; etkilenen yerler tam taranmadı.

**C. Kapsamı daralt: yalnızca `~/Library/LaunchAgents` için ayrı, sade "Kullanıcı ajanları" görünümü.**
- Ne yapılır: `OptimizationView`'a ya da ayrı kartta `.user` kapsamlı öğeler "Senin hesabın" altında öne çıkarılır; çalışan süreç uyarısı, açıklayıcı hata metinleri, `.user` script testi eklenir.
- Dosyalar: `App/Features/Optimization/OptimizationView.swift`, `StartupAndFanTests.swift`.
- Büyüklük: küçük. Değer: mevcut kartın içinde zaten ayrı satırlar var; kazanım çoğunlukla sunum.

**D. Hiç yapmamak.** Satır 144'ü olduğu gibi açık bırakmak. Sonuç: `/gelistir` bu maddeyi tekrar tekrar seçer ve mahkeme aynı konuyu yeniden görür; gereksiz iş döngüsü riski.

**E. Kapsamı genişlet: SMAppService / Background Items (BTM) öğelerini de yönetmek.**
- Ne yapılır: Sistem Ayarları'ndaki arka plan öğelerini programla okuma/değiştirme. Public API bunu başka uygulamalar için sunmuyor görünüyor (PLAN §3 satır 56 aynı noktayı söylüyor); özel `sfltool`/BTM veritabanı yolu güvenli değil.
- Dosyalar: belirsiz. Büyüklük: büyük, fizibilite doğrulanmadı. Önerilmeyen yön olarak not edildi (öneri değil, kapsam sınırı).

## Bilinmeyenler
1. Sahip satır 144'ten ne bekliyor: yeni bir şey mi, yoksa unutulmuş bir kalan satır mı? (Mevcut davranış kodda var; fark söylenmedi.)
2. Gerçek bir Mac'te (hangi macOS sürümü?) `.user` kapsamlı bir ajan için kapat → yeniden başlat → açık/kapalı durumu → Sistem Ayarları'ndaki görünüm doğrulandı mı? Repoda kayıt yok.
3. `launchctl enable` plist `Disabled=true`'yu gerçekten geçersiz kılıyor mu (kod buna güveniyor)?
4. §2.7 "her işlem kaydedilir" aç/kapat işlemlerini de kapsıyor mu, yoksa yalnızca dosya taşıma/silmeyi mi? (Karar B'yi etkiler.)
5. `SafetyPolicy`'nin dışında kalan, yasak-liste tabanlı `LaunchControl.refusal` §2.3'e uyum için sorun mu? İlkenin kapsamı yoruma açık.
6. Arayüzde anahtarın tek tıkla onaysız uygulanması §2.2 "onayla" ile uyumlu mu? (Keel AI kartı onay istiyor, doğrudan anahtar istemiyor.)
7. Aynı etikete sahip birden fazla plist (örn. kullanıcı ve `/Library/LaunchAgents`) gerçekte nasıl davranıyor?
8. Eski kararların tamamı özetlendi: bu konu daha önce yargılanmadı. Emsal olarak: `origin/claude/mahkeme-2026-10-28` sahipsiz artıklar kararı ve `origin/claude/mahkeme-2026-10-29` uygulama güncelleyici kararı "yalnızca salt okunur Aşama 0, ağ/silme yüzeyi reddedildi, öncelik sorusu insana" kalıbıyla kapandı. Her ikisi de GUNDEM'de satır 144'ü (LaunchAgent aç/kapat) öncelik sorusu listesine ekledi ve "Cevap:" alanları hâlâ boş; yani insan sahibin Faz 2 öncelik cevabı hâlâ yok (`git show origin/claude/mahkeme-2026-10-29:docs/mahkeme/GUNDEM.md`). Bu dava aynı ortak soruya bağlı olabilir. Ayrıca sahipsiz artıklar davası, `AppLeftovers.swift:58`'deki `~/Library/LaunchAgents` konumunu (silme yüzeyi) ayrıca ele aldı; bu dava plist silmeyi kapsamaz.
9. `swift test` bu Linux ortamında çalıştırılamadı (`swift` kurulu değil); testlerin güncel durumu doğrulanmadı.
