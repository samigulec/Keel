# Jüri oyları

JÜRİ: Güvenlik uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- PLAN §2'nin hiçbir maddesi çiğnenmiyor. Savunmanın önerdiği sürüm yalnızca tespit yapıyor. Silme yok, `.app` içine veya üzerine yazma yok, root yok, entitlement değişikliği yok. Veto için gerçek bir ihlal yok. Seçenek D açık ihlal olurdu (§2.4, §2.6, §2.8, `SafetyPolicy`'de tanımsız eylem). Savunma da D'yi kapsam dışı bırakıyor, ben de D'ye RED veriyorum.
- Asıl güvenlik riski, kullanıcının kurulu uygulama listesinin ağa sızması. Her sorgu IP ile birlikte hangi uygulamanın kurulu olduğunu satıcı sunucularına bildirir. Bu, geri alınamayan tek risk. Önlemler yalnızca "varsayılan kapalı, açık onay, yalnızca düğmeyle" olarak kalırsa yetmez. Onay ekranının sunucuları ve gidecek bilgiyi gerçekten göstermesi ve bunun testle sabitlenmesi gerekir.
- `SUFeedURL` güvenilmeyen bir girdi, çünkü başka bir uygulamanın Info.plist'inden geliyor. Savunma yalnızca "http atlanır" diyor. İddianamenin SSRF itirazı yerinde. Kötü niyetli bir uygulama feed adresi olarak `https://127.0.0.1/...`, özel ağ adresi, `file:` veya yönlendirme zinciri verebilir. Bu, şema süzgecinin ötesinde somut bir kısıt gerektirir. Savunmada yönlendirme (redirect) takibi, boyut ve zaman aşımı sınırı, XML ayrıştırıcının dış varlık (XXE) ve genişleme (billion laughs) davranışı hiç geçmiyor. Bunlar güvenilmeyen uzak XML'i ayrıştıran kod için şart.
- "Rozet bağlantısı yalnızca satıcının alan adına açılır" iddiası belirsiz. Appcast içindeki `link` ve `enclosure` URL'si, feed'in alan adından farklı olabilir. Keel feed'den gelen bir URL'yi kullanıcıya açtırıyorsa bu kontrol edilmeli. Güvenli olan, feed'den gelen URL'yi açmamak veya açmadan önce alan adını kullanıcıya göstermek.
- §2.7: savunma, ağ kontrolünü `ActionLog`'a yazmayı yalnızca "öneriyorum" diye sunuyor. Veri dışarı çıkan bir işlem için bunu zorunlu görüyorum. Alan adı bazında kayıt, ağ sızıntısının tek denetim izi.
- Keel AI: savunma güncelleme sonucunu `get_installed_apps` çıktısına koymamayı ve bunu testle sabitlemeyi vaat ediyor. "Dosya içeriği asla gönderilmez" ve "yalnızca özet sistem verileri" ilkelerini korumak için bu şart, E reddedilmeli.
- Aşama 0 (ağsız, salt okunur Info.plist ve Caskroom ölçümü) güvenlik açısından zararsız. İnsan onayı beklemeden yapılabilir. Yalnızca dosya okuma yaptığından ve hiçbir şey göndermediğinden kabul ederim. Aşama 1 ise yeni ağ yüzeyi olduğu için insan kararı olmadan başlamamalı. Hem öncelik sorusu hem ağ gizliliği tercihi (Bilinmeyen 5) insanın.
- İddianamenin ağsız ölçüm ve doğrulanmamış şema itirazı güvenlik açısından da geçerli. Doğrulanmamış bir şemaya bakarak güvenilmeyen XML ayrıştıran kod yazmak risk. Ancak savunma bunu "ilk iş doğrulama" diye karşılıyor, makul.
KOŞULLAR:
- Aşama 0 yalnızca dosya okur, ağ kodu içermez. Önce yapılabilir. Aşama 1 (ağ) için insanın iki konuda açık onayı alınmadan kod yazılmaz: Faz 2 öncelik sorusu ve ağ kullanımı kabul edilebilir mi sorusu. Hakim "İNSAN ONAYI GEREKİR: EVET" demeli.
- Ağ varsayılan kapalı olacak. Kullanıcı açıkça açacak. İlk kullanımda hangi alan adlarına hangi bilginin gideceğini gösteren onay ekranı olacak. Arka plan veya zamanlanmış kontrol olmayacak, yalnızca kullanıcı düğmesiyle çalışacak.
- Feed URL'si doğrulama kuralları KeelCore'da saf fonksiyon olarak yazılacak ve Linux testleriyle sabitlenecek. Yalnızca `https` kabul edilir. `file:`, `localhost`, loopback, link-local, özel ağ (RFC1918) ve IP-literal adresler reddedilir. Yönlendirme takip edilirse her adım aynı kurallardan geçer, sayı sınırlıdır ya da hiç takip edilmez. Zaman aşımı, yanıt boyutu sınırı ve toplam istek / oran sınırı vardır. Testler bu vakaları içermelidir.
- XML ayrıştırıcı dış varlık ve DTD işlemeyi kapatır, boyut ve derinlik sınırı koyar. Bozuk, devasa ve XXE içeren girdilerle test edilir. Ayrıştırıcı kodlanmadan önce appcast şeması resmi belgeden doğrulanır, doğrulanamazsa yalnızca iyi bilinen alanlar okunur.
- Keel hiçbir dosya indirmez, hiçbir `.app` yoluna yazmaz. Feed'den gelen bir URL açılacaksa önce alan adı kullanıcıya gösterilir ya da yalnızca HTTPS ve uygulamanın feed alan adıyla eşleşen adres açılır. Bunlar testle sabitlenir.
- Giden istekler tanımlayıcı başlık veya kullanıcı kimliği taşımaz. Yalnızca standart başlıklar kullanılır. Bu, sahte istemcide başlıkları denetleyen testle sabitlenir.
- `ActionLog`'a her kontrol turu için "hangi alan adlarına, ne zaman, kaç istek" kaydı zorunlu yazılır (öneri değil, koşul). Uygulama adı ve sürüm listesi günlüğe tam olarak dökülmez.
- Güncelleme sonucu `get_installed_apps` ve diğer Keel AI araçlarının çıktısına girmez. Araç çıktı şemasında güncelleme alanı olmadığını doğrulayan bir test eklenir. E ayrı mahkemede ele alınır.
- Sparkle çerçevesi ya da başka bir dış bağımlılık eklenmez. Kurma (D) yoktur. İleride kurma istenirse `SafetyPolicy` yeni eylem türü, App Management izni ve Faz 3 ile ayrı mahkemede konuşulur.
- Arayüzde "kontrol edilemedi" durumu ayrıdır. Rozet yokluğu "güncel" yazılmaz. App Store uygulamaları yalnızca "App Store'u aç" bağlantısı alır.

---

JÜRİ: macOS sistem uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Salt okunur tespit (Seçenek B/C'nin tespit kısmı) public API'lerle yapılabilir: FileManager, PropertyListSerialization (Info.plist), URLSession (HTTPS), NSWorkspace (çalışan uygulama). Özel API ya da yeni entitlement gerekmez. Keel sandbox'sız olduğu için ağ çıkışı entitlement istemez; başka uygulamanın Info.plist'ini okumak da yazma izni gerektirmez.
- Sparkle tespiti yalnızca SUFeedURL anahtarına bakarsa eksik kalır. Kullanıcı tanımlı defaults ile feed geçersiz kılınabilir ve bazı uygulamalar feed'i kodda üretir. Sparkle.framework varlığına da bakılmalı. Dosyadaki "Sparkle = SUFeedURL veya framework" ayrımı doğru yönde ama uygulanmadı.
- Homebrew kısmı eksik tanımlı. Dosya yalnızca /opt/homebrew/Caskroom'a bakıyor; Intel Mac'lerde yol /usr/local/Caskroom. Caskroom kurulu sürümü verir, "güncel mi" için upstream sürüm gerekir. Bu ya formulae.brew.sh JSON API (ağ) ya da `brew outdated` (alt süreç, yeni yetki yüzeyi) demek. Dosya ikisini de seçmiyor.
- Appcast alanları (sparkle:version, sparkle:shortVersionString, sparkle:minimumSystemVersion, enclosure) benim bilgime göre bu adlarla. Sparkle karşılaştırmayı sparkle:version (build) üzerinden yapar, shortVersionString görünen metindir. Dosya bu alan adlarını doğrulamamış; doğrulanmadan kodlanırsa sessiz yanlış sonuç üretir.
- App Store: _MASReceipt yalnızca "App Store'dan geldi" der, sürüm bilgisi vermez. Güncelleme durumunu veren resmi bir API bilmiyorum; dosya da bunu çıkarım olarak işaretliyor. App Store'u kapsam dışı bırakıp "App Store'u aç" göstermek teknik olarak doğru.
- Seçenek D (Keel kurar) reddedilmeli. Başka bir .app'in içine yazmak macOS 13+ Uygulama Yönetimi (App Management) korumasına takılır; Keel'in sandbox'sız olması bunu kaldırmaz. /Applications altında root sahipli bundle'lar yönetici yetkisi ister. Bu iki engel, dosyanın §2.4/§2.6/§2.8 itirazını teknik olarak da destekliyor.
- Ağ güvenliği: dosyadaki "tanımlayıcı başlık eklenmez" savunması eksik. URLSession varsayılanı User-Agent'a (CFNetwork ve işletim sistemi sürümü) ve paylaşımlı çerez deposuna sahiptir. Ephemeral oturum ve sabit User-Agent kullanılmazsa sistem bilgisi sızar.
- SSRF önlemi olarak "yerel/özel adres reddi" bir metin filtresiyle yapılamaz. DNS yeniden bağlama ve yönlendirmeler yüzünden çözümlenmiş IP, bağlantı anında kontrol edilmeli. Ayrıca HTTP feed'i ATS'ye bırakmak yerine kodda açıkça reddedilmeli; ATS ayarı App hedefinin Info.plist'inde doğrulanmalı (dosyada bu yok).
- Sparkle çerçevesini bağımlılık yapmama kararı teknik olarak doğru. CVE iddiası dosyada kaynaklı ama bu jüri onu bağımsız doğrulayamadı; karar yine de çerçeveyi almamak yönünde.
KOŞULLAR:
- Aşama 0 ölçümü macOS'ta gerçek /Applications üzerinde yapılır; hem /opt/homebrew/Caskroom hem /usr/local/Caskroom taranır; Sparkle tespiti SUFeedURL ile Sparkle.framework varlığını birlikte kullanır. Sonuç dağılımı PLAN satır 120'ye yazılır.
- Homebrew için "güncel mi" yöntemi kodlanmadan önce yazılı olarak seçilir. Alt süreç (`brew`) seçilirse ayrı mahkeme gerekir; JSON API seçilirse uç nokta ve ağ davranışı belgelenir.
- Appcast alan adları ve karşılaştırma kuralı (sparkle:version ile CFBundleVersion, görünen sürüm değil) resmi Sparkle belgesinden doğrulanır. Doğrulanmadan ayrıştırıcı yazılmaz; sınır testleri (1.9 / 1.10, build-sürüm uyuşmazlığı) Linux'ta saf KeelCore'da yazılır.
- Feed istekleri ephemeral URLSession ile yapılır, çerez kullanılmaz, User-Agent sabittir (işletim sistemi sürümü ve CFNetwork varsayılanı yok); yönlendirme sayısı sınırlıdır; her adımda HTTPS zorunlu ve hedef IP çözümlenip yerel/özel aralıklar bağlantı anında reddedilir. Bu davranış sahte istemcide ve macOS'ta ayrıca test edilir.
- HTTP feed kodda açıkça reddedilir; App hedefindeki ATS ayarları incelenip belgelenir.
- Hiçbir .app yoluna yazma kodu eklenmez. Kurma (Seçenek D) için App Management izni ve yönetici yetkisi gerekliliği macOS'ta ayrıca doğrulanmadan Faz 3'e ya da yeni bir mahkemeye taşınmaz.
- Bu oy yalnızca teknik uygunluk içindir. Faz 2 öncelik sorusu ve ağ varsayılanı gibi insan kararları bu oyla kapanmış sayılmaz.

---

JÜRİ: sıradan Mac kullanıcısı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Mac'imin yavaşlamasından ve diskimin dolmasından şikayet ediyorum. Uygulamalarımın eski olup olmadığını görmek isterim, çünkü eski uygulamanın güvenlik açığı olabileceğini duydum. Bu yüzden "hangi uygulamam eski" bilgisi bana gerçekten yararlı.
- Dosyaya göre önerilen özellik kurulum yapmıyor, yalnızca bakıyor ve bana bir bilgi veriyor. Bu, benim için "beni bir şeye zorlamadan" bir yardım. Kendi kendine bir şeyi silmemesi, üzerine yazmaması da iyi.
- Ancak bence en büyük sorun şu: Uygulama listemin bir kısmını bu özellik kontrol edebilecek, geri kalanını edemeyecek. Dosyada bu oranın hiç ölçülmediği yazıyor. Eğer çoğu uygulamam "kontrol edilemedi" çıkarsa ve yalnızca birkaçı için "güncel" yazarsa, bu bana yanlış bir güven verir. Bir uygulamanın rozeti yoksa onun güncel olduğunu sanarım.
- Uygulama listemin satıcı sitelerine gönderileceği fikri beni rahatsız ediyor. Bilgisayarımda hangi uygulamaların olduğunu bilmelerini istemem. Dosya bunun bir "dışarı veri akışı" olduğunu ve bunun Keel'in "internete çıkmayan temizlik uygulaması" imajıyla çeliştiğini belirtiyor. Bunu açıkça bilmek isterim.
- Savunmada önerilen varsayılan kapalı ağ kontrolü, açık onay ve "bu siteye şu bilgiler gider" uyarısı bana yeterli görünüyor. Bu güvence olmadan özellik beni korkuturdu.
- Sözlüğe ve teknik kavramlara (Sparkle, Homebrew, CVE, imza) girmiyorum. Bunları doğrulamak uzman jürilerin işi. Ben yalnızca kullanıcı deneyimine ve güvenine bakıyorum.
- Mac App Store uygulamalarının durumu belirsiz. Bu uygulamalar için yalnızca "App Store'u aç" bağlantısı olması, yanlış bilgi vermekten iyidir.
KOŞULLAR:
- Ağ kontrolü varsayılan olarak kapalı olmalı. Kullanıcı açıkça açmalı; arka planda otomatik kontrol olmamalı.
- Açmadan önce ekranda hangi sitelere hangi bilginin (uygulama adı ve sürüm) gideceği açıkça yazmalı.
- Ölçüm yapılmalı: Ağa çıkmadan, yalnızca uygulamaların kendi bilgi dosyalarını okuyarak, kaç uygulamanın kontrol edilebildiği ortaya konmalı. Kontrol edilebilen oran düşükse özellik yayımlanmamalı.
- Arayüzde "güncel" yalnızca kontrol edilebilen uygulamalar için yazmalı. Kontrol edilemeyenler ayrı bir grupta "kontrol edilemedi" olarak gösterilmeli; rozet yokluğu "güncel" anlamına gelmemeli.
- Keel güncellemeyi kendisi indirip kurmamalı; yalnızca bağlantı açmalı.
- Ağ kontrolü hangi sitelere gittiğini ve ne zaman yapıldığını kayıt olarak tutmalı; ben sonradan görebilmeliyim.
- Beta ve test sürümleri varsayılan olarak gösterilmemeli; Mac'imle uyumsuz sürümler "güncelleme var" olarak yazılmamalı.

---

JÜRİ: kıdemli Swift mühendisi
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Mimari uyumu var. Tespit ve appcast ayrıştırma KeelCore'da saf fonksiyon olarak yazılabilir, ekran rozeti App/Features/Applications'ta kalır. Savunmanın Aşama 1 dosya planı bu bölünmeye uyuyor.
- Yeni bağımlılık gerekmiyor. Appcast XML'i Foundation XMLParser ile okunabilir, Sparkle çerçevesi alınmadığı sürece PLAN §1 "sıfır bağımlılık" korunur. İddianamenin Sparkle CVE riski de bu yolla devre dışı kalır.
- Linux testi mümkün. Sürüm karşılaştırıcı ve XML ayrıştırıcı Linux'ta test edilir. AppInventory.standardRoots ve scan zaten kök dizinleri parametre olarak alıyor, bu da geçici dizinlerle (fixture) Linux testini mümkün kılıyor. Caskroom ve _MASReceipt gibi macOS'a özgü yollar bu enjeksiyonla test edilebilir hale gelir; ayrı bir #if os(macOS) dalına gerek kalmaz, yalnızca gerçek ağ ve Info.plist okumasının macOS'ta ayrıca sınanması gerekir.
- Mevcut HTTP soyutlaması doğrudan yeniden kullanılmamalı. ModelCatalog.swift'te HTTPClient protokolü public ve Sendable (satır 8-10), ama URLSessionHTTPClient'ın Linux dalı AIError.unsupportedPlatform fırlatıyor (satır 20). Güncelleyici bu tipi kullanırsa AI'ya bağlanır. Savunmanın ayrı bir hata türü ya da genel bir Networking protokolü önerisi doğru; bu bir ön koşul.
- Swift 6 eşzamanlılığı: kontrol async ve Sendable değer tipleriyle yazılmalı. Ağ çağrıları ApplicationsModel içinde MainActor dışında yapılmalı; scan ve read senkron dosya I/O yaptığı için de aynı şekilde ana iş parçacığından ayrılmalı. Paylaşılan değiştirilebilir durum olmamalı.
- Daha basit yol var. Homebrew kısmı için Caskroom okuyup yalnızca kurulu sürümü göstermek ağ gerektirmez; "brew upgrade --cask <ad>" metnini göstermek de Keel'e ek kod yükü getirmez. Ağ kodu yalnızca Sparkle için gerekir, kapsam buna göre daraltılabilir.
- Aşama 0 (ağsız dağılım ölçümü) ucuz ve Swift tarafında kolaydır: read() sonucuna kaynak sınıflandırması eklenir, UI yoktur. Bu adım ilerlemeden ağ kodu yazılmamalı; savunmanın bu sıralamasına katılıyorum.
- Bakım yükü gerçek. Tek geliştirici için her uygulama satıcısının appcast şeması ayrı bir uyum yükü. Doğrulanmamış şema (Bilinmeyen 4) kodlanmadan önce resmi belgeden teyit edilmeli; dosyanın bu konuda doğrulanmadığını ben de kabul ediyorum.
- Koşullar, iddianamedeki 1., 2. ve 9. koşullar ile savunmanın bu oy için yeterli olduğunu düşünüyorum. İnsan onayı (öncelik sorusu, ağ varsayılanı) bu oyun teknik değil, ürün kararı olduğunu kabul ediyorum.
KOŞULLAR:
- Aşama 0 uygulanır: yalnızca Info.plist ve Caskroom okuyan, ağsız, değer tipi bir dağılım raporu. Test: geçici dizinde sahte .app paketleriyle Linux'ta sınanır; kaynak sınıflandırması (sparkle/cask/appStore/other) tablo testiyle sabitlenir. Kapsam eşiğin altındaysa dur.
- Ağ katmanı AIError'dan ayrılır: genel bir taşıma hatası türü ya da güncelleyiciye özel hata türü tanımlanır; ModelCatalog ve AI testleri değişmeden geçer (mevcut testler Linux'ta çalıştırılır: swift test --package-path Packages/KeelCore).
- Appcast ayrıştırıcı ve sürüm karşılaştırıcı Foundation dışında bağımlılık kullanmaz; test seti 1.9 vs 1.10, CFBundleVersion uyuşmazlığı, boş ve bozuk XML, http:// feed, minimumSystemVersion ve beta kanalı durumlarını kapsar. Bu testler Linux'ta geçer.
- Ağ isteği yalnızca kullanıcı düğmesiyle ve varsayılan kapalı ayarla gönderilir; eşzamanlı istek sayısı ve zaman aşımı sınırlıdır. Bu üçü için ayrı birim testi yazılır.
- Ağ ve tarama işi ApplicationsModel'de MainActor dışında yürür; Swift 6 strict concurrency uyarısız derlenir.
- Keel AI araç şeması (get_installed_apps) değişmez; güncelleme alanı eklenmez (test ile sabitlenir).
- Entitlements, project.yml ve SafetyPolicy değişmez; hiçbir .app yoluna yazma yapılmaz.

---

JÜRİ: ürün yöneticisi ve rakip analisti
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Rekabet farkı zayıf. Dosyaya göre CleanMyMac Updater, MacUpdater ve Latest zaten benzer bir "güncelleme var mı" özelliği sunuyor. Keel'in bu özellikle öne çıkabileceği tek alan, rakiplerin yapmadığı dürüst kapsam beyanı ("kontrol edilemeyen N uygulama", "satıcının feed'ine göre" dili, ağ kontrolünün varsayılan kapalı olması). Bu fark somut bir ürün vaadine dönüşmezse özellik kopyalama olarak okunur.
- Kapsam ölçülmedi. Kullanıcının uygulamalarının kaçının Sparkle, Homebrew ya da App Store kullandığı bilinmiyor. Savunmanın Aşama 0 önerisi (Info.plist ve Caskroom okuyan, ağa çıkmayan salt okunur ölçüm) ucuz, geri alınabilir ve ürün kararı için gerekli veriyi verir. İddianamenin "önce ölçüm" talebine katılıyorum.
- Yanlış güven riski ürünün kendi itibarına zarar verir. Bir temizlik uygulaması "güncel" demeyi yanlış söylerse kullanıcı güvenini kaybeder. Kapsam düşükse özellik değer üretmez, yalnızca yanlış rozet üretir. Bu yüzden başarı ölçütü baştan tanımlanmalı.
- Yol haritası sırası cevapsız. GUNDEM'deki "Faz 2 maddelerinden hangisi önce?" sorusu hâlâ açık. Bu özelliğin diğer Faz 2 işlerinin önüne geçmesi için insan kararı gerekir. Ürün tarafında bu olmadan "şimdi yapılmalı" diyemem.
- Bakım maliyeti yüksek. Tek geliştirici için çoklu kaynak (Sparkle, Cask, App Store) ve her birinin kırılgan uç noktası sürekli iş demek. Latest'in boş zamanda geliştirilmesi bu maliyetin gerçek olduğunu gösteriyor. Bu yüzden App Store kapsam dışı başlamalı ve Sparkle ile sınırlı ilk sürüm tercih edilmeli.
- Seçenek D (Keel'in kendisi kurması) ürün açısından da yanlış: yönetici yetkisi, geri alma ve çalışan uygulamayı kapatma riski, kullanıcı değerinden büyük. Reddediyorum.
- Dava dosyasındaki rakip bilgilerinin bir kısmı doğrulanmamış (App Store güncelleme kaynağı, MacUpdater'ın çalışma biçimi). Bu nedenle rakip karşılaştırması tam değil. Karar, doğrulanmış kısma (Latest, CleanMyMac'in kurulamayanlar için bilgi simgesi yaklaşımı, Homebrew livecheck) dayanmalı.
KOŞULLAR:
- Aşama 0 ölçümü yapılır: yalnızca Info.plist ve /opt/homebrew/Caskroom okunur, ağ yoktur. Sonuçta Sparkle ya da Cask ile tespit edilebilen uygulamaların oranı insan tarafından belirlenecek bir eşiğin altındaysa özellik ertelenir (A). Eşik önerisi: kullanıcının üçüncü taraf uygulamalarının en az yarısı kontrol edilebilir olmalı.
- Ölçüm sonucu PLAN.md satır 120'ye yazılır ve İNSAN, Faz 2 öncelik sorusunu cevaplar. Cevap gelmeden Aşama 1 kod yazılmaz.
- İlk sürüm Sparkle ile sınırlıdır. App Store için yalnızca "App Store'u aç" bağlantısı gösterilir, sürüm kontrolü yapılmaz. Homebrew için yalnızca komut gösterilir, Keel çalıştırmaz.
- Ağ kontrolü varsayılan kapalıdır, kullanıcı açıkça etkinleştirir, arayüz hangi alan adlarına hangi bilginin gideceğini söyler ve yalnızca düğmeyle çalışır (arka plan yok).
- Arayüzde "güncel" ifadesi yalnızca kontrol edilebilen uygulamalar için kullanılır. Kontrol edilemeyen uygulamalar ayrı bir grupta "kontrol edilemedi" olarak listelenir.
- Sonuç Keel AI'ya gönderilmez. Bu davada E seçeneği kapsam dışıdır.
- Başarı ölçütü baştan yazılır: örneğin ilk sürümden sonra "güncelleme var" bildirimlerinin yanlış pozitif oranını ölçen bir kullanıcı geri bildirim kanalı ve ayrıca yanlış pozitif bulunursa özelliğin kapatılması kararı.
