## Savunma

### Neden yapılmalı
Menü çubuğu penceresi bugün CPU, bellek, disk, ağ ve sıcaklığı yalnızca anlık sayı ve ilerleme çubuğu olarak gösteriyor. Oysa `SystemStatus` son yaklaşık 60 saniyelik geçmişi (`cpuHistory`, `networkInHistory`, `networkOutHistory`, `diskReadHistory`, `cpuTemperatureHistory`, `historyLength = 30`) zaten topluyor ve yalnızca Performans ekranı kullanıyor. Kullanıcı bir CPU ya da ağ sıçramasını görmek için Keel'i açıp Performans sekmesine geçmek zorunda. Seçenek B bu veriyi menü penceresine taşır. Kullanıcı tek tıkla "az önce ne oldu" sorusunu yanıtlar. Maliyeti düşüktür: yaklaşık 100-150 satır, yeni ölçüm yok, yeni bağımlılık yok, ağ yok, silme yok. Pencere yalnızca kullanıcı açınca çizildiği için enerji yükü artmaz. Bu, PLAN Faz 1 ve Faz 2'de tamamlanan menü çubuğu işlerinin doğal devamıdır.

### Önerdiğim versiyon
Seçenek D'nin birinci yarısı, daraltılmış hâliyle. Simge (C) bu davanın dışında kalır.

Kapsam:
1. `Sparkline` bileşeni `PerformanceView.swift` içindeki `private struct`'tan ortak bir yere (`App/DesignSystem/Components.swift`) taşınır. Yükseklik parametre olur: Performans ekranı 56 pt, menü yaklaşık 18-22 pt kullanır. Performans ekranının görünümü değişmez.
2. `MenuBarContent` içinde yalnızca CPU ve ağ (↓/↑) satırlarına mini grafik eklenir. Disk ve bellek ilk adımda dışarıda kalır. Gerekçe: disk satırı 30 sn'de bir güncelleniyor, grafiği anlamsız olur. Bellek için geçmiş dizisi yok.
3. Pencere genişliği 260 pt olarak kalır. Yeni ayar anahtarı, yeni `Preference` ve yeni `project.yml` değişikliği yoktur.
4. Geçmiş kırpma mantığı (`SystemStatus.appending`, satır 196-198) küçük bir `RollingHistory` ya da serbest fonksiyon olarak `Packages/KeelCore` içine alınır. Dosyanın bilinmeyenler 9. maddesi ve CLAUDE.md "mantık KeelCore'da" kuralı bunu gerektirir. Linux'ta test edilir: boş dizi, uzunluk sınırı, taşma ve sırayı koruma. `SystemStatus` bu fonksiyonu çağırır, davranış aynı kalır. İş büyürse bu parça ayrı bir küçük PR'a bölünebilir. İlk PR yalnızca Sparkline taşıma ve iki satıra grafik olabilir.

Bilerek yapılmayanlar:
- Menü çubuğu simgesinde canlı grafik (C). Ayrı mahkeme gerekir. Ön koşulu Mac'te ölçümdür: Activity Monitor ya da Instruments ile etiket yeniden çizme maliyeti, `ImageRenderer` ve etiket görünümü sınırları, çentikli ekranda genişlik.
- Pencere kapalıyken ölçüm hızını düşürmek. Bu `SystemStatus` döngüsünü ve Performans ekranını etkiler. B için gerekmez, C kararıyla birlikte ele alınmalıdır.
- Bellek geçmişi. "Kullanılan bellek" mi "bellek baskısı" mı sorusu çözülmeden eklenmez.
- Geçmişin Keel AI'ya gönderilmesi. Bu ayrı karar gerektirir (PLAN satır 154).

Öncelik sorusu: Faz 2 sırası (`GUNDEM.md`) sahipte kaldığı için, bu iş küçük ve geri alınabilir olduğundan "sahip öncelik verirse hemen yapılabilir" diye işaretlenmelidir. Hakim isterse karara "İNSAN ONAYI" notu eklenebilir. Bu iş güvenlik ilkelerine dokunmadığından CLAUDE.md'ye göre zorunlu değildir, ama sıra sorusu insana aittir.

### Bilinen riskler ve önlemleri
1. Ek yük: sparkline her 2 sn'de bir yeniden çizilir (pencere açıkken) → Pencere kapalıyken görünüm çizilmez, ölçüm döngüsü aynı kalır. Dizi uzunluğu sabit 30 olduğu için çizim maliyeti sınırlıdır. Yine de Mac'te bir kez Instruments ile pencere açıkken CPU bakılır. Bu Linux'ta yapılamayacağı için PR açıklamasına "ölçülmedi, sahip doğrulasın" notu yazılır.
2. `Sparkline` taşınırken Performans ekranı bozulabilir → Yükseklik varsayılanı 56 pt kalır, çağrı yerleri (satır 341, 366, 469-470, 510-511, 548) değişmez. Değişiklik bir ekran görüntüsü karşılaştırmasıyla PR'da gösterilir.
3. `appending` taşınırken davranış değişebilir → Önce mevcut davranışı sabitleyen testler yazılır, sonra taşınır. Taşıma ayrı commit olur.
4. Küçük pencerede okunabilirlik (260 pt) → Grafik yalnızca CPU ve ağda. Değer metni korunur, grafik yalnızca ek bilgidir. Erişilebilirlik için grafiğe `accessibilityHidden(true)` verilir, sayı zaten okunur.
5. Kapsam kayması (simge grafiğine, hız ayarına, bellek geçmişine geçme) → Yukarıdaki "yapılmayanlar" listesi PR kapsamı olarak yazılır. Bu üçü için ayrı mahkeme açılır.
6. Swift Charts ya da yeni çerçeve çekme isteği → Kullanılmaz. Mevcut çubuk tabanlı `Sparkline` yeterlidir, bağımlılık sorusu hiç açılmaz (PLAN §1).
7. Güvenlik ilkeleri → Özellik salt okunur. Silme yok, yeni yol yok, root yok (§2.8), yeni okuyucu yok. `SafetyPolicy` kuralı gerekmez. Yeni okuma kaynağı eklenirse bu versiyondan çıkılmış sayılır.

### Yapılmazsa ne kaybedilir
Kaybedilen şey çok büyük değil, bunu dürüstçe söylemek gerekir: menü penceresi zaten çalışıyor ve ayrıntılı grafikler Performans ekranında duruyor. Ertelemenin maliyeti şudur. Zaten toplanan geçmiş veri menüde kullanılmaz, kullanıcı anlık sıçramaları görmek için uygulamayı açmak zorunda kalır. Menü çubuğu monitörlerinin ana rakibi grafik sunduğu için bu bir ürün farkı yaratır. `appending` mantığı `App/` katmanında test edilmeden kalır ve CLAUDE.md'deki "mantık KeelCore'da" kuralıyla çelişmeye devam eder. En önemlisi, B yapılmazsa "canlı grafik" maddesi C'nin ölçülmemiş belirsizliğine bağlı kalır ve hiç ilerlemez. B'yi ayırmak, C'nin ölçümünü beklemeden değer sunar. Öte yandan sahip Faz 2'de başka bir maddeyi (kopya bulucu, sahipsiz artıklar, güncelleyici) önceliklendirirse, B'nin ertelenmesi kabul edilebilir. Bu durumda Seçenek A'nın gerekçeli notu da kabul edilebilir bir sondur.

Doğrulama notu: Dava dosyasındaki dosya ve satır numaralarını yeniden açıp doğrulamadım. Yalnızca `docs/PLAN.md` §2'yi okudum. Önerim §2'nin hiçbir maddesiyle çelişmiyor.
