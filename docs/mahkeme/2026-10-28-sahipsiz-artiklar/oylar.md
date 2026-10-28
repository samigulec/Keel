# Jüri oyları

Oylar gizli verildi; hiçbir jüri diğerlerinin oyunu görmedi.

---

JÜRİ: Güvenlik uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Doğrudan bir PLAN §2 ihlali yok. Öneri Çöp'e taşıma, tek tek onay ve ActionLog kullanıyor. Kapsam ~/Library ile sınırlı, root istemiyor. Bu yüzden veto vermiyorum. Savunmanın önerdiği iki aşamalı ve daraltılmış hâl (Aşama 0 salt okunur, Aşama 1 yalnızca yeniden üretilebilir 6 konum) ilkelerin içinde kalıyor.
- Asıl güvenlik sorunu yokluk çıkarımı. "Hiçbir kurulu uygulamaya uymayan girdi sahipsizdir" kararı AppInventory'ye dayanıyor. AppInventory yalnızca /Applications ve ~/Applications altında bir klasör derinliğine bakıyor. Eksik kalan her uygulama (Homebrew Cask, Setapp, harici disk, ~/Downloads, yardımcı .app) yanlış pozitif ve silme adayı olur. Oran ölçülmedi. Bu yüzden envanter genişletilmeden ve ölçüm yapılmadan silme koduna geçilemez.
- PLAN §2/3 allowlist ilkesi eleme kodunda zayıflıyor. Apple ve iCloud girdilerini eleme işi (com.apple.*, group.com.apple.*, Safari, Calendars, AddressBook, CloudDocs) yeni bulucu koduna kalırsa fiilen yasak listesi mantığı çalışır. Savunma bunu orphan'a özel SafetyPolicy örneğiyle çözmeyi öneriyor, ama eleme yine ikinci bir yerde yaşıyor. İddianamenin "eleme SafetyPolicy içinde, tek yerde" şartı daha doğru. Hangisinin seçileceği koşul olarak aşağıda belirtildi.
- Aday kuralı olarak yalnızca bundle ID biçimli adların alınması, ad eşleştirmesinin kullanılmaması ve Spotlight/envanter okunamazsa boş liste dönmesi doğru yön. Yani başarısızlıkta güvenli tarafa düşüyor. Çalışan uygulamayı atlama (§2/6) bu yönde korunuyor. Ancak yalnızca çalışan uygulamaya bakmak, kurulu ama çalışmayan uygulamayı korumaz. Bunu envanter tamlığı karşılamak zorunda.
- İkinci bir silme yolu (OrphanRemover) CLAUDE.md'deki "silme yapan her kod SafetyPolicy'den geçer" kuralına bağlı. Mevcut UninstallPolicy.evaluateFile, FileRemover.moveToTrash ve ActionLog zinciri kopyalanmadan sarmalanırsa kabul edilebilir. Aksi hâlde güvenlik doğrulaması çiftlenir.
- Çöp boşaltıldığında yanlış pozitif kalıcı olur. Bu nedenle Application Support, Containers, Group Containers, Preferences ve LaunchAgents kapsam dışı kalmalı. LaunchAgents'ta çalışan ajanın plist'i Çöp'e gidebiliyor, bu da sessiz bozulma riski.
- Kod yazılması dosyaya göre `İNSAN ONAYI GEREKİR: EVET` kararına bağlı. Faz 2 öncelik sırası kullanıcıya sorulmadan kod yazılmamalı.
KOŞULLAR:
- Kullanıcı Faz 2 öncelik sırasını bu maddeye verene kadar hiçbir kod yazılmaz (CLAUDE.md, `İNSAN ONAYI GEREKİR: EVET`).
- Aşama 0 salt okunur ölçüm hiçbir silme çağrısı içermez. Önceden yazılmış bir yanlış pozitif eşiği (sıfıra yakın) ve ölçüm sonucunda tespit edilen listeler kullanıcıya gösterilir. Eşik aşılırsa Aşama 1'e geçilmez, Seçenek A'ya dönülür.
- Aşama 1 öncesi kurulu uygulama envanteri genişletilir: Spotlight/LaunchServices ile harici disk, Setapp, Homebrew Cask, ~/Downloads ve yardımcı .app bundle ID'leri dahil edilir. Envanter ya da Spotlight okunamazsa sonuç boş aday ve "emin değilim" olur, "temiz" olmaz. Bu davranış testle korunur.
- Kapsam yalnızca Caches, Logs, Saved Application State, HTTPStorages, WebKit, Cookies. Diğer konumlar için ayrı mahkeme gerekir. İzinli kök listesi orphan akışında bu 6 konumdan ibaret olur, test bunu doğrular: Application Support, Containers, Group Containers, Preferences, LaunchAgents ve /Library altı evaluate'ten ret alır.
- Apple ve iCloud elemesi tek yerde yapılır: com.apple.*, group.com.apple.*, Safari, Calendars, AddressBook, CloudDocs `SafetyPolicy` korunan kökleri (ya da onun tek tanımlı eleme noktası) olarak eklenir ve evaluate testleriyle korunur. Bulucudaki ek filtre yalnızca ikinci savunma hattıdır. SafetyPolicy'ye dokunan bu değişiklik için ayrı mahkeme kaydı tutulur.
- OrphanRemover mevcut `UninstallPolicy.evaluateFile`, `FileRemover.moveToTrash`, `ActionLog` ve `TrashRestorer` zincirini sarmalar, kopyalamaz. Sahiplik ve çalışan uygulama ID'leri silme anında yeniden doğrulanır. Sahte `InstalledApp` kullanılmaz.
- Yaş eşiği (savunmanın önerdiği en az 30 gün) sabit olur, gerekçesi yazılır ve testle korunur. Spotlight olmayan ortamda eşik atlanmaz, sınıflandırma daha temkinli olur.
- Gerekli testler: sahipsiz bulunur, kurulu uygulamanın dosyası bulunmaz, iç içe bundle ID doğru sahibe gider, com.apple.* ve group.com.apple.* bulunmaz, sembolik link reddedilir, korunan yol reddedilir, çalışan uygulama atlanır, farklı birim reddedilir, envanter okunamazsa boş aday döner, FDA yokluğunda okunamayan klasör "taranamadı" diye raporlanır ve boş sonuç "temiz" diye sunulmaz. Linux'ta test edilemeyen kısım (Spotlight/TCC) arayüz katmanına izole edilir ve Mac'te elle sınanır.
- Arayüz: ön seçim yok, "hepsini seç" yok, etiket "Sahibi bulunamadı" (kesinlik iddiası yok), her öğe tek tek gösterilir, Çöp'ten geri alma ve Çöp boşaltılırsa kalıcı olduğu açıkça yazılır, kazanç sayısı "tahmini" etiketiyle ve yanlış sınıflandırma uyarısıyla verilir.
- Seçenek D (Akıllı Tarama, KeelTools, AssistantModel, Keel AI'ya yol gönderme) bu karar kapsamı dışındadır. Yol adları bile kurulu ya da kaldırılmış uygulamaları sızdırır. Ayrı mahkeme ve ayrı veri akışı kararı olmadan eklenmez.

---

JÜRİ: macOS sistem uzmanı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Ters yönlü eşleştirme teknik olarak yapılabilir, ama mevcut kurulu-uygulama envanteri bunun için yetersiz. `AppInventory` yalnızca /Applications ve ~/Applications'ı bir klasör derinliğinde tarıyor. /Applications/Setapp/*.app gibi iki seviyeli yollar görünmez, dolayısıyla kurulu Setapp uygulamalarının verisi "sahipsiz" çıkar. Dosyanın ve iddianamenin bu tespiti doğru.
- Dosyada eksik kalan somut bir yanlış pozitif kaynağı var: Microsoft Office gibi uygulamalar Group Containers'ı TeamID önekli düz adla kullanır (ör. `UBF8T346G9.Office`). Bu ad `com.microsoft.Word` ile eşleşmez. Mevcut `owner(of:)` `TEAMID.com.x.app` biçimini bekliyor, `TEAMID.Office` biçimini değil. Ters yönde Office kurulu olsa bile bu klasör listeye girer. Çözüm, uygulamanın kod imza ekibini (SecStaticCode / `codesign -dv`, public API) okuyup TeamID eşleştirmesi yapmaktır. Bu, dosyada yoktur.
- macOS 14 ile gelen App Data koruması (SystemPolicyAppData) başka uygulamaların ~/Library/Containers ve Group Containers içeriğine erişimde kullanıcı izni ister. FDA yoksa içerik okuma ve `trashItem` izne takılabilir, bazen sessiz kısmi başarıyla sonuçlanabilir. Bu ayrıntıyı bu ortamda doğrulayamıyorum; bilgim bu yönde, ama Mac'te sınanmadan kabul edilemez. Dosyadaki "TCC doğrulanmadı" notu yerindedir.
- Sahip çözümleme için public API (NSWorkspace.urlForApplication(withBundleIdentifier:), LaunchServices kayıtları) mevcut `/Applications` taramasından daha geniş kapsar. Spotlight çapraz kontrolü için `mdfind` yerine NSMetadataQuery tercih edilmelidir. `mdfind` çıktısı indeks durumuna bağlıdır. Private LaunchServices sembolleri (_LSCopy... vb.) kullanılmamalı, bir sonraki macOS'ta kırılır.
- LaunchAgents seçeneği riskli. SMAppService/BTM (macOS 13+) ile kaydedilen öğelerin plist'i uygulama paketinde olabilir. ~/Library/LaunchAgents'taki plist'i silmek yüklü job'ı hemen durdurmaz, bir sonraki oturumda ajan sessizce yüklenmez. Dosyadaki C daraltması (LaunchAgents dışarıda) teknik olarak doğrudur.
- Caches, Logs, Saved Application State, HTTPStorages, WebKit ve Cookies yeniden üretilebilir veri türleridir ve bu daraltılmış kapsam makul. Yine de ad biçimi `x.y.z` olmayan üretici klasörleri (Google, Adobe, JetBrains, Homebrew, CrashReporter) ve com.apple.* dışı sistem girdileri elenmelidir.
- Uzun vadeli kırılma noktası dosya konumları ve public API değil, Apple'ın ~/Library'ye ek kısıtlar koyması ile elle tutulan Apple/üretici listeleridir. Bu listelerin SafetyPolicy içinde tek yerde ve testli tutulması gerekir.
- B ve D seçenekleri mevcut haliyle reddedilmeli. Ölçüm yapılmadan yanlış pozitif oranı bilinmiyor. A seçeneği güvenli bir geri çekilmedir ve kayıp küçüktür.

KOŞULLAR:
- Aşama 0 (salt okunur, silme yok) gerçek bir Mac'te çalıştırılır: Apple silicon ve mümkünse Intel, macOS 14 ve en güncel sürüm. Setapp, Homebrew Cask, /Applications/Utilities, harici disk ve Office (UBF8T346G9.*) dahil edilir. Eşik önceden kullanıcıyla belirlenir ve sonuçlar kayda yazılır.
- Sahip çözümleme NSWorkspace/LaunchServices ile genişletilir ve Group Containers için TeamID (kod imzası) eşleştirmesi eklenir. Test: Word kuruluyken `UBF8T346G9.Office` sahipsiz çıkmaz.
- TCC: FDA verili ve verisiz iki durum Mac'te sınanır. Okunamayan dizin "taranamadı" olarak raporlanır, boş sonuç "temiz" diye sunulmaz.
- Aşama 1 yalnızca Caches, Logs, Saved Application State, HTTPStorages, WebKit ve Cookies kapsamında olur. Application Support, Containers, Group Containers, Preferences ve LaunchAgents kapsam dışı kalır; bunları açmak için ayrı mahkeme gerekir.
- Apple/iCloud/Safari/Calendars/AddressBook/CloudDocs korunan kökleri SafetyPolicy içine eklenir ve evaluate testiyle doğrulanır.
- Spotlight çapraz kontrolü public API ile yapılır. İndeks kapalıysa aday listesi boş döner ve "emin değilim" denir.
- Faz 2 öncelik sırası kullanıcı tarafından verilir (İNSAN ONAYI GEREKİR), kod bu karar olmadan yazılmaz.

---

JÜRİ: sıradan Mac kullanıcısı
OY: RED
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- "Sahipsiz" kelimesi bana "bu uygulama artık yok, kalıntısı silinebilir" diyor. Ama dosyanın kendisi Keel'in kurulu uygulamaları yalnızca /Applications ve ~/Applications içinde gördüğünü yazıyor. Harici diskten, Downloads'tan veya Homebrew ile kurduğum bir uygulamanın verisi de "sahipsiz" diye listelenebilir. Bunu ben fark edemem.
- Dosyanın kendi itirafı: yanlış pozitif oranı hiç ölçülmemiş (Bilinmeyen 1). Ölçülmemiş bir listeyi onaylamam, kendi kararımı veremem.
- Listelenen yerler (Application Support, Containers, Group Containers) lisans, kayıt ve ayar gibi benim için değerli şeyleri tutabilir. Çöp'e gitmesi güven veriyor, ama Çöp'ü boşalttığım anda geri dönüş yok. Bu riski bir sihirbaz penceresinde anlayamam.
- Apple ve iCloud'a ait bazı girdilerin korunan listede olmadığını dosya kabul ediyor. Sistemin bir parçasını bozmaktan korkarım, bu da teknik bir kullanıcının bile kolay fark edemeyeceği bir sorun.
- Bu özelliğin benim için somut faydası küçük. Mac'in yavaşlamasının ve diskin dolmasının büyük kısmı zaten Temizlik bölümündeki önbellek ve günlük temizliğiyle çözülüyor. Dosyanın Savunma bölümü de kazancın küçük olduğunu kabul ediyor.
- Kendi önerim: bu madde şu an yapılmasın. Yalnızca ölçüm amaçlı, hiçbir şey silmeyen bir rapor ileride gerçek Mac'lerde denenebilir. Silme özelliği ancak bu ölçüm sonucu açıkça iyi çıkarsa tekrar gündeme gelsin.

---

JÜRİ: kıdemli Swift mühendisi
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Kod doğrulandı. `SafetyPolicy.standardProtectedRoots` (SafetyPolicy.swift 175 ve devamı) Apple/iCloud servis yollarını (Group Containers, AddressBook, Safari, Calendars, CloudDocs) içermiyor, dosyanın ve iddianamenin bu tespiti doğru. `AppLeftoverFinder.owner(of:)` (AppLeftovers.swift 103-109) ters yönde kullanılırsa "eşleşmedi = sil" anlamına gelir; bu, tasarlandığı dar eşleştirme varsayımını bozar.
- Dosyadaki satır numaraları güncel değil: `standardAllowedRoots` kodda 163-172'de, dosyanın verdiği 332-341 değil. Karar notu düzeltilmeli, yoksa ilerideki sahiplik kararları eski referansla yapılır.
- Mühendislik açısından en pahalı kısım silme değil, sınıflandırmanın kendisi: "kurulu uygulama kümesi" girdisi (AppInventory yalnızca /Applications ve ~/Applications, bir derinlik) eksik. Bu eksik, yanlış pozitifi yapısal olarak üretir. Ölçüm yapılmadan yazılacak her eşik keyfi kalır.
- Salt okunur Aşama 0 (orphans(installedBundleIDs:) saf fonksiyon, dosya sistemi girdisi parametre olarak verilir) KeelCore içinde yazılabilir ve Linux'ta test edilebilir. Yeni bağımlılık gerekmez. Bu aşamanın maliyeti düşük, değeri de gerçek veri üretmesidir. Destekliyorum.
- Spotlight/LaunchServices çapraz kontrolü `#if os(macOS)` arkasında, bir protokol üzerinden izole edilmeli. Linux'ta stub "bilinmiyor" döndürmeli ve aday listesi boş kalmalı. Bu, savunmadaki "emin değilim" davranışıyla uyumlu.
- Basit alternatif gerçekten daha iyi: Keel'in kendi görülmüş uygulama listesinin geçmişini tutmak (sahiplik bilgisi ölçülebilir, tahmin değil). Bu, dosya sistemi taramasının belirsizliğini ortadan kaldırır ve Linux'ta tam test edilebilir. Uygulama kalıcılığı için küçük bir JSON durumu gerekir; yeni bağımlılık gerekmez.
- Silme yolu (`OrphanRemover`) yeni bir silme yolu olarak yazılmamalı; `UninstallPolicy.evaluateFile` ve `perform` zincirini sarmalamalı. Kopya kod, CLAUDE.md'deki "silme yapan her kod SafetyPolicy'den geçer" kuralını ikinci kez doğrulatır.
- Marjinal fayda düşük: Caches zaten Temizlik tarafından `bundleIDFromName` ile yönetiliyor. Asıl kendine özgü değer Saved Application State, HTTPStorages, WebKit, Cookies ve Logs'ta. Bu, Aşama 0 ölçümü anlamlı çıkmadan Aşama 1'i haklı çıkarmaz.
KOŞULLAR:
- Aşama 0 (yalnızca salt okunur, silme yok): `orphans(installedBundleIDs:)` saf fonksiyon olarak KeelCore'da, Linux'ta birim testli. Gerçek bir Mac'te ölçüm sonucu (aday sayısı, yanlış pozitif örnekleri) kullanıcıya gösterilmeden Aşama 1'e geçilmez.
- Spotlight/LaunchServices kontrolü `#if os(macOS)` ve bir protokol arkasında; Linux'ta stub "bilinmiyor" döner ve aday listesi boş kalır. Bu davranış testle korunur.
- Aşama 1 kapsamı yalnızca Caches dışı yeniden üretilebilir türlerle sınırlı (Saved Application State, HTTPStorages, WebKit, Cookies, Logs). Application Support, Containers, Group Containers, Preferences, LaunchAgents için ayrı mahkeme kararı gerekir.
- Orphan için ayrı SafetyPolicy örneği; Library/Safari, Library/Calendars, Application Support/AddressBook, CloudDocs ve com.apple.*/group.com.apple.* korunan kök olarak eklenir ve `evaluate` testleriyle doğrulanır. Mevcut `SafetyPolicy` çekirdeğine dokunulmaz ya da dokunulacaksa bu ayrı mahkeme kapsamında yapılır.
- Silme yalnızca `UninstallPolicy.evaluateFile` + `FileRemover.moveToTrash` + `ActionLog` zincirinden geçer; `OrphanRemover` bu zinciri sarmalar, kopyalamaz. Silme anında sahiplik ve çalışan uygulama ID'si yeniden kontrol edilir.
- Kullanıcı önceliği ve yaş eşiği (ör. 30 gün) kullanıcı tarafından onaylanmadan Aşama 1 kodu yazılmaz. Dosya/iddianame satır numaraları kod üzerinden düzeltilir.

---

JÜRİ: ürün yöneticisi ve rakip analisti
OY: RED
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Madde Faz 2'de hâlâ `[ ]` ve bugünkü açık işler arasında öncelik sırası kullanıcının kararı. Bu özellik mevcut akışın tersi, yani "kurulu olmayan uygulamanın artığı" kategorisi. Keel'in uygulama kaldırıcısı zaten `[x]`, Temizlik zaten önbellekleri kapsıyor. Geriye kalan fayda, Keel dışında kaldırılan uygulamaların artıkları. Bu fayda dar ve dosyanın kendi ifadesiyle "küçük" (savunma: "kazanç küçük ve acil değil").
- Rakip farkı kanıtlanmış değil. Dosya rakiplerin kalıntı özelliği olduğunu söylüyor ama eşleştirme yöntemi ve kapsam doğrulanmadı. Bu yüzden "rakipler var, biz de olmalıyız" gerekçesi kullanılamaz. Keel'in farkı da bu özellikte görünmüyor: sahiplik bulma tahmine dayalı, Keel'in güç alanı olan güvenli kaldırma ise zaten var.
- Kod doğrulaması: `SafetyPolicy.standardAllowedRoots` gerçekte `SafetyPolicy.swift:163` civarında (dosyadaki 332 satır numarası yanlış), izinli kökler Caches, Logs, .Trash, Downloads, DerivedData, CoreSimulator/Caches. `standardProtectedRoots` ise `:175`'te, Keychains/Mobile Documents/Mail/Messages/Photos gibi yollar içeriyor. Dosyanın "Apple servis verisi korunan listede yok" itirazı kodda doğrulanıyor: `group.com.apple.*`, AddressBook, Safari, Calendars bu listede yok. Yani B/D seçeneği ya ilke 3'ü (allowlist tek yerde) bozar ya da yeni bir eleme listesi gerektirir.
- Risk-değer oranı kötü: silme yüzeyi Application Support/Containers'a açılırsa yanlış pozitif kullanıcı verisi (lisans, veritabanı) kaybına yol açar. Bu kayıp Çöp boşaltılınca kalıcı. Yanlış pozitif oranı hiç ölçülmemiş. Ölçülmemiş bir "sahipsiz" etiketi kullanıcıya yanlış güven verir ve PLAN §3 "uydurma sayı" ilkesiyle çelişir.
- Savunmanın önerdiği Aşama 0 (salt okunur tanı, silme yok) ucuz ve riski düşük. Ama bu ürün kararı değil, bir araştırma adımı. Ürün önceliğine girmesi için bugün bir talep ya da ölçülmüş ihtiyaç yok. Bu yüzden şimdi kod açmayı önermiyorum.
- Daha değerli görünen açık maddeler (örn. uygulama güncelleyici, kopya dosya bulucu, menü çubuğu canlı grafikleri) Keel'in çekirdek değeriyle daha doğrudan ilgili. Önceliklendirme kullanıcının kararı; ben bu maddeyi bu sıralamada geriye koyuyorum.
- Karar: PLAN satır 119 `[ ]` olarak kalsın ve "şimdilik ertelendi, gerekçe: düşük fayda, ölçülmemiş yanlış pozitif, korunan liste eksik" notu eklensin. Yeniden ele alma koşulu: kullanıcı önceliği verirse ve salt okunur ölçüm (Aşama 0) yanlış pozitifin sıfıra yakın olduğunu gösterirse, ayrı bir mahkemeyle yeniden değerlendirilsin. Silme içeren hiçbir aşama bu karara dayanarak yazılmasın.
