## Savunma

### Neden yapılmalı
Kopya bulucu, PLAN §5 Faz 2'de açık duran tek madde. Rakipler (Gemini 2, CleanMyMac) bu özelliği sunuyor, bu yüzden "CleanMyMac benzeri" bir uygulamada eksik duruyor. Kullanıcıya faydası şu: İndirilenler, Masaüstü ve Belgeler'de birikmiş aynı dosyaları (tekrar indirilen DMG ve PDF'ler, yedek kopyalar, video ve arşivler) görmek ve onayla Çöp'e taşımak. Altyapının neredeyse hepsi hazır. `LargeFileScanner` ve `LargeFileRemover` kalıbı, `SafetyPolicy`, `ActionLog` ve `TrashRestorer` yeniden kullanılır, yani yeni güvenlik yüzeyi açılmaz. Yeni olan tek parça içerik karşılaştırmadır. Bunu bağımlılık eklemeden yapmak mümkündür (aşağıda).

Kazancı abartmayacağım. Gerçek kopya oranı bu makinede ölçülmedi, APFS klonları yüzünden "X GB açılır" iddiası yanlış olabilir. Önerim bu iki sorunu ürünün dürüstlük kuralı hâline getirir.

### Önerdiğim versiyon
Seçenek B'nin daraltılmış hâli. C ve D'yi savunmuyorum. D, "Çöp'e taşı ve geri al" ilkesiyle çelişir ve karar insana aittir. C ise iCloud, Fotoğraflar ve harici disk yüzeyini açar.

**Adım 0: ölçüm (yarım gün, kod birleşmeden).**
- `DuplicateFinder` yalnızca okuma yapan bir çekirdek olarak yazılır ve gerçek ev klasöründe çalıştırılır.
- Kaç grup çıktığı, toplam "en fazla" boyut, tarama süresi ve bellek kullanımı ölçülür.
- Sonuç ihmal edilebilirse madde "yapılmayacak" notuyla kapatılır. Bu, Seçenek A'ya dürüst bir çıkış sağlar.

**Adım 1: tarama çekirdeği** (`Packages/KeelCore/Sources/KeelCore/Duplicates/DuplicateFinder.swift`)
- Kök kuralları `LargeFileScanner` ile aynıdır: `Library`, `Applications` ve `.Trash` atlanır; gizli dosyalar, paketler, sembolik linkler ve `standardProtectedRoots` dışarıda kalır.
- iCloud ve bulut yer tutucu dosyaları da dışarıda tutulur.
- Asgari boyut 1 MB'dır.
- Kademe: boyut, sonra ilk/son bloğun kısmi karşılaştırması, sonra tam bayt bayt karşılaştırma. Karma kitaplığı gerekmez. Böylece CryptoKit ve Linux sorunu ve swift-crypto bağımlılığı ortadan kalkar. Sıfır bağımlılık ilkesi (§1) ve Linux'ta `swift test` korunur.
- Aynı inode'a giden hard link'ler tek dosya sayılır.
- Aynı birimde olmayan dosyalar aynı gruba girmez.
- Gösterilen kazanç her zaman "en fazla ~X GB (klonlar yer açmayabilir)" biçimindedir. Kesin kazanç iddiası yoktur.

**Adım 2: silme** (`DuplicateRemover.swift`, `LargeFileRemover` kalıbı)
- Aynı `policy` ve aynı kontrol zinciri kullanılır: dosya var mı, `SafetyPolicy.evaluate`, sembolik link çözümü, normal dosya mı.
- Silmeden hemen önce yeniden doğrulama yapılır: boyut ve değişiklik tarihi aynı mı, kalan "koruyucu" kopya hâlâ var mı ve içeriği aynı mı.
- Sonra `FileRemover.moveToTrash`, `ActionLog` ve `TrashedItem` ile geri alma gelir.
- `SafetyPolicy` kodu değişmez.

**Adım 3: arayüz** (`App/Features/Duplicates/DuplicatesModel.swift` ve `DuplicatesView.swift`)
- `LargeFilesModel` fazları aynen kullanılır: idle, scanning, ready, removing, undo ve reveal.
- Değişen dosyalar: `RootView.swift`, `KeelApp.swift` ve sidebar.
- Hangi kopyanın korunacağı için varsayılan öneri vardır (en eski veya en kısa yol). Kullanıcı bunu grup başına değiştirebilir. Bu bir ürün kararı olduğundan mahkeme onaylamalıdır.

**Kapsam dışı (bu sürümde):** Keel AI aracı (`KeelTools`), SmartScan/SmartCare entegrasyonu, benzer görsel, harici diskler, uygulama verisi. İleride eklenirse AI'ya yalnızca yol ve ad gider, içerik gitmez.

Büyüklük: yaklaşık 4-6 dosya, 600-900 satır, 10-15 test.

### Bilinen riskler ve önlemleri
1. **Klonlar yüzünden "yer kazanılır" yanılgısı** → Kazanç yalnızca "en fazla" olarak gösterilir. Klon ayrımı için `ATTR_CMNEXT_*` / `fcntl` yolu Adım 0'da denenir. Çalışırsa kullanılır, çalışmazsa üst sınır etiketi kalır. Test: kazanç metninin kesin ifade içermediği doğrulanır.
2. **Kullanıcı bir gruptaki tüm kopyaları siler** → "Hepsini seç" yoktur. Her grupta en az bir dosya korunur. Bu kural hem arayüzde hem `DuplicateRemover` içinde zorlanır, çünkü arayüz tek başına yeterli savunma değildir. Test: bir grubun tamamı verilirse reddedilir.
3. **Tarama ile silme arasında dosya değişir (TOCTOU)** → Silmeden hemen önce boyut, tarih ve kalan kopya yeniden doğrulanır. Uyuşmazlıkta o dosya atlanır ve `ActionLog`'a yazılır. Test: tarama sonrası değiştirilen dosya silinmez.
4. **Hard link'i kopya sanıp silmek** → Aynı inode tek sayılır ve ayrı kopya olarak sunulmaz. Test eklenir.
5. **Korunan veya yanlış konumdaki dosyalar** → Mevcut `LargeFileRemover.policy` ve kök kuralları aynen kullanılır, `SafetyPolicy` genişletilmez. Test: korunan yol, `.app` içi, sembolik link ve başka disk reddedilir.
6. **Karma/karşılaştırma bağımlılığı ve Linux CI** → Bayt karşılaştırma standart kütüphane ile yapılır, yeni bağımlılık yoktur. Derlemenin Linux'ta geçtiği Adım 0'da doğrulanır.
7. **Tarama süresi ve G/Ç yükü** → Önce boyuta, sonra kısmi okumaya göre eleme yapılır, asgari boyut 1 MB'dır, tarama `Task.detached` ile iptal edilebilir. Adım 0'da ölçülür. Kabul edilemezse kapsam daraltılır (yalnızca İndirilenler, Masaüstü, Belgeler).
8. **TCC izin istemleri** → Faz 1'deki Full Disk Access onboarding'i kullanılır. İzin yoksa ilgili klasör atlanır ve kullanıcıya söylenir.
9. **Aynı içerik ama farklı anlam (ör. bilerek tutulan şablon kopyaları)** → Hiçbir şey otomatik silinmez. Her silme açık onay ister ve Çöp'ten geri alınabilir (§2.1, §2.2).

### Yapılmazsa ne kaybedilir
Faz 2'nin tek açık maddesi kalır ve Keel rakiplerin sunduğu bir özelliğe sahip olmaz. Daha önemlisi, kullanıcılar bunu başka bir araçla yapar. Bu araçlar çoğunlukla Keel'in sağladığı korumalara (allowlist, `SafetyPolicy`, kayıt, geri alma, dürüst kazanç gösterimi) sahip olmaz. Erteleme maliyeti düşüktür ve bunu saklamıyorum: ölçüm (Adım 0) kopya oranının küçük çıktığını gösterirse en doğru karar maddeyi kapatmaktır. Bu yüzden asıl önerim, tam özelliğe girmeden önce ucuz ölçümü yapmaktır. Ölçüm olmadan ne "yapalım" ne "yapmayalım" demek sağlam bir karar olur.
