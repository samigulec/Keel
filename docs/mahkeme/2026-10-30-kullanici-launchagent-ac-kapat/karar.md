# Karar: Kullanıcı LaunchAgent'larını aç/kapat (PLAN.md Faz 2, satır 144)

**KARAR:** DEĞİŞTİRİLEREK KABUL
**İNSAN ONAYI GEREKİR:** HAYIR. Kabul edilen kapsam, kural 4'teki tetikleyicilerin hiçbirine girmiyor. Yeni yetki yok ve `.system` yönetici yolu ile istem metni değişmiyor. Silme yok, `SafetyPolicy`'e dokunulmuyor, cihaz dışına veri çıkmıyor, yeni bağımlılık yok. Her adım geri alınabilir. İnsana bağlı olan iki şey var ve ikisi de bu PR'ı bekletmiyor, GUNDEM'e yazılıyor. Birincisi Mac'te elle doğrulama. İkincisi mevcut yasak-liste korumasının ve `.system` root yolunun §2.3/§2.8 ile uzlaştırılması. Satır 144 bu doğrulama yapılmadan `[x]` olmaz.

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik | KOŞULLU | 3 | HAYIR |
| macOS sistem | KOŞULLU | 3 | HAYIR |
| Kullanıcı | KOŞULLU | 3 | HAYIR |
| Swift mühendisi | KOŞULLU | 3 | HAYIR |
| Ürün | KOŞULLU | 3 | HAYIR |

5 KOŞULLU, 0 veto. Koşulların ortak çekirdeği şu: işlem kaydı ayrı biçimde ve KeelCore'da olacak, `.user` testi ile çift-etiket testi yazılacak, "süreç durdurulur" uyarısı eklenecek, doğrulanmamış vaatler kaldırılacak, Mac doğrulaması yapılmadan `[x]` konmayacak. Bu çekirdek plana aynen alındı. Aşağıda kabul etmediğim ya da daralttığım üç koşulun gerekçesi var.

## Gerekçe

**Kodda doğruladıklarım.**
- `LaunchControl.swift:37-41`: `refusal` gerçekten yalnızca `com.apple.` önekine ve bir karakter süzgecine bakıyor.
- `:54-61`: kapatma komutu `disable && bootout` biçiminde, plist'e dokunulmuyor.
- `:3-5`: yorumda "the way System Settings' switches do" deniyor. Bu, doğrulanmamış bir iddia.
- `SystemControl.swift:71-94`: `setLaunchItems` hiçbir şeyi kayda geçirmiyor.
- `OptimizationView.swift:231`: metin "Mac yeniden başlasa da kapalı kalır" diyor, süreç durdurmaktan hiç söz etmiyor.
- PLAN satır 129-131 ve 140-143 `[x]`, satır 144 `[ ]`.

**Dava dosyasında bir olgu hatası var.** Dosyaya göre "`ActionLog` `App/` içinde hiç kullanılmıyor". Bu yanlış. `ApplicationsModel.swift:243` ve `Undo.swift:8` `log: .standard()` geçiriyor, `CleanupExecutor` ve `LargeFileRemover` da `.standard()` ile kayıt yazıyor. `SettingsView.swift:78-90`'da ise "Kayıt dosyasını Finder'da göster" düğmesi var. Yani silme kaydı çalışıyor ve kullanıcı ona ulaşabiliyor. Asıl bulgu yine de geçerli, çünkü servis aç/kapat kaydı yok. Ama bu düzeltme planı etkiliyor: yeni kaydı bu var olan Ayarlar yüzeyi üzerinden görünür kılmak ucuz.

**Savcının en güçlü argümanı.** "Seçenek A (yalnızca `[x]`) iki açığı örter: §2.7 kayıt boşluğunu ve doğrulanmamış macOS varsayımları üzerine kurulu 'bitti' iddiasını." Kabul edildi. Madde düz kapatılmayacak. Kayıt eklenecek, doğrulanmamış vaatler metinden ve kod yorumundan çıkarılacak, satır 144 Mac doğrulamasına kadar `[x]` olmayacak.

Savcının ikinci güçlü noktası yasak-liste korumasıydı: antivirüs, VPN, MDM ya da Keel'in kendi ajanı kapatılabiliyor. Bu argüman haklı, ama bu davada çözülmesini reddettim. Allowlist'e geçmek ya da "koruma ajanı" listesi tutmak yeni bir davranış ve yeni bir politika. Hangi etiketin "koruma" sayılacağı da ayrı bir tasarım sorusu. Bunu bu küçük kapanış işine sıkıştırmak planı test edilebilir olmaktan çıkarır (kural 5). Konu sahibe soru olarak gidiyor, ayrı mahkemenin konusu. Kullanıcı jürisinin "koruma ajanları için ek uyarı" koşulu da aynı gerekçeyle bu davada karşılanmıyor. Çoğunluğa aykırı bir karar değil, çünkü güvenlik jürisi de bunu açıkça sahibe bıraktı.

**Avukatın en güçlü argümanı.** Kayıt, `ActionLog.Entry`'yi (`Removal`/`path`/`bytes`) genişletmek yerine ayrı bir kayıt türü ve ayrı bir dosyayla tutulsun. Böylece silme ve geri alma yolu hiç riske girmez. Kabul edildi. Beş jürinin beşi de bunu destekliyor. Güvenlik jürisi de geri alma yolunun en hassas yer olduğunu söylüyor.

Avukatın "anahtar tek tıkla kalsın, onay penceresi eklenmesin" önerisini de kabul ettim. İşlem görünür ve tek tıkla tersine çevrilebiliyor. Çalışan sürecin durması gibi gerçek yan etki uyarı metniyle açıkça söylenecek. Kullanıcı jürisi onay adımı istedi. Ama bu tek bir jürinin koşulu, diğer dört jüri istemedi, güvenlik jürisi de onayı gerekli bulmadı.

**Daralttığım ya da çoğunluktan ayrıldığım koşullar.**
1. *Ürün jürisi: "Sahip satır 144'ün cevabını vermeden kod yazılmaz."* Kabul etmedim. Bu iş yeni bir özellik değil. Var olan bir yolun §2.7 açığını kapatıyor ve yanıltıcı metni düzeltiyor, yani risk azaltıyor. Kural 4'teki tetikleyicilerin hiçbiri yok. Önceki üç davanın öncelik sorusu, büyük ve yeni işler (ağ, silme, ölçüm aracı) içindi. Bu iş o soruya bağlanırsa satır 144 `/gelistir` döngüsünde dönmeye devam eder (dosyada Seçenek D). Diğer dört jüri bu koşulu koymadı.
2. *Ürün ve kullanıcı jürisi: kayıt arayüzde "son değişiklikler" listesi olarak görünsün.* Daralttım. Yeni bir liste ekranı kapsamı büyütür. Bunun yerine var olan Ayarlar > "Gizlilik ve kayıtlar" bölümü güncellenecek: metin servis değişikliklerinden de söz edecek, düğme iki kaydın bulunduğu klasörü gösterecek. Böylece kayıt "gizli dosya" olmaktan çıkıyor. Arayüz içi liste sahibe soru olarak gidiyor.
3. *Mühendis jürisi: kayıt yazıcısı actor olsun.* Daralttım. Var olan `ActionLog` `Sendable` bir struct ve eşzamanlı ekleme yapmıyor. Servis değişikliğinin tek giriş noktası `@MainActor` olan `PerformanceModel.setLaunchItems`. Buradan `SystemControl.setLaunchItems`'a gidiliyor ve döngü sıralı çalışıyor. Aynı deseni izlemek tutarlılık açısından daha iyi. Uygulayıcı bu tek giriş noktası dışında bir çağrı yolu bulursa (ör. Keel AI kartının model dışından doğrudan çağırması), struct yerine actor kullanmak zorunlu olur. Sıralı ardışık eklemede satır kaybı olmadığını gösteren test her durumda yazılacak.

**Pazarlıksız ilkeler.**
- §2.7 için yorumum güvenli yönde: aç/kapat da kayda girer. Sahibe yalnızca teyit sorusu gidiyor.
- §2.3 ve §2.8 açısından bu iş hiçbir şeyi gevşetmiyor ya da genişletmiyor. Var olan uyumsuzluk (yasak liste ve `osascript` ile root; aynı şey `[x]` işaretli fan yardımcısı için de geçerli) bu davada kayda geçiyor ve sahibe gidiyor. Kapanış notu "güvenlik tamam" demeyecek.

## Uygulama planı

1. **Kayıt türü ve yazıcı (KeelCore).**
   - Dosyalar: yeni `Packages/KeelCore/Sources/KeelCore/Startup/LaunchActionLog.swift`.
   - `LaunchActionLog: Sendable` olacak; içinde `fileURL`, `standard(home:)` (`~/Library/Logs/Keel/startup.log`) ve `append(_:)` bulunacak. `append` `ActionLog.append` ile aynı JSON-satır desenini izler. `ActionLog.swift`'e dokunulmaz, ortak yardımcı da çıkarılmaz.
   - `Entry: Codable, Equatable, Sendable` alanları: `date`, `label`, `scope`, `action` (`enable`/`disable`), `outcome` (`ok`/`failed`/`refused`/`cancelled`), `detail: String?`. `detail` init sırasında en fazla 200 karaktere kısaltılır.
   - Plist yolu, plist içeriği ve tam komut dizesi alan olarak yer almaz.
   - Saf bir kurucu yazılır: `LaunchActionLog.Entry.refused(item:enabled:date:)` ya da eşdeğeri. Gerekçe metnini `LaunchControl.refusal`'dan alır.
   - Test: yeni `Packages/KeelCore/Tests/KeelCoreTests/LaunchActionLogTests.swift`. İçeriği:
     - geçici dizine yazma ve geri okuma (dizin yoksa oluşturulur);
     - 50 sıralı eklemenin sonunda tam 50 geçerli satırın doğru sırada olması;
     - `detail` kısaltması;
     - `com.apple.` ve geçersiz karakterli etiket için `refused` kaydı.

2. **Kod yorumu düzeltmesi (KeelCore, yalnızca yorum).**
   - Dosyalar: `Startup/LaunchControl.swift:3-5`.
   - "the way System Settings' switches do" ifadesi kaldırılır. Yerine yalnızca yapılan iş yazılır: `launchctl disable/enable`, plist'e dokunulmaz. Mantık satırı değişmez.
   - Test: yok, davranış değişmiyor.

3. **Eksik karakterizasyon testleri.**
   - Dosyalar: `Packages/KeelCore/Tests/KeelCoreTests/StartupAndFanTests.swift`.
   - `.user` kapsamı için `script(enable: true/false, ...)` çıktısının tam dizesi sabitlenir.
   - `.allUsers` için `domain == "gui/<uid>"` ve `needsAdministrator == false` sabitlenir ("yalnızca bu oturum"). Var olan test bunu zaten tam karşılıyorsa yeni test yazılmaz, PR'da belirtilir.
   - Aynı etiketle `~/Library/LaunchAgents` ve `/Library/LaunchAgents` altında iki plist durumu sabitlenir: iki ayrı satır çıkar, ikisinin `isDisabled` değeri tek override'dan gelir.
   - Tarayıcı dizin enjekte etmeye izin vermiyorsa `LaunchItems.swift:66-84`'teki ayrıştırma işlevi üzerinden test edilir. Davranış değiştirilmez.

4. **Kaydın bağlanması (App).**
   - Dosyalar: `App/Features/Performance/SystemControl.swift` (`setLaunchItems`).
   - Her öğe için bir kayıt yazılır:
     - reddedilen öğe `refused`;
     - kullanıcı kapsamında `.done` sonucu `ok`, `.failed` sonucu `failed` (detail: mesaj);
     - sistem toplu isteminde her öğe aynı sonucu alır (`ok`/`failed`/`cancelled`).
   - Kayıt yazılamazsa işlem iptal edilmez. `problems` listesine tek bir "İşlem kaydı yazılamadı: …" satırı eklenir, yani hata sessizce yutulmaz.
   - Yönetici script'i, istem metni ve `refusal` kontrolü değişmez. Diff bunu göstermelidir.
   - Test: mantık 1. adımda testli. Bu adım yalnızca çağrıyı bağlıyor.

5. **Arayüz metni.**
   - Dosyalar: `App/Features/Optimization/OptimizationView.swift:231`.
   - Yeni metin üç noktayı söyler:
     - kapatınca çalışan servis hemen durdurulur;
     - Keel servisi açılışta başlamaması için işaretler, anahtarı açınca geri gelir;
     - "Tüm kullanıcılar" servislerinde değişiklik yalnızca senin oturumunu etkiler; kilitli olanlar yönetici şifresi ister.
   - "Mac yeniden başlasa da kapalı kalır" ya da "Sistem Ayarları'yla aynı" gibi kesin vaatler yer almaz.

6. **Kaydın görünürlüğü.**
   - Dosyalar: `App/Features/Settings/SettingsView.swift:78-90`.
   - Açıklama metnine "açıp kapattığı arka plan servisleri" eklenir.
   - Düğme `~/Library/Logs/Keel/` klasörünü gösterir. Bu klasörde `actions.log` ve `startup.log` bulunur. Klasör yoksa var olan geri dönüş davranışı korunur.

7. **PLAN ve gündem.**
   - Dosyalar: `docs/PLAN.md`, `docs/mahkeme/GUNDEM.md`.
   - Satır 144 kutucuksuz bir nota çevrilir, böylece `/gelistir` bu maddeyi yeniden seçmez ve madde yalan yere `[x]` da olmaz. Not şunları söyler:
     - kod tarafı satır 129-131 ve 140-143 ile karşılandı;
     - servis aç/kapat `startup.log`'a, silme ve geri alma `actions.log`'a yazılıyor;
     - Mac'te doğrulama bekliyor (insan işi); doğrulanınca `[x]` yapılır;
     - yasak-liste koruması ve `.system` root yolu §2.3/§2.8 ile uzlaştırılmadı, sahip kararına bırakıldı.
   - §2 metnine dokunulmaz.
   - GUNDEM'e aşağıdaki sorular eklenir.

## Sahibe sorular (GUNDEM'e; bu PR'ı bekletmez)
1. **Mac doğrulaması.** En az bir macOS 13+ cihazda şu senaryoyu çalıştırmayı kabul ediyor musun?
   - Bir `.user` ajanını Keel'den kapat, `launchctl print gui/<uid>/<label>` ile durduğunu gör, Mac'i yeniden başlat, çalışmadığını gör.
   - Sistem Ayarları > Giriş Öğeleri ve Uzantılar görünümüyle karşılaştır.
   - Ajanı aç ve aynı kontrolleri tekrarla.
   - Plist'inde `Disabled=true` olan bir ajanda `enable` sonrası yüklenip yüklenmediğini dene.
   - Aynı etiketli çift plist varsa davranışını not et.
   - Hangi makine ve macOS sürümünde? Sonuç PLAN'a yazılınca satır 144 `[x]` olur. Uyuşmazlık çıkarsa arayüz metni bunu açıkça anlatacak şekilde ayrıca düzeltilir.
2. **§2.7.** "Her işlem kaydedilir" ilkesi servis aç/kapatı da kapsıyor mu? Bu kararda "evet" diye yorumlandı.
3. **§2.3 / §2.8.** Servis korumasının yasak listesiyle yapılması (`com.apple.` ve karakter süzgeci) kabul edilebilir mi? Yoksa güvenlik, VPN, yedekleme, MDM ajanları ve Keel'in kendi etiketi için ek uyarı ya da allowlist mi istiyorsun (ayrı mahkeme)? `.system` servislerinin ve fan yardımcısının `osascript` ile root çalıştırması "Root yetkisi MVP'de yok" ilkesiyle nasıl uzlaşsın?
4. **Görünürlük.** Ayarlar'daki "kayıt klasörünü göster" düğmesi yeterli mi, yoksa uygulama içinde "son değişiklikler" listesi mi istiyorsun (ayrı iş)?
5. **Kapsam.** Satır 144'ten mevcut işin ötesinde bir şey bekliyor muydun? Cevap "hayır" ise doğrulamadan sonra madde kapanır.

## Kabul kriterleri
- [ ] `swift test --package-path Packages/KeelCore` geçiyor. Çıktı CI'dan ya da Mac'ten PR'a konur, bu ortamda swift yok, "geçti" iddiası kanıtsız yapılmaz.
- [ ] Yeni `LaunchActionLogTests` var: geçici dizine yazma ve okuma, 50 sıralı eklemede kayıpsız ve sıralı satırlar, `detail` ≤ 200 karakter, Apple ve geçersiz etiket için `refused`.
- [ ] `StartupAndFanTests`'te `.user` script dizesi (açma ve kapatma), `.allUsers` oturum alanı ve çift-etiket karakterizasyon testleri var.
- [ ] `git diff` `ActionLog.swift`, `CleanupExecutor.swift`, `TrashRestorer.swift`, `SafetyPolicy` ve `LaunchControl.refusal`/`script`/`needsAdministrator` gövdelerinde değişiklik göstermiyor. `LaunchControl.swift`'te yalnızca 3-5. satırlardaki yorum değişiyor.
- [ ] `SystemControl.setLaunchItems` içindeki yönetici script'i ve istem metni değişmemiş.
- [ ] Kayıt girdisinde plist yolu, plist içeriği ya da tam komut dizesi yok.
- [ ] `grep -rn "startup.log\|LaunchActionLog" App/Features/Assistant` boş, yani kayıt Keel AI araçlarına ya da herhangi bir ağ yoluna verilmiyor. Grep çıktısı PR'da.
- [ ] Kayıt yazma hatası işlemi iptal etmiyor ve kullanıcıya tek satır sorun olarak dönüyor.
- [ ] `OptimizationView` metni süreç durdurmayı ve "Tüm kullanıcılar"ın yalnızca bu oturumu etkilediğini söylüyor. "Yeniden başlasa da kapalı kalır" ya da "Sistem Ayarları'yla aynı" vaadi yok.
- [ ] Ayarlar'daki metin ve düğme servis kaydını da kapsıyor.
- [ ] PLAN satır 144 `[x]` değil, kutucuksuz "Mac doğrulaması bekliyor" notu. §2 metni değişmemiş. GUNDEM'de yukarıdaki 5 soru var.
- [ ] PR açıklamasında şu cümle var: "yasak-liste koruması ve .system root yolu §2.3/§2.8 ile uzlaştırılmadı, sahip kararına bırakıldı." "Güvenlik tamam" ya da "Sistem Ayarları ile aynı" gibi bir ifade yok.
- [ ] Yeni bağımlılık yok, `project.yml` değişmemiş.

## Kapsam dışı
- `refusal`'ı allowlist'e çevirmek, koruma ajanları (güvenlik, VPN, yedekleme, MDM, Keel'in kendisi) için ek ret listesi ya da uyarı. Sahibe soru 3, ayrı mahkeme.
- `.system` yönetici yolunda ya da fan yardımcısında her türlü değişiklik.
- Anahtara onay penceresi eklemek.
- Uygulama içi "son değişiklikler" listesi (soru 4).
- `launchctl` ham hata mesajlarını Türkçeleştirmek.
- `ActionLog` biçiminde değişiklik ya da iki kaydı birleştirmek.
- Kayıt dosyası döndürme veya boyut sınırı.
- Seçenek E: SMAppService/BTM öğeleri, `sfltool`, BTM veritabanı.
- Satır 144'ü `[x]` yapmak. Bu ancak sahibin Mac doğrulamasından sonra olur.
- Rakiplerle (CleanMyMac, Stats, AppCleaner) ilgili her türlü iddia.

---
Not (ana oturum için): Okuduğum dosyalar: dava klasöründeki dört dosya, `/home/claude/keel/docs/PLAN.md` (§2 ve Faz 2), `/home/claude/keel/Packages/KeelCore/Sources/KeelCore/Startup/LaunchControl.swift`, `/home/claude/keel/Packages/KeelCore/Sources/KeelCore/Actions/ActionLog.swift`, `/home/claude/keel/App/Features/Performance/SystemControl.swift`, `/home/claude/keel/App/Features/Performance/PerformanceModel.swift`, `/home/claude/keel/App/Features/Optimization/OptimizationView.swift`, `/home/claude/keel/App/Features/Settings/SettingsView.swift`, `/home/claude/keel/docs/mahkeme/GUNDEM.md`, `/home/claude/keel/.claude/commands/gelistir.md`. Dava dosyasındaki "ActionLog App/ içinde kullanılmıyor" iddiası yanlış çıktı (ApplicationsModel.swift:243, Undo.swift:8, SettingsView.swift:84). Kullanıcı belleğinden bilgi kullanmadım. Dosya yazmadım, kod yazmadım.
