## İddianame

### Ana itiraz
Özellik B kapsamıyla bile bu hâliyle yapılmamalı. Dava dosyasının kendi bulgusu, bu özelliğin vaadinin ("X GB kazanılır") APFS klonları yüzünden yanlış olabileceği. Bu, PLAN §3'te "uydurma sayı" diye reddedilen kalıbın aynısı. Üstüne kullanıcının tek kopyasını Çöp'e göndermeye yarayan bir yol geliyor ve bu yolun güvenliği şu an Linux'ta test edilemeyen bir karma katmanına, ölçülmemiş bir iCloud/bulut davranışına ve `LargeFileRemover` politikasının kopyalanmasına bağlı. Önce üç şey kanıtlanmalı: gerçek kazanç ölçülebiliyor mu, bulut dosyaları taramada indirilmiyor mu, silmeden hemen önce her iki tarafın içeriği byte düzeyinde doğrulanıyor mu. Bunlar yokken "orta" büyüklükte, 600-900 satırlık yeni bir silme yüzeyi açmak orantısız. Açık duran dört başka madde de var.

### Riskler
1. **Yanlış kazanç iddiası.** Klon blokları paylaşır, bu yüzden silince neredeyse hiç yer açılmaz. Dosya, klonu gerçek kopyadan ayırmanın resmî yolu olmadığını ve bunun doğrulanmadığını söylüyor. "En fazla X GB" ifadesi dürüst görünür ama pratikte yine de abartıdır. Kullanıcı 20 GB "kazanç" görür, 200 MB açılır, uygulamaya güveni biter. Olasılık: yüksek. Etki: orta. Geri alınabilir: evet (güven kaybı hariç).

2. **Bulut dosyaları, silme ve indirme.** Dosya "iCloud ve bulut dışarıda" diyor ama bunu somut bir kurala bağlamıyor. `LargeFileScanner` yalnızca `Library` ve gizli klasörleri atlıyor. iCloud "Masaüstü ve Belgeler" senkronu `~/Desktop` ve `~/Documents` altında çalışır, bu klasörler taranır. Dropbox, OneDrive gibi eski tip klasörler de ev klasöründe durur. Üç sonuç çıkar.
   - Bu klasörlerde karma almak, yalnızca bulutta duran (dataless) dosyaların indirilmesini tetikleyebilir. Bu, "tarama salt okunur" ilkesini (§2.2) pratikte bozar. Disk ve ağ da dolar.
   - Senkronlanan bir dosyayı Çöp'e taşımak, silmeyi diğer cihazlara yayar.
   - `packageExtensions` listesi sabit ve kısa (16 uzantı). `.pvm`, `.rtfd`, `.vmwarevm`, `.dtBase`, `.scriv` gibi paketler listede yok. Üretim sürümü `.skipsPackageDescendants` kullanıyor ama bu yalnızca dizin paket olarak işaretliyse çalışır. Bilinmeyen paketlerin içindeki aynı dosyalar (ör. iki VM'deki aynı disk parçaları) "kopya" diye sunulur. Paketin bir parçasını silmek paketi bozar.

   Olasılık: orta. Etki: yüksek. Geri alınabilir: kısmen. Çöp boşaltılmış ya da bulut tarafı silmeyi yaymışsa hayır.

3. **Silme anında doğrulama yetersiz.** Dosya "boyut ve karma hâlâ aynı mı" diyor, yani silmeden önce tam karmayı yeniden hesaplamak gerekiyor. Büyük dosyalarda bu pahalı olduğu için "kısmi karmayla geç" kısayolu cazip olacak. Daha önemli eksik, **hayatta kalacak kopyanın** da aynı anda doğrulanması gerektiği. Tarama ile onay arasında diğer kopya taşınmış, silinmiş ya da değişmişse, kullanıcının seçtiği son kopya silinir. "Her gruptan en az biri korunur" kuralı yalnızca arayüzde kalırsa yetmez. Bu kural `DuplicateRemover` içinde, silme anında, kopyanın varlığı ve içeriği yeniden okunarak zorlanmalı. Olasılık: orta. Etki: yüksek (tek kopyanın kaybı). Geri alınabilir: Çöp'ten evet. İki seçim sırayla silinirse ve Çöp boşaltılırsa hayır.

4. **Karma kütüphanesi ve Linux testi.** CryptoKit Linux'ta yok, swift-crypto yeni bağımlılık olur (§1 "mümkün olduğunca sıfır"). `#if os(macOS)` arkasına almak ise tam silme-güvenliği mantığını Linux CI'ın dışına iter. CLAUDE.md "mantık Linux'ta test edilebilir" diyor. Elle SHA yazmak da denetlenmesi gereken kriptografik kod demek. Hiçbiri denenmemiş. Basit alternatif ortada: karma yalnızca gruplama için kullanılır, silmeden önce byte byte karşılaştırma yapılır (dosyada da böyle belirtilmiş). Kriptografik güç gerekmez, çakışma sorunu da kalmaz. Olasılık: yüksek (karar şart). Etki: orta. Geri alınabilir: evet.

5. **Politika kopyalama.** B, `LargeFileRemover.policy` "mantığını" yeniden kullanıyor. `DuplicateRemover` bunu ya kopyalar ya da `LargeFileRemover`'a bağımlı olur. Kopyalanırsa korunan yol listesi iki yerde ayrışır (Bir tanesine `Applications` eklenir, ötekine eklenmez). Bu, "tek kapı" ilkesini (§2.3) pratikte zayıflatır. `SafetyPolicy` koduna dokunulmasa da, çağıran taraftaki politika yapılandırması güvenlik sınırıdır. Olasılık: orta. Etki: yüksek. Geri alınabilir: evet (hata fark edilirse).

6. **Kasıtlı kopyalar.** Aynı içerikli dosya çoğu zaman hatadır, bazen yedektir, bazen proje gereğidir (aynı SDK, aynı kaynak dosyası iki projede, sürüm kopyaları, "Yedek" klasörü). Aynı diskte tutulan yedeği silmek yedeği silmektir. "Orijinal" seçimi ürün kararı olarak açık bırakılmış. Otomatik seçim varsayılan olursa kullanıcı onaylar ama anlamaz. Olasılık: yüksek. Etki: orta. Geri alınabilir: Çöp'te evet.

7. **Metadata kaybı.** İçerik aynı olsa da Finder etiketleri, "Where from", karantina ve ACL alanları, tarihler ve genişletilmiş öznitelikler farklı olabilir. Silinen kopyanın metadatası kullanıcı açısından değerli olabilir. Dosya bundan hiç söz etmiyor. Olasılık: orta. Etki: düşük. Geri alınabilir: Çöp'te evet.

8. **Hard link ve aynı inode.** B'nin "tek sayılır" kuralı doğru yönde ama silme tarafı belirsiz. Aynı inode'un iki adından birini Çöp'e taşımak hiç yer açmaz ve diğer adı bırakır. Gruplamada aynı inode tek öğe sayılırsa kullanıcıya iki ad gösterilmeli mi, hiç gösterilmemeli mi? Tanımlı değil. Olasılık: düşük. Etki: düşük. Geri alınabilir: evet.

9. **Kapsam sızıntısı: Akıllı Tarama ve Keel AI.** `LargeFilesModel` `SmartCare.swift`, `KeelTools.swift` ve `AssistantModel.swift` içinde bağlı. Kopya bulucu aynı kalıpla Akıllı Tarama'ya girerse "tek tıkla bakım" içinde otomatik seçimli bir silme yolu doğar. §2.2 gereği buna izin verilmemeli. Keel AI aracı olarak eklenirse dosya yolları ve adları sağlayıcıya gider (içerik gitmez ama yollar hassas olabilir). Ayrıca kopya grup bilgisi (hangi iki dosyanın aynı olduğu) içerik hakkında bilgi sızdırır. İlk sürümde ikisi de kapsam dışı olmalı. Olasılık: orta. Etki: yüksek. Geri alınabilir: evet (kod geri çekilir, giden veri çekilemez).

10. **Tarama maliyeti ve izin istemleri.** Büyük ev klasöründe boyut gruplaması, sonra kısmi, sonra tam karma. Süre, bellek ve G/Ç ölçülmemiş. İlk taramada Belgeler, Masaüstü ve İndirilenler için art arda TCC istemleri çıkabilir ve kullanıcı bunu "Keel dosyalarımı karıştırıyor" diye okuyabilir. Dosya "doğrulanmadı" diyor. Olasılık: orta. Etki: düşük. Geri alınabilir: evet.

11. **Bakım yükü ve öncelik.** 4-6 dosya, 600-900 satır, 10-15 test, yalnızca Mac'te doğrulanabilen arayüz. Rakipler bu özelliği sunuyor diye değil, kullanıcı değeri ölçülmüş olduğu için yapılmalı. Dosya kullanıcıdaki gerçek kopya oranını ölçmemiş ("Bilinmeyenler" 1). Sahipsiz artıklar, uygulama güncelleyici ve LaunchAgent aç/kapat gibi açık maddeler daha az belirsiz ve daha az riskli. Olasılık: yüksek. Etki: orta. Geri alınabilir: evet.

### Pazarlıksız ilke ihlali
**Yok, ama iki ilke fiilen risk altında.**
- **§2.2 (tarama salt okunur):** Bulut/dataless dosyalarda karma almak içerik indirebilir (Risk 2). Kural açıkça tanımlanmazsa ihlal olur.
- **§2.3 (tek kapı `SafetyPolicy`):** `SafetyPolicy`'nin kendisi değişmiyor ama politika yapılandırması kopyalanırsa kapı ikiye bölünür (Risk 5). Ayrıca §2.2'nin "yalnızca seçilen öğeler" kuralı, "en az bir kopya korunur" invariantı silme anında kod içinde zorlanmazsa fiilen boşalır (Risk 3).

Karma, klon ve arayüz vaadiyle ilgili sorunlar ilke ihlali değil, "kullanıcıya yanlış güven" kategorisinde. PLAN'ın kendi ruhuna (§3 uydurma sayı, Faz 4 yarım yapılan koruma) ters.

### İtirazım hangi koşulda düşer
1. Kazanç sayısı ya hiç gösterilmez ya da ölçülebilir hâle getirilir (ör. klon/paylaşılan blok sorgusu doğrulanır). Gösterilirse metin "yer açılmayabilir (APFS klonları)" uyarısıyla birlikte olur, "kazanılır" asla yazmaz. Klon sorgusu çalışmıyorsa özellik kopyaları **yer kazancı** değil **düzen** aracı olarak sunulur.
2. Bulut kuralı koda yazılır ve testlenir: dataless/senkronlanan dosyalar (`.isUbiquitousItem`, `ubiquitousItemDownloadingStatus`) taramada atlanır ve karma için asla açılmaz. `~/Desktop` ve `~/Documents` iCloud senkronu açıkken ya tümden atlanır ya da kullanıcıya açıkça söylenir.
3. Silme anında, silinecek dosyanın **ve** grupta kalan en az bir kopyanın varlığı ile içeriği byte byte yeniden doğrulanır. Karşılaştırma `DuplicateRemover` içinde, çağıran arayüzden bağımsız yapılır. İhlalde işlem reddedilir ve test edilir. Hepsini seçme yolu yoktur. Otomatik "orijinal" seçimi varsayılan olarak yapılmaz.
4. Karma bağımlılıksız çözülür: boyut + kısmi karma gruplama için, son doğrulama byte byte. Ya da swift-crypto bu mahkemede ayrıca açıkça onaylanır. Tüm mantık Linux'ta test edilir.
5. Politika tek yerden gelir: `LargeFileRemover.policy` ortak bir yere çıkarılır ya da iki kullanıcı için aynı testler çalışır. Kopyalanan korunan yol listesi kabul edilmez.
6. Bilinmeyen paketleri hesaba katan kural eklenir (paket uzantısı listesine güvenmek yerine, bir klasörün `isPackage` değeri ya da `Info.plist` varlığı) ve `Library` dışında bile yinelenen pakete girilmez.
7. Akıllı Tarama'ya ve Keel AI'ya girmez. İlk sürüm yalnızca kendi ekranıyla çıkar. Bu iki entegrasyon ayrı mahkeme kararı ister.
8. Başlamadan önce kısa bir ölçüm yapılır: kullanıcının ev klasöründe 1 MB üstü gerçek kopya oranı ve süre. Sonuç anlamlı değilse A (ertelemek) seçilir.
9. Seçenek D (klonlama) ve C (geniş kapsam) bu mahkemede reddedilmeli. D, PLAN ile çelişiyor ve "İNSAN ONAYI GEREKİR" kapsamında.

Bu koşulların hepsi sağlanırsa B'ye karşı çıkmam. Bunlar olmadan B'ye de karşıyım.
