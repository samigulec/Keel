# Jüri oyları

JÜRİ: Güvenlik uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- PLAN.md §2'nin 8 maddesini tek tek kontrol ettim. Savunmanın daraltılmış B kapsamı hiçbirini çiğnemiyor. İş salt okunur: silme yok (§1, §2, §3), yeni yol yok (§4, §5), çalışan uygulama önbelleği yok (§6), root yok (§8). Yeni işlem kaydı gerektirecek bir eylem de yok (§7). Bu yüzden veto kullanmıyorum.
- C (simgede canlı grafik) güvenlik açısından da ayrı karar gerektirir. Güvenliği doğrudan çiğnemiyor. Ama simge notch'ta gizlenirse kullanıcı "Çıkış" ve "Keel'i aç" düğmelerine ulaşamaz. Bu bir erişilebilirlik ve kontrol kaybı riski. İddianamenin 3. riskine bu yönüyle katılıyorum. C bu davanın dışında kalmalı.
- Dava dosyasındaki dosya yollarını ve satır numaralarını kodda yeniden açıp doğrulamadım. Kararım dosyadaki aktarımlara ve PLAN §2 metnine dayanıyor. Aşağıdaki koşulların hepsi buna göre yazıldı.
- Keel AI veri akışı bu davada yok. Geçmiş dizileri ve grafik verisi cihazdan çıkmıyor. Bunun karara açıkça yazılmasını istiyorum, çünkü "dosya içeriği asla gönderilmez" kuralının yanına "ölçüm geçmişi de bu davada gönderilmez" notu gelecekte yanlış anlaşılmayı önler (PLAN satır 154).
- Swift Charts kullanılmayacağı savunmada açıkça yazılmış. Bağımlılık sorusu açılmıyor. Bu doğru.
- `SystemStatus.appending` mantığını `KeelCore`'a taşımak güvenlik açısından olumlu. Ama mevcut davranışı sabitleyen testler önce yazılmalı, taşıma sonra yapılmalı.
KOŞULLAR:
- Kapsam yalnızca B'dir. Simge statik kalır. Menü çubuğu etiketi, `ImageRenderer`, `KeelApp.swift`'teki `MenuBarExtra` etiketi ve `SystemStatus` döngü hızı bu işte değişmez. C için ayrı mahkeme gerekir. Ön koşulu Mac'te ölçüm, macOS 14 etiket davranışı ve notch kontrolüdür.
- Yeni okuma kaynağı, yeni okuyucu, yeni yol erişimi, yönetici yetkisi ve ağ çağrısı eklenmeyecek. Eklenirse bu karar geçersiz sayılır ve yeniden yargılanır (§8 ve root yok ilkesi korunur).
- Grafik verisi, geçmiş dizileri dahil, Keel AI'ya ya da herhangi bir dış yere gönderilmeyecek. Bu karar metnine açıkça yazılacak.
- Yeni bağımlılık eklenmeyecek, Swift Charts dahil. `Package.swift` ve `project.yml` değişmeyecek.
- Geçmiş kırpma mantığı `Packages/KeelCore`'a alınacak. `swift test --package-path Packages/KeelCore` ile şu Linux testleri geçecek: boş dizi, uzunluk sınırı, taşma, sıra korunumu, `historyLength` değişimi. Sabitleme testleri taşımadan önce ayrı commit'te yazılacak.
- Grafiğe `accessibilityHidden(true)` verilecek. Değer metni, "Keel'i aç" ve "Çıkış" düğmeleri olduğu gibi kalacak.
- Bellek geçmişi ve bellek grafiği bu işe girmeyecek. Girerse metrik olarak ham "kullanılan" değil baskı seçilecek ya da ayrı karar alınacak.
- Faz 2 öncelik sorusu insana ait olduğu için, karar "İNSAN ONAYI GEREKİR" notunu taşısın. Sahip onay vermeden kod yazılmasın (CLAUDE.md son kuralı).
- Enerji ve CPU maliyetinin ölçülmediği PR açıklamasına yazılacak. Sahip Mac'te doğrulayacak. Linux'ta bu ölçülemez ve iddia edilmeyecek.

---

JÜRİ: macOS sistem uzmanı
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Doğrulama: Kodda `SystemStatus.swift:9` (historyLength = 30), `:44` (2 sn interval), `:196-197` (appending), `PerformanceView.swift:154` (private struct Sparkline) ve `PLAN.md:122` (açık madde) dosyadaki atıflarla uyuşuyor. Tek küçük fark: `slowEvery = 15` satır 44'te değil, satır 46'da. Bu karara etkisi yok.
- Seçenek B (açılan pencerede mini grafik) teknik olarak mümkün ve risksiz. Swift Charts ya da özel API gerektirmiyor, mevcut `Sparkline` çubuk tabanlı çizim yeterli. Tamamen public SwiftUI ve macOS 14 üzerinde çalışır. Yeni ölçüm okuyucusu, root ya da ağ gerekmiyor. Güncellemeye karşı kırılganlığı düşük.
- Savunmanın en zayıf iddiası: "pencere kapalıyken çizim yapılmaz, enerji yükü artmaz". Bu, macOS'ta doğrulanmadan kabul edilmemeli. `MenuBarExtra(.window)` içeriği bir NSPanel içinde yaşar. `SystemStatus` 2 sn'de bir `@Observable` değer güncellediği için SwiftUI, pencere gizliyken de gövdeyi yeniden değerlendirebilir. Ayrıca macOS 14'te pencere görünürlüğünü SwiftUI tarafından public olarak bildiren bir binding olup olmadığı belgede kontrol edilmeli. Yoksa NSWindow görünürlük bildirimleri gerekebilir. Bu yüzden "kapalıyken çizilmez" iddiası Instruments (SwiftUI ve Time Profiler şablonları) ile görülmeden geçerli sayılmamalı.
- Bellek geçmişi için "kullanılan bellek" yanıltıcıdır (önbellek ve sıkıştırılmış bellek nedeniyle yüksek görünür). Bellek grafiği eklenirse metrik bellek baskısı olmalı. Baskı seviyesi `kern.memorystatus_vm_pressure_level` sysctl'i ya da `DispatchSource` memorypressure üzerinden public yoldan okunabilir. Bu yol macOS 14'te kullanılabilir olsa da Keel'in bugünkü okuyucularında yoktur ve doğrulanmadı. Bu nedenle bellek grafiği ilk aşamada eklenmemeli, baskı kaynağı ayrıca doğrulanmalı.
- Simge grafiği (C) teknik olarak bugün ölçülmemiş bir risk taşıyor. `MenuBarExtra` etiketi SwiftUI'den NSStatusItem'a rasterize edilir. Etikette `ImageRenderer` ile üretilen görüntü kullanmak macOS 13+ public API'si olsa da, tema (koyu/açık), template renderleme ve ölçek (Retina) davranışı sürüm bazında değişebilir. Ayrıca sürekli etiket güncellemesinin enerji maliyeti Keel'e özgü ölçülmedi. Notch'lu Mac'lerde menü çubuğu dolduğunda öğeler gizlenir (macOS'un bilinen davranışı). Simgenin genişlemesi Keel'e erişimi kesebilir. Bu konu ayrı mahkemeye bırakılmalı.
- Ölçüm döngüsü şu an pencere kapalıyken de 2 sn'de bir çalışıyor. B bu döngüyü değiştirmediği sürece yeni bir ek yük yaratmaz. Ama C'de bu maliyet görünür hâle gelir. Döngü hızını pencereye bağlamak ayrı bir karar olmalı ve Performans ekranının zaman eksenini bozacağı için B ile birlikte yapılmamalı.
- Sahip sorusu (Faz 2 önceliği) bir macOS teknik sorusu değil. Bu kısmı hakime ve sahibe bırakıyorum. Teknik açıdan B'nin uygulanması güvenli. Önceliğin verilmesi kararı ise insana ait.

KOŞULLAR:
- Kapsam yalnızca B olsun. Simge statik kalsın, `isInserted`, `Preference` ve `SettingsView` değişmesin. Simge grafiği (C) için ayrı mahkeme açılsın. Bu mahkemenin ön koşulu Mac'te ölçüm olsun: Activity Monitor "Energy Impact" ve Instruments ile etiket yeniden çizme maliyeti, `ImageRenderer` davranışı macOS 14 ve güncel sürümde, notch'lu ekranda genişlik.
- B'den önce (ya da PR'da) Mac'te bir ölçüm yapılsın: pencere kapalıyken `MenuBarContent` gövdesinin çağrılmadığı Instruments ile gösterilsin. Gösterilemezse grafik çizimi açık pencereye bağlanacak bir mekanizma (macOS 14'te doğrulanmış public yol ya da NSWindow görünürlük bildirimi) kurulsun. Ölçüm sonucu PR'da yazılsın. Ölçülmediyse "ölçülmedi" notu açıkça düşülsün.
- Geçmiş kırpma mantığı `KeelCore`'a alınsın ve Linux'ta testle birlikte gelsin: boş dizi, tam dolu, taşma, `historyLength` değişimi, sıra korunumu. Bu test olmadan PR birleşmesin. Davranışı sabitleyen testler taşımadan önce yazılsın.
- Bellek geçmişi bu aşamada eklenmesin. Eklenecekse metrik "bellek baskısı" olsun ve kaynağı (sysctl ya da memorypressure) macOS 14'te doğrulansın. Ham "kullanılan" etiketiyle eklenmesin.
- `SystemStatus` ölçüm döngüsünün aralığı ve eşzamanlılık kuralı (satır 66-79, 97-126) bu işte değiştirilmesin. Döngü hızı ayrı karar olsun.
- Swift Charts ya da yeni çerçeve eklenmesin. Mevcut `Sparkline` taşınsın, Performans ekranındaki beş kullanımın görsel karşılaştırması PR'da gösterilsin.
- Grafik `accessibilityHidden(true)` olsun ve değer metni (sayı) korunsun.
- Geçmiş verisi Keel AI'ya gönderilmesin. Bu davanın kapsamı dışında kalmalı ve karara açıkça yazılmalı.

---

JÜRİ: sıradan Mac kullanıcısı
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Keel'i Mac yavaşladığı için indirdim. Menü çubuğundaki simgeye baktığımda bir şeyin "canlı" olarak değişmesini isterim, ama bu benim için temel bir ihtiyaç değil. Bir ses ya da hız sıçraması olduğunda "ne oldu" sorusunun cevabını görmek istediğim anda, menüyü açıp küçük bir çizgi grafik görmek gerçekten işime yarar. Bu yüzden B (açılan pencerede mini grafik) makul bir fikir.
- B'de simge değişmediği için, sürekli titreyen ya da değişen bir şey görmem. Pencereyi açmadığımda bir şey olmuyor. Bu, sıradan kullanıcının kafasını karıştırmayan, korkutmayan bir değişiklik.
- C (menü çubuğu simgesinde canlı grafik) benim gözümde risk taşıyor. Bir bakım uygulamasının menü çubuğunda sürekli değişen bir şey olması dikkatimi dağıtır. Daha da önemlisi, "Keel beni yavaşlatıyor" diye düşünmeye başlarım. Dosyada Keel'in bu yükünün ölçülmediği yazıyor. Ölçülmemiş bir şeyi kullanıcıya sunmak güven kaybettirir.
- C'de bir de şu kaygı var: çentikli ekranlarda simge sığmazsa Keel'i menü çubuğundan hiç açamayabilirim. Bunu fark etmeden bir süre Keel'in kapandığını sanabilirim. Bu, sıradan biri için ciddi bir sorun.
- Bellek grafiği tehlikeli olabilir. Mac'imde bellek çoğu zaman "dolu" görünür, çünkü macOS boş belleği önbellekte tutar. Grafikte kullanılan bellek yüksek çıkarsa, "temizlemem lazım" diye panik yaparım. Bu yanıltıcı olur. Bellek grafiği eklenecekse ne anlama geldiği açıkça yazılmalı, ya da bu aşamada hiç eklenmemeli.
- Dosyada geçmiş verilerinin zaten toplandığı, yeni bir ölçüm gerekmediği yazıyor. Bu iyi bir haber: yeni bir yük eklemeden var olan veriyi göstermek mantıklı.
- Savunmanın "Keel bu alanda rakiplerle yarışmalı" kısmına katılmıyorum. Ben Keel'i temizlik için indirdim, grafik için değil. Ama B küçük olduğu için zararı az, ve bir kullanıcı olarak yine de "ne oldu" sorusunu yanıtladığı için faydası var.
- Teknik kısımları (Swift Charts bağımlılığı, kod satır numaraları, Linux testleri, enerji ölçümü) uzmanların işi. Bunlara karar vermiyorum. Ama benim açımdan şu şart: yeni bir sürekli yük ya da yeni bir ayar gerekiyorsa, bu ayrı bir karara bırakılmalı.
KOŞULLAR:
- Kapsam yalnızca B olsun: menü çubuğu simgesi statik kalsın, C bu karara dahil edilmesin ve ayrı bir mahkemeye bırakılsın. C için ön koşul, Mac'te gerçek bir ölçümle (Activity Monitor'de Keel'in Energy Impact ya da CPU değerinin pencere açıkken ve kapalıyken karşılaştırılması) ve çentikli ekranda simgenin görünürlüğünün kontrol edilmesi olsun.
- Menüyü açmadığım sürede Keel'in CPU kullanımı artmasın. Bu, pencere kapalıyken ek çizim ya da ek ölçüm yapılmadığı, PR'da ya da kısa bir ölçümle gösterilerek kanıtlansın.
- Bellek grafiği bu aşamada eklenmesin. Eklenecekse "kullanılan" yerine yanıltmayan bir metrik seçilsin (ör. bellek baskısı) ve grafikte ne anlama geldiği kısa bir yazıyla açıkça belirtilsin.
- Grafik yanında sayı da kalsın ve grafik bir sonucu değil yalnızca ek bilgi olarak görünsün. Ayrıca, grafiğin neyi gösterdiğini tek bakışta anlayabileceğim bir etiket (ör. "son 1 dakika") olsun.
- Performans ekranındaki grafikler ilk adımda bozulmasın; Sparkline taşınırken görsel kontrol yapılsın.
- Bu iş "canlı grafik" olarak adlandırılıp sahibinin Faz 2 önceliği belirsizken yapılmasın. Önceliği sahip onaylamadan kod yazılmasın (sıra sorusu insana ait).

---

JÜRİ: kıdemli Swift mühendisi
OY: KOŞULLU
GÜVEN: 4
VETO: HAYIR
GEREKÇE:
- Kod doğrulandı. `App/SystemStatus.swift` satır 35-42'de geçmiş dizileri var, satır 196-198'de `appending` `App/` içinde duruyor. Döngü satır 66-79'da, 2 sn aralıkla çalışıyor ve durdurma ya da pencere durumu kontrolü yok. `App/KeelApp.swift:68`'de `MenuBarExtra` statik SF Symbol ile kullanılıyor. `Sparkline` `App/Features/Performance/PerformanceView.swift:154`'te `private struct`. Dosyanın bu tespitleri doğru.
- B (açılan pencerede mini grafik) yeni ölçüm, yeni okuyucu, yeni bağımlılık, yeni ayar ve ağ gerektirmiyor. Salt okunur ve geri alınabilir. Savunmanın değer iddiası (zaten toplanan geçmiş verinin menüde kullanılmaması) kodla tutarlı. Bu kısımda iddianamenin "koşulsuz yapılmasın" itirazına katılmıyorum, ama koşul gerekli.
- C (simgede canlı grafik) bu davanın kapsamında olmamalı. Etiket güncelleme maliyeti Mac'te ölçülmedi, `ImageRenderer` ve macOS 14 etiket davranışı doğrulanmadı, notch riski açık. Savunmanın kendisi de C'yi dışarıda bırakıyor. Bu ayrım doğru.
- Mimari sorun var. CLAUDE.md "mantık KeelCore'da" diyor, ama `appending` App/ içinde ve Linux'ta test edilemiyor. B'ye geçmiş kırpma mantığını `KeelCore`'a almadan girmek, testsiz borcu büyütür. Bu nedenle `RollingHistory` (ya da serbest fonksiyon) `Packages/KeelCore` içine alınmalı ve Linux testleriyle birlikte gelmeli. Bu, B'nin ön koşuludur.
- Daha basit çözüm: Sparkline'ı taşımak yerine, `MenuBarContent` içinde kısa bir yatay çubuk görünümü de yeterli olabilir. Ama Performans ekranı zaten `Sparkline` kullanıyor ve tek bileşen tutmak bakım yükünü azaltır. Taşıma kabul edilebilir.
- Açık nokta: Savunma "pencere kapalıyken çizilmez" diyor, ama `MenuBarExtra(.window)` içeriğinin kapalıyken de bellekte ve güncellenir durumda kalıp kalmadığı doğrulanmadı. `SystemStatus` `@Observable` olduğundan, görünüm hiyerarşide kalıyorsa her 2 sn'de yeniden çizim sürebilir. Bu, B'nin "ek yük yok" iddiasını çürütebilir. Mac'te ölçülmeden bu iddia kabul edilmemeli.
- Bellek geçmişi için "kullanılan" ya da "baskı" sorusu cevapsız. Bu davada bellek grafiği eklenmemeli. Karar sonraya bırakılmalı.
- Faz 2 öncelik sorusu üç davada cevapsız. Bu, iddianamenin itirazı olarak geçerli. Ama B küçük ve geri alınabilir olduğu için öncelik sahibi onayına bağlı bir "hemen yapılabilir" notu ile ilerlenebilir. Sıra sorusu hakimin ve sahibin kararıdır, ben bunu teknik olarak çözemem.
KOŞULLAR:
- Kapsam yalnızca B'dir. Menü çubuğu simgesi (`KeelApp.swift:68`) statik kalır. C için ayrı mahkeme açılır ve Mac'te Activity Monitor/Instruments ile enerji ve CPU ölçümü, macOS 14 etiket davranışı ve notch kontrolü kararda şart koşulur.
- Geçmiş kırpma mantığı (`SystemStatus.appending`) `Packages/KeelCore` altına taşınır ve `swift test --package-path Packages/KeelCore` ile şu durumları kapsayan testler gelir: boş dizi, tam dolu dizi, taşma (suffix kırpma), `historyLength` değişimi, sıranın korunması. Taşıma ayrı bir commit olur ve davranışı değiştirmez.
- Ölçüm döngüsünün hızı (`SystemStatus.swift:44`, 66-79) bu işte değiştirilmez. Pencere durumuna bağlı hız ayarı ayrı karardır.
- `Sparkline` taşınırken Performans ekranının beş kullanımı (satır 341, 366, 469-470, 510-511, 548) yükseklik 56 pt ile aynı kalır. PR'da önce/sonra ekran görüntüsü ile gösterilir. Grafik `accessibilityHidden(true)` alır, değer metni okunmaya devam eder.
- Menü penceresinin kapalıyken yeniden çizim yapıp yapmadığı PR öncesinde Mac'te doğrulanır (Instruments, SwiftUI view body sayacı veya eşdeğeri). Yeniden çizim sürüyorsa, ya grafik yalnızca pencere açıkken takip edilir ya da B ertelenir. "Pencere kapalıyken ek yük yok" iddiası ölçülmeden PR açıklamasına yazılmaz.
- Bellek geçmişi bu aşamada eklenmez. Bellek grafiği yalnızca "baskı" gibi yanıltmayan bir metrik ve ayrı kararla gelir.
- Disk ve bellek satırları bu aşamada dışarıda kalır. Yalnızca CPU ve ağ (↓/↑) satırlarına grafik eklenir.
- Yeni bağımlılık (Swift Charts dahil), yeni `Preference`, yeni ayar anahtarı ve `project.yml` değişikliği yapılmaz. Geçmiş verisinin Keel AI'ya gönderilmesi bu kararın dışındadır.
- Faz 2 öncelik sorusu için sahip onayı alınır ya da karara "İNSAN ONAYI" notu eklenir. Hakim `İNSAN ONAYI GEREKİR: EVET` derse kod yazılmadan kullanıcıya sorulur.
- PR bir ajan tarafından birleştirilmez, varsayılan dala doğrudan gönderilmez.

---

JÜRİ: ürün yöneticisi ve rakip analisti
OY: KOŞULLU
GÜVEN: 3
VETO: HAYIR
GEREKÇE:
- Kod doğrulandı: `App/SystemStatus.swift` 35-42. satırlarda geçmiş dizileri var, `historyLength = 30` (satır 9). Geçmiş kırpma `Self.appending` (satır 196-197) `App/` içinde ve test edilmiyor. `PLAN.md:122` maddesi açık. Dosyanın bu ifadeleri doğru.
- Rekabet açısından: Stats ve iStat Menus menü çubuğu grafiklerini zaten sunuyor ve ücretsiz ya da olgun. Açılan pencerede mini grafik tek başına Keel'i ayırt etmez. Keel'in ayırt edici değeri güvenli temizlik, bu madde onu ilerletmiyor. Bu bir "eşitleme" özelliği, farklılaştırıcı değil.
- Dosyada kullanıcı talebine dair hiçbir kanıt yok. Ne destek talebi, ne kullanıcı araştırması, ne de "kullanıcı anlık sıçramayı görmek için Performans'a gidiyor" gözlemi var. Savunmadaki "kullanıcı tek tıkla görmek ister" iddiası varsayım. Bu yüzden erteleme (A) da makul bir sonuç.
- Faz 2 öncelik sorusu üç davadır cevapsız. Bu sıralama kararı sahibe ait, jüri yerine geçemez.
- Seçenek B'nin marjinal maliyeti düşük: veri zaten toplanıyor, ölçüm döngüsü değişmiyor, yeni bağımlılık yok, pencere kapalıyken çizim yok. Ayrıca `appending` mantığını KeelCore'a taşımak, mevcut testsiz borcu da kapatıyor. Bu, B'nin kendi başına değeri.
- Seçenek C'yi bu aşamada desteklemiyorum. Enerji maliyeti ölçülmedi, macOS 14'te etiket davranışı doğrulanmadı, notch riski açık. Pencere kapalıyken de 2 sn'de bir güncellenmesi bir bakım uygulaması için ürün açısından ters bir mesaj verir (Keel'in kendisi CPU yiyor). Dış kaynaklar (Control Center, Stats) bu riskin gerçek olabileceğini gösteriyor, bu yeterli bir gerekçe.
- Bellek grafiğini "kullanılan bellek" olarak eklemek yanıltıcı olabilir. Bu karar eklemeden önce verilmeli.

KOŞULLAR:
- Kapsam yalnızca Seçenek B: `MenuBarContent` içinde CPU ve ağ satırlarına Sparkline. Disk ve bellek bu aşamada eklenmez. Simge (C) bu kararın dışında, ayrı bir mahkeme ve Mac'te ölçüm (Activity Monitor/Instruments ile enerji ve CPU, macOS 14 etiket davranışı, notch kontrolü) olmadan açılmaz.
- Önce sahip Faz 2 sıralamasını yazılı olarak onaylar ya da B'yi "düşük öncelik, sahip onayı bekliyor" olarak PLAN'a işler. Onay gelmeden kod yazılmaz. Hakim bu noktada İNSAN ONAYI GEREKİR: EVET notu düşmelidir.
- Geçmiş kırpma mantığı önce `Packages/KeelCore` içine taşınır ve `swift test --package-path Packages/KeelCore` ile şu durumlar test edilir: boş dizi, tam dolu, taşma (historyLength aşımı), sıranın korunması. Bu test birleşmeden UI değişikliği birleşmez.
- Bellek geçmişi bu PR'a girmez. "Kullanılan" mı "baskı" mı kararı verilmeden eklenmez.
- `SystemStatus` ölçüm döngüsü ve hızları değişmez. Pencere durumuna göre hız ayarı ayrı karar.
- `Sparkline` taşınırken Performans ekranının beş kullanım yerinde (PerformanceView.swift satır 341, 366, 469-470, 510-511, 548) görsel karşılaştırma yapılır ve PR'a ekran görüntüsü eklenir. Görünüm değişmiyorsa yükseklik varsayılanı 56 pt kalır.
- PR açıklaması "Menü penceresi açıkken ek CPU ölçülmedi, sahip Mac'te doğrulasın" notunu taşır. Kapsam dışı maddeler (simge grafiği, hız ayarı, bellek geçmişi, Keel AI'ya geçmiş gönderimi) açıkça listelenir.
- Pazarlama dili "hafif ve güvenilir bakım" ile tutarlı olmalı. "Rakiplerden daha iyi menü çubuğu monitörü" gibi bir iddia kullanılmaz; gerekçe "son 60 saniyeyi tek tıkla görme" olarak kalır.
