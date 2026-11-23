# Dava dosyası: Sahipsiz artıklar (kaldırılmış uygulamalardan kalanlar) bulucu

## Soru
PLAN.md Faz 2 satır 119'daki "Sahipsiz artıklar" maddesi (`~/Library` altında, sahibi artık kurulu olmayan uygulamaların bıraktığı dosyaları bulup kullanıcıya gösteren ve onayıyla Çöp'e taşıyan özellik) eklensin mi, eklenecekse hangi kapsam ve hangi güvencelerle?

## Mevcut durum

**Önceki yargılama:** Bu konu daha önce yargılanmadı. `docs/mahkeme/2026-10-28-sahipsiz-artiklar/` klasörü var ama boş. Tek ilgili önceki karar kopya dosya bulucu kararı (2026-10-27, dal `origin/claude/mahkeme-kopya-dosya-bulucu`). O karar sahipsiz artıkları yalnızca "Faz 2'deki diğer açık maddeler" olarak anıyor. Karar `İNSAN ONAYI GEREKİR: EVET` ve "açık maddeler arasındaki öncelik sırası kullanıcının kararı" diyor. Aynı soru burada da geçerli. Kopya bulucunun kendiliğinden önceliği yok, bu maddenin de yok.

**Bugünkü uygulama kaldırıcı (aynı mantığın yarısı hazır):**
- `Packages/KeelCore/Sources/KeelCore/Applications/AppLeftovers.swift`
  - `AppLeftoverFinder.locations` (satır 45-59) 13 konum tarar. Bunlar: Application Support, Caches, Preferences, Preferences/ByHost, Containers, Group Containers, Application Scripts, Saved Application State, Logs, HTTPStorages, WebKit, Cookies, LaunchAgents.
  - Eşleştirme dar tutulmuş (satır 32-36, 73-98). Girdi adı küçük harfe çevrilir, `.plist`, `.savedstate`, `.binarycookies` soneki ve ByHost UUID'si atılır (`stripSuffix`, 111-121). Sonuç bundle ID'ye eşitse, `ID.` ile başlıyorsa ya da `.ID` ile bitiyorsa (Group Containers: `TEAMID.com.x.app`, `group.com.x.app`) o uygulamanındır (`owner(of:)`, 103-109).
  - Başka kurulu uygulamanın bundle ID'si daha uzun eşleşiyorsa girdi ona aittir (`.max { $0.count < $1.count }`).
  - Ad ile eşleştirme yalnızca Application Support, Caches ve Logs için geçerlidir. Ad en az 4 harf olmalı ve `genericNames` içinde olmamalı (satır 77, 88, 124-127).
  - **Yani bugünkü mantık "bu uygulamanın dosyalarını bul" yönünde çalışır. Sahipsizlik için gereken ters yön, yani "hiçbir kurulu uygulamaya ait olmayan girdileri bul", yoktur.**
- `AppInventory.swift:55-80` yalnızca `/Applications` ve `~/Applications` (bir klasör derinliğinde) tarar. `/System/Applications` ve başka konumlar (`/Library/...`, harici disk, `~/Downloads` içindeki .app, Homebrew Cask, `/Applications/Utilities` dışı yardımcılar, bir sistem uzantısının .app'i) kapsam dışı. `isSystem` salt-okunur birime bakar (satır 112-122).
- `ApplicationsModel.swift:207-216` kurulu uygulamaların bundle ID'lerini toplayıp `AppLeftoverFinder`'a verir.
- `Uninstaller.swift`
  - `UninstallPolicy.evaluateFile` (102-108): `SafetyPolicy.evaluate` + "doğrudan arama klasörünün çocuğu" şartı.
  - `UninstallPolicy.standard` (64-74): izinli kökler `AppLeftoverFinder.locations`, korunan kökler standart liste.
  - `perform` (124-168): çalışan uygulamanın ID'sine bakar, her hedefi değerlendirir, `FileRemover.moveToTrash` çağırır, `TrashedItem` döndürür ve her sonucu `ActionLog`'a yazar.

**Güvenlik ve kayıt altyapısı:**
- `Safety/SafetyPolicy.swift`
  - `evaluate` (226-268): sembolik link zinciri çözülür, `.app` içi reddedilir, korunan köklerde ve onları kapsayan yolda ret, izinli kökün kendisi ret, farklı birim ret.
  - `standardAllowedRoots` (332-341) yalnızca Caches, Logs, .Trash, Downloads, DerivedData ve CoreSimulator/Caches. `Application Support`, `Containers` vb. burada **yok**. Uygulama kaldırıcı bunları kendi `SafetyPolicy` örneğiyle (`UninstallPolicy.library`) izinli yapıyor.
  - `standardProtectedRoots` (344-366): Keychains, Mobile Documents, Mail, Messages, Photos, Logs/Keel, Photos Library.
  - **Eksik olabilecek korunan yollar (doğrulanmadı):** `Library/Group Containers` ve `Library/Containers` içindeki Apple servislerinin veya iCloud'un verileri (ör. `group.com.apple.*`, `com.apple.*`), `Library/Application Support/AddressBook`, `Library/Safari`, `Library/Calendars` korunan listede değil. Sahipsiz tarama Apple girdilerini ayrıca elemek zorunda.
- `Actions/FileRemover.swift`: `moveToTrash` `FileManager.trashItem` ile yapılır, kalıcı silme ayrı metottur.
- `Actions/ActionLog.swift:5-60`: `Entry{date, removal, path, bytes, outcome(removed/skipped/failed/restored), detail}`. Her satır tek JSON, `~/Library/Logs/Keel/actions.log`.
- `Actions/TrashRestorer.swift:135-180`: geri alma yalnızca hâlâ Çöp'te olan öğeyi, eski yerinde aynı adlı öğe yoksa geri taşır ve `.restored` yazar.
- UI geri al: `App/Features/Cleanup/Undo.swift`. PLAN'da "Geri al (temizlik, uygulama kaldırma, büyük dosyalar)" `[x]`.

**Benzer özellik:** `LargeFiles.swift` uygulama verisi dosyalarını sahibine göre sınıflar (`belongs(toAnyOf:names:)`, satır 18-21; `appDataAreas`, satır ~150) ve çalışan uygulamaya ait olanı atlar. `CleanupScanner.swift:67` çalışan uygulamanın önbelleğini atlar (`SkippedItem.Reason.appRunning`, `CleanupCategory.swift:60`). `FileActivity.lastActivity` Spotlight `kMDItemLastUsedDate` kullanıyor (`Scanning/FileActivity.swift:30`), macOS dışında yok.

**Testler:** `Tests/KeelCoreTests/ApplicationsTests.swift` (`findsOnlyTheAppsOwnFiles` 89, `genericNamesDoNotMatchByName` 133, `uninstallsAppAndFilesToTheTrash` 143, `leavesRunningAppsAndKeelAlone` 160, `refusesAppsOutsideInstallFoldersAndFilesOutsideLibrary` 179, `refusesLinksPosingAsApps` 196). Sahipsiz tarama için test yok, kod yok. UI'da eşleşen ekran yok (`App/Features/` altında yalnızca Applications, Cleanup, LargeFiles vb.).

**Git:** Son commit `7d78cec`. Çalışma ağacında değişiklik yok.

## İlgili kurallar
PLAN.md §2 (satır 22-44):
1. Kalıcı silme yok, her şey Çöp'e. Geri alma var.
2. Önce göster, sonra onayla; yalnızca seçilen öğeler.
3. Allowlist, tek yerde `SafetyPolicy`, testli.
4. Korunan yollar: `.app` içi, iCloud Drive, Fotoğraflar/Mail/Mesajlar, Keychain'ler vb.
5. Sembolik link takip edilmez, başka diske taşan yol silinmez.
6. Çalışan uygulamanın verisine dokunulmaz.
7. Her işlem `~/Library/Logs/Keel/` altında kaydedilir.
8. Root yok (MVP). Sahipsiz tarama `~/Library` ile sınırlı kalırsa root gerekmez. `/Library` altındakiler (LaunchDaemons, PrivilegedHelperTools) bu ilke yüzünden kapsam dışı olmak zorunda.

Diğer:
- §5 Faz 2 satır 115-117 (`[x]` uygulama kaldırıcı): "~/Library artıkları (bundle ID ile eşleştirme, **kullanıcıya tek tek gösterilir**)". Aynı ilke sahipsiz artıklar için de doğal bir referans.
- Satır 119: `- [ ] Sahipsiz artıklar (kaldırılmış uygulamalardan kalanlar)` (madde yalnızca bu cümle, ayrıntı yok).
- PLAN §3 satır 59: karantina yok, Çöp Kutusu kullanılır. Satır 53-58: "uydurma sayı" kaçınma ilkesi (kazanç beyanı için).
- CLAUDE.md: mahkeme zorunlu (yeni özellik + silme), `SafetyPolicy`'ye dokunan değişiklik, `İNSAN ONAYI GEREKİR: EVET` ise kod yazılmaz.
- Kopya bulucu kararı (bağlam): "koruyucu kopya silme anında doğrulanır", "önceden seçili gelmez / hepsini seç yok", "uzantı listesine dayalı paket tespiti zayıf" gibi ilkeler benzer bir silme yüzeyi için emsal. Kullanıcı sırası belirleyene kadar kod yok.

## Dış araştırma
Tek web araması yapıldı, sonuçlar kaynak sayfa özetlerinden ibaret. İçerikleri ayrıca okunmadı, aşağıdakiler **doğrulanmadı** olarak işaretli.
- Rakipler "kalıntı" araçlarını sunuyor: Nektony App Cleaner & Uninstaller "kaldırılmış uygulamaların kalıntılarını sil" bölümü (https://nektony.com/support/faq-app-cleaner/remove-service-files), Mole rehberi (https://mole.tw93.fun/blog/how-to-remove-leftover-files-after-uninstalling-mac-apps), iBoysoft rehberi (https://iboysoft.com/howto/remove-app-leftover-files-mac.html). CleanMyMac'in "Leftovers" modülü olduğuna dair bir bulgu var ama kaynak sayfası okunmadı (https://www.stellarinfo.com/blog/remove-delete-mac-leftover-files). Rakiplerin eşleştirme yöntemi (bundle ID mi, ad mı, buluşsal mı) **doğrulanmadı**.
- DEVONtechnologies forumundaki bir başlık (https://discourse.devontechnologies.com/t/anyone-have-problems-with-cleanmymac-new-version/82317) CleanMyMac'in yeni sürümünde sorun bildiren kullanıcıları gösteriyor. İçerik okunmadı, kanıt değeri **doğrulanmadı**.
- **Doğrulanmadı (genel bilgi, kaynaksız):** macOS 14+ TCC, `~/Library/Containers` ve `Group Containers` içeriğine başka uygulamaların erişimini kısıtlıyor (Full Disk Access yoksa listeleme/silme başarısız olabilir). PLAN "Full Disk Access yoksa onboarding" dediğine göre (satır 112) uygulama FDA'yı zaten bekliyor. Gerçek davranış Mac'te sınanmadı.
- **Doğrulanmadı:** Aynı bundle ID'nin sistem uzantıları, Setapp/Homebrew/başka kullanıcıya kurulu uygulamalar, Xcode simülatörü, `/Applications` dışı .app'ler (ör. harici disk, `~/Downloads`) kurulu olduğu hâlde `AppInventory` tarafından görülmeyebilir, bu durumda sahipsiz sanılırlar.

## Seçenekler

**A. Hiç yapmamak / ertelemek.** PLAN satır 119 "yapılmayacak (gerekçe)" notuyla kapatılır ya da `[ ]` olarak kalır. Dosya: `docs/PLAN.md`. Büyüklük: çok küçük. Mevcut "uygulamayı kaldırırken artıkları da götür" akışı zaten var, geride kalan sorun yalnızca Keel dışında kaldırılan uygulamalar (Finder'dan çöpe atma, Homebrew vb.).

**B. Salt okunur sahipsiz bulucu, kullanıcı tek tek onaylar (uygulama kaldırıcı ilkesiyle).**
- Yeni `Applications/OrphanedLeftovers.swift` (ya da `AppLeftoverFinder`'a ters yönlü bir `orphans(installedBundleIDs:)`). 13 konumdaki her girdinin sahibi `owner(of:)` ile aranır, bulunamazsa ve bundle ID biçimli (`x.y.z`) ise aday olur.
- Eleme: `com.apple.*`, `group.com.apple.*`; ID biçimi olmayan adlar (`Google`, `Adobe`, `Application Support/Firefox` vb.) ve `genericNames`; yeni değişmiş girdiler (eşik karar gerektirir); çalışan uygulamaların ID'leri.
- Silme: mevcut `Uninstaller`/`UninstallPolicy.evaluateFile` yeniden kullanılır. `UninstallPlan` uygulaması olmadığı için ya yeni bir plan türü (`removesApp: false` ve sahte `InstalledApp`) ya da küçük bir `OrphanRemover` gerekir. `ActionLog`, `TrashedItem` ve `TrashRestorer` olduğu gibi çalışır.
- Arayüz: `App/Features/Applications/` altına bir sekme ya da yeni bölüm, ya da ayrı `Orphans/` klasörü. Ön seçim yok.
- Testler: sahipsiz bulunur, kurulu uygulama dosyası bulunmaz, `com.apple.*` bulunmaz, iç içe ID'ler (`com.x.app.pro`) doğru sahibe gider, sembolik link, korunan yol, çalışan uygulama.
- Büyüklük: orta (KeelCore ~1 yeni dosya + test, UI ~2 dosya).

**C. B'nin daraltılmış hâli: yalnızca düşük riskli türler (Caches, Logs, Saved Application State, HTTPStorages, WebKit, Cookies).** `Application Support`, `Containers`, `Group Containers`, `Preferences`, `LaunchAgents` kapsam dışı. Gerekçe: bu klasörler kullanıcı verisi (belge, veritabanı, lisans, ayar) ve ayarlar içerebilir, önbellekler ise yeniden üretilir. Büyüklük: B'den küçük. Faydası da daha az olabilir (önbellekleri zaten Temizlik bölümü siliyor, `CleanupScanner` `bundleIDFromName` ile sahibini biliyor).

**D. B + otomatik/öneri.** Akıllı Tarama'ya ("tek tıkla bakım") ve Keel AI'ya sahipsiz artıkları ekleme. Bu `SmartCare.swift`, `KeelTools.swift`, `AssistantModel.swift`'e dokunur ve yolların Keel AI'ya gitmesi sorusunu açar (PLAN satır 154: dosya içeriği asla, yalnızca özet). Ayrı karar gerektirir.

## Bilinmeyenler
1. **Yanlış pozitif oranı:** Sahibi gerçekten kurulu ama `AppInventory`'nin görmediği uygulamalar (`/Applications` dışı, harici disk, Setapp, Homebrew Cask, başka kullanıcı) yüzde kaç? Gerçek bir Mac'te salt okunur ölçüm yapılmadı.
2. **Aynı veri tek yerde mi?** Bir uygulama silinmiş ama kullanıcı yeniden kuracaksa (lisans, oyun kayıtları, veritabanı) `Application Support`/`Containers` içindekiler geri döndürülemez kayıp gibi hissettirir. Çöp'e taşımak geri alınabilir ama Çöp boşaltılırsa kalıcıdır.
3. **Apple/sistem girdileri:** `com.apple.*` dışında hangi girdiler sistem/Apple servisine ait (ör. `Group Containers/group.com.apple.*`, iCloud, `Application Support/CloudDocs`, `com.microsoft.*` Office ortak klasörleri, `Adobe`, `JetBrains`)? Liste bilinmiyor, Mac'te doğrulanmadı.
4. **FDA/TCC:** `Containers`/`Group Containers` Full Disk Access olmadan ne kadar okunabiliyor? Sınanmadı.
5. **Kullanıcı önceliği:** Kopya bulucu kararında istenen "Faz 2 açık maddeleri arasında sıra" (119, 120, 122, 124, 144) hâlâ belirsiz. Bu maddenin önceliği için kullanıcıya sorulmalı.
6. **Yaş eşiği:** "Sahipsiz" tanımına bir yaş şartı (örneğin son değişiklik 30+ gün) eklenmeli mi? Yeni kaldırılmış ya da yeniden kurulacak bir uygulamayı korur, ama eşik değeri keyfi olur.
7. **Rakip davranışı:** CleanMyMac, AppCleaner, Nektony sahipsiz tespitini hangi yöntemle ve hangi klasörlerde yapıyor? Kaynaklar okunmadı.
8. **Mevcut `UninstallPolicy` yeniden kullanımı:** `UninstallPlan`'ın `InstalledApp` zorunluluğu sahipsiz öğelere uyar mı, yoksa ayrı bir tür mü gerekir? Kod okundu ama tasarım denenmedi.
