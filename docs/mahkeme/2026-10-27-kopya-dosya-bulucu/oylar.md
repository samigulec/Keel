# Jüri oyları

Oylar gizli verildi; hiçbir jüri diğerlerinin oyunu görmedi.

---

JÜRİ: Güvenlik uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Önerilen B-daraltılmış sürüm PLAN §2'deki sekiz ilkeden hiçbirini çiğnemiyor. Silme `FileRemover.moveToTrash` ile Çöp'e gidiyor (§2.1). Tarama salt okunur kalıyor, silme yalnızca onaydan sonra ve seçilenler için çalışıyor (§2.2). `SafetyPolicy` koduna dokunulmuyor (§2.3). Korunan yollar, sembolik link ve başka disk kontrolleri mevcut zincirle geliyor (§2.4, §2.5). İşlemler `ActionLog`'a yazılıyor (§2.7). Root yetkisi gerekmiyor (§2.8). Bu yüzden veto yok. D (klonlama) ise PLAN ile çelişiyor ve "İNSAN ONAYI GEREKİR" kapsamında. C'nin güvenlik yüzeyi de geniş. İkisine de karşıyım.
- İddianamenin Risk 3'ü haklı ve güvenlik açısından en önemlisi. Savunma, "en az bir kopya korunur" kuralını `DuplicateRemover` içinde zorlamayı kabul ediyor. Ama yeniden doğrulamayı "boyut ve değişiklik tarihi aynı mı" diye yazıyor. Tarih ve boyut içerik doğrulaması sayılmaz. Tarama sonrası bozulan ya da değiştirilen bir kopya buradan geçebilir. Hayatta kalan kopyanın içeriği silme anında byte düzeyinde yeniden doğrulanmalı. Aksi hâlde kullanıcı, tek gerçek kopyasını "kopyası var" güvencesiyle kaybeder.
- Risk 2, §2.2 bakımından gerçek. `~/Desktop` ve `~/Documents` iCloud senkronu altında olabilir. Dataless dosyayı okumak indirmeyi tetikler, bu tarama sırasında yan etki demektir. Senkronlanan bir dosyayı Çöp'e taşımak da silmeyi diğer cihazlara yayar. Savunmadaki "iCloud ve bulut yer tutucu dosyaları dışarıda" cümlesi somut bir kural değil. Koda ve teste bağlanmadan kabul edemem.
- Risk 5 (politika kopyalama) kabul edilebilir bir yapı sorunu değil, güvenlik sınırı sorunu. Korunan yol listesi iki yerde tutulursa zamanla ayrışır. "Tek kapı" ilkesi pratikte zayıflar. Politika tek yerden gelmeli.
- Bilinmeyen paketler (Risk 2, üçüncü madde) gerçek bir veri bozma yolu. `packageExtensions` listesi sabit ve kısa. Paket içindeki bir dosyayı "kopya" diye Çöp'e atmak paketi bozar. Liste yerine `isPackage` ya da `Info.plist` gibi genel bir kural gerekiyor.
- Bayt bayt karşılaştırma önerisi (kriptografik karma yok, yeni bağımlılık yok) güvenlik açısından da iyi. Çakışma riski kalmıyor, denetlenecek kriptografik kod yazılmıyor ve mantık Linux'ta test edilebiliyor.
- Keel AI ve Akıllı Tarama kapsam dışı bırakılmış. Bu doğru. Kopya grubu bilgisi, yani hangi dosyaların aynı olduğu, içerik hakkında çıkarım sızdırır. Dosya yolları da hassas olabilir. Keel AI'ya veri gitmesi geri alınamaz. Akıllı Tarama'ya girerse otomatik seçimli silme yolu doğar. İkisi ayrı mahkeme kararı gerektirir.
- Yanlış kazanç iddiası ve kasıtlı kopyalar öncelikle ürün sorunu. Güvenlik açısından önemli olan nokta şu: hiçbir şey otomatik seçilmemeli ve her silme açık onay istemeli. Savunmadaki "varsayılan öneri (en eski/en kısa yol)" bu noktada riskli. Önerilen dosyalar önceden işaretli gelirse onay kullanıcı için anlamsız bir tıklamaya dönüşür.

KOŞULLAR:
- Silme anında `DuplicateRemover` içinde, arayüzden bağımsız olarak şunlar yapılır. Silinecek dosya ve grupta kalan en az bir kopya için varlık kontrolü yapılır. Her iki tarafın içeriği byte byte yeniden karşılaştırılır. Yalnızca boyut ve tarih bakmak yetmez. Ardından bu kopya `policy` ve sembolik link çözümünden geçmeli. Çağrıdaki seçim bir grubun tamamını kapsıyorsa işlem reddedilir. Aynı çağrıda iki dosya seçilip her biri diğerini "koruyucu" saymasın diye, koruyucu kopya silinecekler kümesinin dışında olmalıdır. Testler: koruyucu kopya kaybolmuş, koruyucu kopya değişmiş (boyutu aynı, içeriği farklı), silinecek dosya değişmiş ve grubun tamamı seçilmiş durumları reddedilir.
- Bulut kuralı koda yazılır ve testlenir. `isUbiquitousItem` / `ubiquitousItemDownloadingStatus` ile dataless ve senkronlanan dosyalar taramada atlanır ve içerik için asla açılmaz. iCloud "Masaüstü ve Belgeler" senkronu açıksa ilgili klasörler ya atlanır ya da kullanıcıya açıkça söylenir ve varsayılan olarak atlanır. Dropbox/OneDrive gibi bilinen bulut klasörleri için de aynı muamele uygulanır. Bu kural macOS'a özgü olduğundan, Linux testleri için soyutlanır (örn. bir protokol arkasında) ve sahte uygulamayla test edilir.
- Politika tek yerden gelir. `LargeFileRemover.policy` ortak bir yere çıkarılır ve iki silici de onu kullanır. Korunan yol listesinin kopyası kabul edilmez. Ortak politikayı doğrulayan bir test, iki sicil için de koşar.
- Paket tespiti uzantı listesine güvenmez. `isPackage` değeri ya da `Info.plist` varlığına göre genel bir kural kullanılır. Paket içindeki dosyalar hem gruplamaya hem silmeye girmez. Silme sırasında da yolun herhangi bir üst klasörünün paket olup olmadığı kontrol edilir. Test: bilinmeyen uzantılı bir paketin içindeki aynı dosyalar listelenmez ve silinemez.
- Hiçbir kopya önceden seçili gelmez. "Orijinal" önerisi gösterilebilir ama silinecekler kullanıcı tarafından tek tek işaretlenir. "Hepsini seç" ve grup bazında toplu işaretleme olmaz. Onay ekranı kaç dosyanın ve hangi yolların Çöp'e gideceğini açıkça listeler.
- Aynı inode (hard link) için bir tanesini silmeye izin verilmez. Bu adlar kopya olarak sunulmaz. Aynı birimde olmayan dosyalar aynı gruba girmez. İkisi için de test eklenir.
- Kapsam dışı bırakılanlar şart olarak yazılır. İlk sürüm Keel AI aracına (`KeelTools`, `AssistantModel`) ve Akıllı Tarama'ya (`SmartCare`) bağlanmaz. Bu iki entegrasyon için ayrı mahkeme kararı gerekir. Kopya grup bilgisi ve yolları Keel AI'ya hiçbir koşulda gitmez.
- Her atlama, reddetme ve başarılı silme `ActionLog`'a yazılır. Başarılı silmede hangi koruyucu kopyanın doğrulandığı da kayda geçer.
- Adım 0 ölçümü salt okunur çalışır. Ölçüm kodu da bulut kuralını ve paket kuralını uygular. Ölçüm kodu silme yolu içermez ve birleşmez. Sonuç anlamlı değilse A seçilir.
- Karşılaştırma bağımlılıksız yapılır (standart kütüphane, byte byte). swift-crypto bu mahkemede onaylanmış değil. Eklemek istenirse ayrı karar gerekir. Tüm mantık `swift test --package-path Packages/KeelCore` ile Linux'ta geçer.
- Kazanç metni "yer açılmayabilir (APFS klonları)" uyarısıyla gösterilir ve "kazanılır" gibi kesin ifade içermez. Bu bir güvenlik şartı değil, yanlış güven vermeme şartıdır. Yine de testle doğrulanır.

---

JÜRİ: macOS sistem uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Dosya teknik olarak mümkün. Boyut ve kısmi/tam bayt karşılaştırması Foundation ile yapılabilir, `LargeFileScanner` ve `LargeFileRemover` kalıbı yeniden kullanılabilir, `FileRemover.moveToTrash` ve `TrashRestorer` de mevcut. Yeni bağımlılık gerekmiyor. Bu, savunmanın "sıfır bağımlılık" iddiasını doğruluyor.
- Klon sorunu gerçek ve macOS'ta public bir API ile çözülmüyor. APFS'te paylaşılan bloklar için resmi bir sorgu yok. `ATTR_CMNEXT_*` ya da `fcntl` yolu public belgelenmiş bir sözleşme değil, sürümler arası davranışı doğrulanmamış. Bu yüzden kazanç yalnızca "en fazla" olarak gösterilebilir. Savunmanın bu kabulü doğru, ama "klon ayrımı denenir" maddesi kırılgan bir uygulamaya bağlanmamalı.
- Bulut sorunu iddianamenin en somut riski. `~/Desktop` ve `~/Documents` iCloud Drive senkronu açıkken dataless dosyalar yalnızca okumayla indirilebilir. Bu yüzden taramadan önce `URLResourceValues` üzerinden `isUbiquitousItem` ve `ubiquitousItemDownloadingStatus` public API'siyle kontrol edilmeli, dataless olan dosya hiç açılmamalı. Savunmadaki "bulut yer tutucu dosyaları dışarıda" ifadesi bu kontrol kod olarak yazılmadıkça yeterli değil.
- Paket tespiti sabit uzantı listesine (16 uzantı) dayanıyor. Bu, `.pvm`, `.rtfd`, `.vmwarevm`, `.dtBase` gibi paketlerin içindeki dosyaların "kopya" diye gösterilmesine yol açabilir. `URL.isPackageKey` ya da `.skipsPackageDescendants` kullanımı daha güvenilir ve macOS sürümleri arasında daha kararlı.
- Silme güvenliği için en kritik eksik, hayatta kalacak kopyanın silme anında yeniden doğrulanmaması. Savunmadaki "kalan koruyucu kopya hâlâ var mı ve içeriği aynı mı" kuralı ancak `DuplicateRemover` içinde zorlanırsa geçerli. Yalnızca arayüzde kalırsa tek kopya kaybı mümkün.
- TCC ve izin istemleri Mojave'den beri Desktop, Documents ve Downloads için gerçek. Full Disk Access onboarding'i bunu kapsıyor, ama izin yoksa klasörün sessizce atlanması ve kullanıcıya bildirilmesi gerekiyor. Bu doğrulanmamış, Adım 0'da test edilmeli.
- Akıllı Tarama ve Keel AI entegrasyonu bu sürümde kapsam dışı kalmalı. Otomatik seçimli bir silme yolu tek tıkla bakım içinde doğar, bu §2.2 ile çelişir.
- Ölçüm yapılmadan kapsamın değeri belirsiz. Gerçek kopya oranı ve tarama süresi bilinmiyor. Adım 0 olmadan "yapılsın" demek sağlam bir karar olmaz.
KOŞULLAR:
- Adım 0 ölçümü birleşmeden yapılır: gerçek ev klasöründe 1 MB üstü kopya grubu sayısı, "en fazla" kazanç, tarama süresi ve bellek ölçülür. Sonuç ihmal edilebilirse madde kapatılır.
- Bulut kontrolü public API ile kodlanır ve testlenir: `isUbiquitousItem` ve `ubiquitousItemDownloadingStatus` dataless olan dosyalar açılmadan atlanır. Test, dataless bir dosyanın okunmadığını doğrular.
- Paket tespiti uzantı listesine değil, `isPackageKey` ya da `.skipsPackageDescendants` değerine dayanır. Bilinmeyen paketlerin içindeki dosyalar gruplanmaz.
- Silme anında `DuplicateRemover` içinde hem silinecek dosya hem de grupta kalan en az bir kopya yeniden okunur ve bayt bayt karşılaştırılır. Uyuşmazlıkta işlem reddedilir ve test edilir. "Hepsini seç" yolu olmaz.
- Kazanç metni yalnızca "en fazla" olarak gösterilir. `ATTR_CMNEXT_*` ya da `fcntl` yolu denenirse sonuç ayrı bir kararla değerlendirilmeden ürün metnine girmez.
- Politika tek kaynaktan gelir: `LargeFileRemover.policy` ortak bir yere çıkarılır ya da kopyalanmaz. `SafetyPolicy` kodu değişmez.
- Akıllı Tarama ve Keel AI entegrasyonu bu sürümde yapılmaz. Bunlar ayrı mahkeme kararı gerektirir.

---

JÜRİ: sıradan Mac kullanıcısı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Mac'im yavaşladı ve diskim doldu. Aynı filmi ya da PDF'yi iki kez indirmiş olmak bu sorunun gerçek bir parçası, o yüzden kopyaları bulup Çöp'e göndermek işime yarar.
- Onay istenmesi ve Çöp'e gitmesi beni rahatlatıyor. Yanlışlıkla silersem geri alabilirim.
- Bir kopyayı "kazanç" diye gösterip yerin açılmaması beni en çok kızdırırdı. Dosyada yer açılmayabileceği ve bunun doğrulanmadığı yazıyor. Kullanıcıya "X GB kazanılır" gibi kesin bir vaat verilmemeli.
- Kendi klasörlerimde kopya sandığım ama gerçekten ihtiyacım olan dosyalar var (proje kopyaları, yedekler). Hangisinin kalacağını ben seçebilmeliyim ve bütün kopyaları birden silen bir yol olmamalı.
- iCloud'daki dosyalar tarama sırasında internetten inip Mac'imi daha da doldurmamalı. Bulutta duran dosyalar listeye alınmamalı.
- Teknik ayrıntıları (karma, klon, politika kodu) değerlendiremem, ama bunların bozulursa en çok benim tek kopyamı kaybedeceğimi anlıyorum.
KOŞULLAR:
- Ekranda yer kazancı için kesin bir rakam yazılmaz. Metin "yer açılmayabilir" uyarısını içerir ve bu uyarı arayüzde açıkça görünür.
- Bir grubun tüm kopyaları seçilemez. Silmeden hemen önce, kalan kopyanın gerçekten var olduğu ve içeriğinin aynı olduğu kontrol edilir. Bu kontrol test edilir.
- iCloud, Dropbox ve OneDrive klasörlerindeki dosyalar, bulut tarafında yalnızca yer tutucu olanlar dahil, taramada hiç açılmaz ve listelenmez. Bu kural test edilir.
- Hangi kopyanın kalacağı varsayılan olarak otomatik seçilmez. Kullanıcı her grupta kendisi seçer, varsayılan öneri varsa bu açıkça belirtilir.
- Silinecek her dosyanın yolu ve boyutu onaydan önce listede görünür. Silinen dosyalar Çöp'ten geri alınabilir kalır.
- Özellik ilk sürümde Akıllı Tarama'ya ya da Keel AI'ya bağlanmaz.

---

JÜRİ: kıdemli Swift mühendisi
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Savunmanın önerdiği B'nin daraltılmış hali mühendislik açısından makul. Yeni güvenlik yüzeyi çoğunlukla mevcut `LargeFileScanner`/`LargeFileRemover` kalıbı, `SafetyPolicy`, `ActionLog` ve `TrashRestorer` ile kurulabiliyor. Bayt karşılaştırması için bağımlılık gerekmiyor, bu yüzden CryptoKit/swift-crypto ve Linux CI sorunu ortadan kalkıyor.
- İddianamenin en güçlü noktası, "X GB kazanılır" vaadinin APFS klonları yüzünden yanlış çıkabileceği. Savunma bunu kabul edip kazancı yalnızca "en fazla" olarak gösterme ve ölçüm adımı (Adım 0) önererek ele alıyor. Bu yeterli, ama ölçüm sonucu kod kararını bağlamalı.
- Bulut/dataless dosyalar gerçek bir risk. Savunma "iCloud ve bulut yer tutucu dosyaları dışarıda" diyor ama bunu koda bağlayan bir mekanizma (ör. ubiquitous/download status kontrolü) ve buna ait test belirtmiyor. Masaüstü ve Belgeler'in iCloud senkronu açıkken bu, §2.2 ihlaline dönüşebilir.
- Politikanın kopyalanması riski gerçek. Savunma "aynen kullanılır" diyor ama `LargeFileRemover.policy` bir yerde tanımlı olduğu için ortak bir yere çıkarılmazsa iki korunan yol listesi zamanla ayrışır. Bu, §2.3 tek kapı ilkesini zayıflatır.
- "En az bir kopya korunur" ve silme anında kalan kopyanın içeriğinin yeniden doğrulanması savunmada var ve doğru. Bu kontrolün arayüzden bağımsız, `DuplicateRemover` içinde ve testli olması şart. Tarama ile onay arasında son kopya değişirse ya da silinirse korumanın çalışması gerekir.
- Paket tespiti için sabit uzantı listesi yetersiz (`.pvm`, `.rtfd`, `.vmwarevm` gibi paketler listede yok). Bu, paketin içindeki parçaları "kopya" diye sunmaya ve paketi bozmaya yol açabilir. Dosya sisteminden `isPackage` benzeri bir kontrol kullanılmalı.
- Kapsam dışı tutma kararı doğru: Akıllı Tarama, `KeelTools` ve harici disk entegrasyonu ilk sürümde olmamalı. Bu, otomatik seçimli silme yolunu ve AI'ya giden yol/ad verisini engeller.
- Yeni bağımlılık yok ve derlemenin Linux'ta geçtiği Adım 0'da doğrulanacak. Bu, CLAUDE.md'nin "mantık Linux'ta test edilebilir" kuralına uyuyor.
KOŞULLAR:
- Kod birleşmeden önce Adım 0 ölçümü yapılmalı: gerçek ev klasöründe grup sayısı, "en fazla" boyut, süre ve bellek kaydedilmeli. Kazanç ihmal edilebilir çıkarsa madde "yapılmayacak" notuyla kapatılmalı.
- Bulut kuralı koda yazılıp testlenmeli: dataless ya da iCloud senkronlu dosyalar taramada atlanmalı ve karma/karşılaştırma için asla açılmamalı. Test, sahte bir "bulut durumu" sağlayıcısı üzerinden Linux'ta çalışmalı. Masaüstü ve Belgeler'in iCloud senkronu açıksa ya tümden atlanmalı ya da kullanıcıya açıkça gösterilmeli.
- `LargeFileRemover.policy` ortak bir yere çıkarılmalı, `DuplicateRemover` bunu kopyalamamalı. Korunan yol listesi için tek kaynak ve iki kullanım için aynı testler gerekli.
- "Her gruptan en az bir kopya korunur" kuralı `DuplicateRemover` içinde zorlanmalı ve bir grubun tamamının verildiği durum testle reddedilmeli. Silme anında hem silinecek dosya hem kalan kopya varlık ve bayt bayt içerik açısından yeniden doğrulanmalı. Karma yalnızca gruplama için kullanılabilir, son doğrulama byte byte olmalı.
- Paket tespiti uzantı listesine değil dosya sistemi özelliğine (ör. `isPackage`) dayanmalı. Paket içindeki dosyalar hiçbir durumda kopya olarak sunulmamalı.
- Hard link davranışı tanımlanmalı: aynı inode'un adları tek öğe sayılmalı, birbirinin "kopyası" olarak silme adayı gösterilmemeli. Bu davranışa dair bir test eklenmeli.
- Akıllı Tarama, `KeelTools` ve Keel AI entegrasyonu bu sürümde yer almamalı. Bunlar ayrı bir mahkeme kararı gerektirir.

---

JÜRİ: ürün yöneticisi ve rakip analisti
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Kopya bulucu, CleanMyMac ve Gemini 2 gibi rakiplerde zaten var. Keel'in "CleanMyMac benzeri" konumu için eksik bir parça, yani kopyalama değil tamamlama. Farkı, geri alma, onay ve dürüst kazanç gösterimi gibi güven özellikleri yaratabilir. Ancak bu fark ürün vaadine yansıtılmazsa rakiplerden ayrışmaz.
- Asıl sorun değer ölçülmemiş olması. Dava dosyası, kullanıcının makinesinde kaç gerçek kopya çıkacağını ve APFS klonları yüzünden kazancın ne kadar küçük kalacağını bilmiyor. Kazanç dürüst gösterilirse rakiplerin "X GB kazanın" vaadi kadar çekici olmayabilir. Bu yüzden ölçüm, özelliğin ürün olarak değerini belirleyen tek kanıt.
- Kullanıcı tarafında gerçek bir ihtiyaç var: İndirilenler, Masaüstü ve Belgeler'de biriken tekrar indirilmiş DMG/PDF ve yedek kopyalar. Bu kullanım, ölçümde yeterli grup çıkarsa anlamlı.
- PLAN'da Faz 2'nin diğer açık maddeleri (sahipsiz artıklar, uygulama güncelleyici, LaunchAgent aç/kapat) bu özelliğe göre daha az riskli ve daha belirgin değer sunabilir. Kopya bulucu bu maddelerin önüne, ölçüm değeri kanıtladığı sürece geçebilir.
- "Yer kazanılır" dili kullanılırsa özellik rakiplerle aynı abartı hatasına düşer ve Keel'in dürüstlük konumunu zayıflatır. Bu nedenle kazanç yalnızca "en fazla" ve klon uyarısıyla gösterilmeli.
- Akıllı Tarama ve Keel AI entegrasyonu ürün açısından çekici görünse de ilk sürüm için kapsam dışı kalmalı. Otomatik seçimli bir "tek tık" akışı, dürüst konumlandırmayla çelişir.
KOŞULLAR:
- Adım 0 ölçümü yapılır: kullanıcının ev klasöründe (iCloud Drive kapalı ve açık iki durumda) 1 MB üstü gerçek kopya grupları, toplam "en fazla" kazanç ve tarama süresi ölçülür. Önerilen eşik: ayrışmış kopyalarda 1 GB üstü ve birkaç yüz grup gibi kayda değer bir sonuç. Eşiği mahkeme netleştirir. Sonuç bu eşiğin altındaysa madde "yapılmayacak" olarak kapatılır.
- Arayüz ve pazarlama metninde "kazanılır" ya da kesin GB iddiası yer almaz. Her kazanç gösteriminde klon uyarısı bulunur. Bu, ürün kopyasının doğrulanabilir olması için şarttır.
- İlk sürüm yalnızca İndirilenler, Masaüstü, Belgeler ve ev kökünde çalışır. Uygulama verisi, harici disk, benzer görsel ve Akıllı Tarama/Keel AI kapsam dışıdır. Bu kapsam değişikliği ayrı mahkeme kararı ister.
- iCloud/bulut yer tutucu dosyaları taramada atlanır ve bu davranış testle doğrulanır. Bu, dava dosyasındaki güvenlik itirazını da karşılar.
- Mahkeme, PLAN Faz 2'deki diğer açık maddelerle önceliği karşılaştırır ve kopya bulucunun önceliğini yazılı olarak kararlaştırır. Kullanıcının tercihi bilinmediğinden bu karar belgelenmeden kodlamaya geçilmez.
