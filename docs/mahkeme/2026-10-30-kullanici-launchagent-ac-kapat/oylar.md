# Jüri oyları

## juri-guvenlik

JÜRİ: Güvenlik uzmanı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Bu iş silme yapmıyor, plist'e dokunmuyor, yeni yetki ya da ağ yüzeyi açmıyor. Savunmanın önerisi (ayrı `LaunchActionLog`, `.user` script testi, uyarı metni, dürüst PLAN notu) güvenlik yüzeyini küçültür, büyütmez. Bu yüzden RED için gerekçe yok.
- Veto vermiyorum. §2.7 ("her işlem kaydedilir") aç/kapatı kapsıyor mu belirsiz. Metnin kendisini okumadım, yalnızca dosyadaki alıntılara baktım. Savunma kapsıyor varsayıp kayıt ekliyor, bu güvenli yöndeki yorum. §2.3 dosya yolları için yazılmış. §2.8 için `.system` yönetici yolu bu davadan önce birleşmiş, bu öneri onu genişletmiyor. Gerçek ihlal yok, "riskli" olan şeyler var.
- Savunmanın ayrı günlük dosyası kararı doğru. `ActionLog.Entry` silme geri-al okuyucularına bağlı. Onu genişletmek, geri alma yolunu (güvenlik açısından en hassas yol) riske atardı. Ayrı biçim bu riski kaldırır.
- İddianamenin en güçlü noktaları: (1) yasak listesi koruması (`com.apple.` ve karakter süzgeci) antivirüs, VPN, yedekleme, MDM ve Keel'in kendi ajanını korumuyor. Tek tıkla kapanabiliyor ve kullanıcı korumanın düştüğünü fark etmeyebilir. (2) `.system` kapsamı tek root isteminde toplanıyor ve ortada allowlist yok. Bunlar bu davada çözülmüyor. Savunma da bunu sahibe bırakıyor. Bunu kabul edilebilir buluyorum, ama açık risk olarak kayıtta kalmalı. Kapanış notu "güvenlik tamam" demesin.
- Savunmanın "tek tıkla anahtar yeterli, plist değişmiyor" argümanı çalışan süreç öldürülene kadar geçerli. `bootout` yarım kalan senkron, yedekleme ya da yazdırma işini bozabilir. Metin uyarısı bunu ancak kısmen kapatır. Yeni bir onay penceresi gerektirecek kadar ağır bulmuyorum, çünkü işlem tersine çevrilebilir ve görünür.
- Günlük kendi başına yeni bir veri riski doğurabilir. Etiket ve kapsam kullanıcının kurduğu yazılımları ifşa eder. Dosya yerelde kalırsa sorun yok. Keel AI bağlamına (`KeelTools`) ya da herhangi bir dışarı gönderime girerse "dosya içeriği asla gönderilmez" ruhuna yaklaşır. Bu yüzden aşağıdaki koşul gerekli.
- Doğrulanmamış macOS davranışları (`enable` ile `Disabled=true`, Background Items ilişkisi) yanlış durum gösterme riski taşıyor. Güvenlik açısından asıl sorun, kullanıcının "kapalı" sanıp kapatamadığı bir korumayı ya da tersini yanlış anlaması. Savunma bunu "doğrulanmadı" diye açıkça kayda geçiriyor. Bu yeterli olur, ama koşullara bağlıyorum.
- Çift etiketli plist: override etikete, bootstrap satırın yoluna bağlı. Etkisi düşük-orta ve geri alınabilir. Karakterizasyon testi sabitler, davranışı değiştirmez. Kabul.
- `swift test` ve gerçek Mac doğrulaması hiç yapılmadı. Bu davada ikisine de güvenemem.
KOŞULLAR:
- Günlük yalnızca metadata içerir: tarih, etiket, kapsam, eylem, sonuç, kısa `detail`. Plist içeriği, komut dizesinin ham halinin tamamı ya da dosya içeriği yazılmaz. `detail` içindeki ham launchctl çıktısı kısaltılır (örn. en fazla 200 karakter) ve kullanıcı ev dizini yolu dışında yol içermez. Günlük dosyası ve içeriği Keel AI araçlarına, analitiğe ya da herhangi bir ağ çağrısına verilmez. Bunu gösteren bir test ya da grep kanıtı PR'a yazılır.
- Günlük yazma hatası işlemi iptal etmez ama `detail`'e düşer (savunmadaki gibi). `refused` sonuçları da kaydedilir ve bunu kanıtlayan KeelCore testi eklenir (Apple etiketi, geçersiz karakter).
- `.user` kapsamı için `script(...)` çıktısını sabitleyen test, `.allUsers` için "yalnızca bu oturumu etkiler" davranışını sabitleyen test ve çift-etiket karakterizasyon testi eklenir. Birleştirmeden önce `swift test --package-path Packages/KeelCore` gerçekten çalıştırılıp çıktısı PR'a konur. "Geçti" iddiası bunsuz yapılmaz.
- `ActionLog.Entry`, `Outcome`, `Removal` ve silme geri-al yoluna hiç dokunulmaz. PR diff'inde bu dosyaların değişmediği görülür. `SafetyPolicy`'e dokunulmaz, `refusal` gevşetilmez.
- `.system` yönetici yolu, `refusal` ve çalışan-süreç öldürme davranışı bu iş kapsamında değiştirilmez. Bu iş PR'da şu cümleyi taşır: "yasak-liste koruması ve .system root yolu §2.3/§2.8 ile uzlaştırılmadı, sahip kararına bırakıldı." PLAN notu da bunu açık madde olarak yazar. Kapanış notu "güvenlik tamam" ya da "Sistem Ayarları ile aynı" gibi doğrulanmamış vaat içermez.
- Arayüz metnine "Kapatınca çalışan süreç de durdurulur" eklenir. Mac doğrulaması yapılana kadar arayüz ve PLAN metni "yeniden başlatmada kapalı kalır" ya da "Sistem Ayarları'yla aynı" diye kesin konuşmaz. Ayrı `- [ ]` Mac doğrulama maddesi açılır (macOS sürümü, `.user` ajanı kapat, yeniden başlat, Sistem Ayarları görünümü, `Disabled=true` plist ile `enable`).
- Sahibe iki kısa soru iletilir ve cevapsız kalırsa kod ilerlemesi hakimin kararına bağlıdır. (1) §2.7 aç/kapatı kapsıyor mu? (2) Yasak-liste tabanlı `refusal` ve `.system` root yolu kabul edilebilir mi? Hakim `İNSAN ONAYI GEREKİR: EVET` derse kod yazılmaz.
- Seçenek E (SMAppService/BTM, `sfltool`) kapsam dışı kalır. Seçenek A tek başına yeterli değildir.

## juri-macos

JÜRİ: macOS sistem uzmanı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Teknik olarak mümkün: `launchctl enable/disable` (gui/<uid> alanı) ile `bootout/bootstrap` alt komutları güncel ve kararlı API'lerdir; eski `load/unload` yerine bunları kullanmak doğru tercih. `.user` kapsamı root gerektirmez. `.system` kapsamındaki `osascript ... with administrator privileges` public AppleScript standart eklentisidir, private API değildir.
- Savunmanın dayandığı iki varsayım (`enable` plist içindeki `Disabled=true` değerini geçersiz kılar; launchctl anahtarı Sistem Ayarları'ndakiyle aynı yolu kullanır) bu oturumda hiçbir kaynakla ya da Mac'te doğrulanmadı. Ben iddianamenin bu noktadaki tespitine katılıyorum. macOS 13'ten beri Giriş Öğeleri ve Arka Plan Öğeleri BTM veritabanıyla yönetilir; launchd'nin override veritabanıyla birebir senkron olduğu varsayılamaz. Sistem Ayarları "açık", launchctl "kapalı" (ya da tersi) gerçekçi bir senaryodur. Bu, kullanıcıya yanlış durum göstermek demektir.
- `bootout` çalışan süreci anında sonlandırır. Bu gerçek bir yan etkidir ve kullanıcıya bildirilmiyor. Arayüz metni bunu söylemiyor; bu eksik teknik olarak da düzeltilmelidir.
- Plist'e dokunulmadığı ve silme yapılmadığı için işlem tek bir `enable` ile geri alınabilir. Kod düzeyinde küçük bir değişiklik bu yüzden kabul edilebilir risk taşır.
- `.allUsers` (/Library/LaunchAgents) kapsamı gui/<uid> altında çalışır; yani sistem genelinde değil, yalnızca o oturumdaki kullanıcıyı etkiler. Arayüz metni bunu açıkça belirtmelidir.
- Ayrı `startup.log` önerisi teknik olarak sorun çıkarmaz; `ActionLog` biçimine dokunulmaması doğru karardır.
- `com.apple.` yasak listesi teknik olarak makul bir alt sınırdır, ama Keel'in kendi ajanı ya da güvenlik/VPN/MDM ajanları da kapatılabilir. MDM kaynaklı ajanlar kapatıldıktan sonra bir sonraki politika senkronizasyonunda yeniden yüklenebilir; bu, kullanıcıyı yanıltabilir. Ürün ve politika tarafı diğer jürilere bırakılmıştır.
- Doğrulanmamış macOS davranışı üzerine "tamamlandı" işareti konmamalıdır. Kod tarafı kabul edilebilir, cihaz doğrulaması açık kalmalıdır.
KOŞULLAR:
- En az bir macOS 13+ sürümünde elle doğrulama yapılacak: `.user` kapsamlı bir ajan kapatılır, yeniden başlatılır, süreç yokluğu (`launchctl print gui/<uid>/<label>`) ve Sistem Ayarları > Giriş Öğeleri görünümü karşılaştırılır, sonra açılıp aynı kontrol tekrarlanır. Sonuç PR açıklamasına ve PLAN'a yazılmadan satır 144 `[x]` yapılmaz.
- Doğrulamada Sistem Ayarları ile launchctl durumu uyuşmazsa arayüz metni "Sistem Ayarları'yla aynı" ya da benzeri bir vaatte bulunmaz; uyuşmazlık metinde açıkça anlatılır.
- Plist'te `Disabled=true` olan bir ajanın `enable` sonrası gerçekten yüklendiği en az bir kez Mac'te doğrulanır (`man launchctl` ile birlikte).
- `OptimizationView.swift:231` metnine "kapatınca çalışan süreç de durdurulur" uyarısı eklenir; `.allUsers` satırları için "yalnızca bu oturumu etkiler" ifadesi eklenir.
- `.user` için `script(...)` testi ve aynı etiketli çift plist karakterizasyon testi eklenir; `swift test --package-path Packages/KeelCore` bu ortamda çalıştırılamadığı için birleşmeden önce geçtiği gösterilir.
- Bu işte `.system` kapsamındaki yönetici yolu genişletilmez, yalnızca mevcut davranış korunur.

## juri-kullanici

JÜRİ: sıradan Mac kullanıcısı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Özellik bana yarar. Mac yavaşladığında hangi programların açılışta çalıştığını bir listede görüp kapatabilmek işime yarar. Dosyaya göre bu zaten kodda var ve Apple'ın kendi servisleri korunuyor, sistem servisleri için de yönetici şifresi isteniyor. Bu, korktuğum "rastgele bir şeyi bozarım" durumunu sınırlıyor.
- Anahtarın ne yaptığını tam anlamıyla bilmiyorum. Dosyaya göre kapatmak hem bir sonraki açılışta programı başlatmıyor, hem de o an çalışan programı hemen durduruyor. Arayüzdeki metin yalnızca "Mac yeniden başlasa da kapalı kalır" diyor, çalışan programın durduğunu söylemiyor. Bu eksik beni kandırır: bir senkronizasyon ya da yedekleme programını kapatıp yarım kalan işle karşılaşırım.
- Anahtar tek tıkla, onay sormadan uygulanıyor. Keel AI kartında onay istendiği için orada sorun yok, ama doğrudan anahtarda yanlış bir satıra tıklayıp bir programı durdurabilirim. Anahtar değişikliği geri alınabilir, bu iyi; yine de durdurma eylemi için bir onay adımı beklerim.
- Bilmediğim bir program adını (güvenlik, VPN, yedekleme ya da kurum yönetim yazılımı olabilir) kapatmak, Mac'in korumasını sessizce düşürebilir. Yalnızca Apple ile başlayanların engellenmesi bana yetmiyor; bu tür programlar için en azından ek bir uyarı beklerim.
- Yaptığım değişiklikleri sonradan görmek istiyorum. "Bunu ne zaman kapattım?" sorusunun cevabı yoksa güvenmem zor. Dosyadaki günlük önerisi bu yüzden iyi, ama bu kaydın arayüzden okunabilir olması gerekir; sadece bir dosyaya yazılması bana yetmez.
- Dosya kendi itirafında, anahtarın Sistem Ayarları'yla aynı durumu gösterdiğini, enable'ın plist'teki kapalı ayarı geçersiz kıldığını ve Mac'te kapat-yeniden başlat döngüsünün doğrulanmadığını yazıyor. Bu doğrulanmadan arayüzün "doğru durumu gösteriyor" gibi bir izlenim vermesi beni yanıltır.
- Madde zaten büyük ölçüde yapılmış görünüyor; ben için sorun "yeni özellik" değil, mevcut özelliğin dürüst ve güvenli hâle getirilmesi. Bu yüzden tamamen reddetmiyorum, ama yalnızca kapanış notuyla da yetinmiyorum.
KOŞULLAR:
- Kapatma anahtarında, kapatmanın o an çalışan programı durduracağını söyleyen açık bir uyarı olmalı (dosyadaki "Arayüz metnine ekleme" önerisi bu koşulu karşılar).
- Güvenlik, VPN, yedekleme ve kurum yönetim programları gibi bilinen koruma ajanları için ek bir uyarı ya da onay adımı olmalı; yalnızca "com.apple." önekine bakan yasak listesi tek koruma olmamalı.
- Yapılan her aç/kapat işlemi tarih, program adı ve eylemle birlikte kaydedilmeli ve bu kayıt arayüzden (örneğin "son işlemler" listesi olarak) görülebilmeli.
- Belirtilen bir macOS sürümünde gerçek bir Mac'te doğrulama yapılmalı: bir ajanı kapat, yeniden başlat, programın çalışmadığını gör, Sistem Ayarları'ndaki Giriş Öğeleri görünümüyle karşılaştır, sonra aç ve tekrar kontrol et. Sonuç kaydedilmeden arayüzde "Sistem Ayarları ile aynıdır" gibi bir vaat yer almamalı.

## juri-muhendis

JÜRİ: kıdemli Swift mühendisi
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Satır 144'ü olduğu gibi kapatmak (Seçenek A) ya da hiçbir şey yapmamak (D) kabul edilemez. Mevcut aç/kapat yolu günlüksüz çalışıyor ve bu, PLAN §2.7 ile uyumsuz. Kayıt eksiği somut bir mühendislik açığı.
- Savunmanın önerdiği yön (Seçenek B'nin daraltılmış hâli) doğru. `ActionLog.Entry`'yi (Removal/path/bytes) değiştirmeyip ayrı bir Codable kayıt türü eklemek, geri al okuyucusu ve silme çağıranları riske atmaz. Yeni bağımlılık yok, yeni yetki yok.
- Mantık KeelCore'da olmalı (CLAUDE.md). Savunma "App/ yalnızca sonuçları verip yazar" diyor. Dosyaya ekleme (append) App'te kalırsa Linux'ta test edilemez ve kuralla çelişir. Biçimlendirme ve dosya yazımı KeelCore'da, hedef dosya yolu enjekte edilerek (geçici dizinle) testlenmeli.
- Kayıt yazımı eşzamanlılık açısından ele alınmalı. Birden fazla hızlı aç/kapat işlemi aynı dosyaya paralel yazabilir. Swift 6 strict concurrency altında tek bir actor ya da seri kuyruk ve Sendable kayıt türü gerekir. Savunma bu konuya değinmiyor.
- Test planı yerinde: `.user` için script() sabitleme testi, aynı etiketli iki plist karakterizasyon testi, reddedilen etiketin `refused` olarak kaydedildiği test. Bu üçü Linux'ta çalışır ve testsiz kalan en büyük boşluğu kapatır.
- Kayıt iki dosyaya bölünürse (actions.log ve startup.log) denetim izi parçalanır. Bu tek başına engel değil, ama PLAN'da hangi dosyanın hangi işlemi tuttuğu yazılmalı.
- Arayüz metni ve Mac doğrulaması: "kapatınca çalışan süreç durdurulur" uyarısı küçük ve doğru bir metin değişikliği. Mac doğrulama maddesinin ayrı `- [ ]` olarak eklenmesi dürüst bir kapanış sağlar. Bu konuların ürün/güvenlik boyutu diğer jürilerin alanı.
- Benim değerlendirmem yalnızca üç dosyadaki iddialara dayanıyor. Kaynak kodu (LaunchControl.swift, SystemControl.swift vb.) bu talimat kapsamında okumadım; dosyadaki satır referansları ve testlerin varlığı doğrulanmadı. `swift test` bu ortamda çalıştırılamadı.
KOŞULLAR:
- Kayıt üretimi ve dosyaya yazma KeelCore'da olacak (yeni dosya, örn. Startup/LaunchActionLog.swift). Hedef dosya yolu parametre olarak alınacak ve yazma testi geçici dizinde Linux'ta çalışacak. App/ yalnızca bu API'yi çağıracak.
- Yazıcı bir actor (ya da seri kuyruk) olacak; kayıt türü Sendable olacak. Swift 6 strict concurrency uyarısı olmadan derlenmeli. Hızlı ardışık işlemlerde satır kaybı ya da karışması olmayacak şekilde bir test eklenecek.
- ActionLog.Entry ve actions.log okuyucularına dokunulmayacak (mevcut testler değişmeden geçecek).
- Testler eklenecek: .user kapsamı script() sabitleme, aynı etiketli iki plist karakterizasyonu, refused kaydı. `swift test --package-path Packages/KeelCore` geçmeden birleşme olmayacak (CI ya da Mac çıktısı ile kanıtlanacak).
- PLAN'a iki günlük dosyasının rolü (hangisi hangi işlemi tutar) tek satırla yazılacak. Yazma hatası işlemi iptal etmeyecek, ama detail alanına düşecek.
- Satır 144 "[x]" yapılırken "Mac doğrulaması açık" ayrı bir `- [ ]` maddesi olarak eklenecek; kod tarafı tamam, cihaz doğrulaması açık diye not düşülecek.

## juri-urun

JÜRİ: ürün yöneticisi ve rakip analisti
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Satır 144 yeni bir özellik değil. Dava dosyasına göre listeleme, aç/kapat anahtarı, Keel AI kartı ve geri alma zaten var ve PLAN'da [x] işaretli. Bunu yeniden geliştirme olarak yürütmek, aynı işi iki kez satmak olur. Maddenin kapanış işi olarak ele alınması doğru.
- Rakip açısından bu bir farklılaşma değil, eşitleme. Dosyanın verdiğine göre CleanMyMac aynı tür ajan yönetimini sunuyor, Stats yapmıyor. Dosya rakip bilgisini kaynakla doğrulamamış. Keel'in farkı, ancak anahtarın doğru durumu göstermesi ve Keel AI kartının onayla ve geri alınabilir çalışması olabilir. Bu da doğrulanmadan bir fark sayılmaz.
- Ürün güveni için en önemli açık, yeni kayıt ya da yeni kod değil, doğrulanmamış vaatlerdir: "Sistem Ayarları ile aynı yol", "enable plist'teki Disabled=true'yu ezer", "yeniden başlasa da kapalı kalır". Kullanıcı anahtarı kapattığında yanlış durum görürse güven kaybı yaşanır. Bu yüzden önce Mac'te elle doğrulama gerekir.
- Çalışan süreci öldüren bootout davranışı arayüzde söylenmiyor. Bu ürün metni eksiğidir ve tek cümleyle düzelir. Dosyadaki öneriyle aynı yönde.
- İşlem günlüğü (§2.7) kullanıcıya görünür bir "ne zaman kapattım" geçmişi olmadıkça yalnızca hata ayıklama değeri taşır. Ürün değeri orta-düşük. İlkeyle uyum açısından küçük ve geri alınabilir olduğu sürece makul, ama acil değil.
- Dosya bu maddenin Faz 2 içinde hangi önceliğe sahip olduğunu karşılaştırmıyor. Önceki iki dava öncelik sorusunu insana bırakmış ve cevap boş. Ürün önceliğine bu jüri karar veremez; sahip cevabı olmadan yeni iş başlatılmamalı.
- Ben kodu doğrulamadım, yalnızca üç dosyayı okudum. Oyum dosyadaki teknik iddialara dayanıyor; bu yüzden güven 3.
KOŞULLAR:
- Satır 144 "yeni geliştirme" olarak değil, mevcut işin kapanışı olarak ele alınır. PLAN'a "kod tarafı tamam, cihaz doğrulaması açık" notu ve ayrı bir "- [ ]" Mac doğrulama maddesi eklenir.
- Mac doğrulaması tamamlanmadan arayüz metni "Sistem Ayarları ile aynı" ya da "kapalı kalır" gibi kesin vaatler içermez. Test senaryosu: bir .user ajanını kapat, yeniden başlat, çalıştığını ve Sistem Ayarları'ndaki durumu kontrol et, aç, tekrar kontrol et. macOS sürümü kaydedilir.
- OptimizationView.swift:231 metnine "Kapatınca çalışan süreç de durdurulur" benzeri bir cümle eklenir.
- İşlem günlüğü eklenecekse kayıt başına tek satır, ayrı dosyada ve kullanıcının görebileceği bir yerde (en az "son değişiklikler" listesi) kullanılır. Yalnızca gizli bir log dosyası olarak kalacaksa ürün kazanımı yoktur ve bu iş ertelenir.
- Sahip, satır 144'ten beklediğini (Bilinmeyen 1) yazılı olarak cevaplar. Cevap gelmeden yeni kod yazılmaz.
- Rakip iddiaları (CleanMyMac, Stats, AppCleaner) kaynakla doğrulanmadan PLAN ya da arayüz metninde "rakiplerden farklı" denmez.
