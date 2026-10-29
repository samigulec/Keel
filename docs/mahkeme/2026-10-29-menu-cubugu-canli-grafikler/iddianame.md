## İddianame

(Not: Yalnızca dava dosyasına dayandım. Kodu ve PLAN'ı ayrıca açıp doğrulamadım. Aşağıdaki olgular dosyadaki aktarımlara aittir.)

### Ana itiraz
Dava, "canlı grafik" ifadesinin ne anlama geldiğini çözmeden karar istiyor. B (açılan pencerede mini grafik) ile C (simgede canlı grafik) arasında büyük bir fark var. C'nin maliyeti hiç ölçülmemiş. Menü çubuğu etiketinin sınırları macOS 14'te doğrulanmamış. Enerji etkisi bilinmiyor. Notch davranışı bilinmiyor. Dosyadaki dış kaynaklar (Control Center'ın yaklaşık %3 CPU'su, Stats'ın "kapatınca %50'ye kadar azalır" notu) bu riskin gerçek olabileceğini gösteriyor. Üstelik ölçüm döngüsü pencere kapalıyken de 2 sn'de bir çalışıyor. C bu gizli maliyeti kalıcı ve görünür bir enerji yüküne çevirir. Bu yüzden C bu hâliyle yapılmamalı. B de koşulsuz yapılmamalı. Üç önceki davada sorulan Faz 2 öncelik sorusu hâlâ cevapsız. Bakım uygulaması olarak Keel'in "hafif ve güvenilir" imajı için, kimsenin istediği doğrulanmamış bir görsel özellik öncelik sayılamaz. Savunulabilecek en iyi hâl şudur. B yalnızca küçük kapsamla yapılır. Geçmiş mantığı `KeelCore`'a alınıp Linux'ta test edilir. C ayrı bir mahkemeye bırakılır ve Mac'te ölçüm şartına bağlanır. Bunun dışındaki her hâle karşı çıkıyorum.

### Riskler
1. **C: Simge etiketinin pencere kapalıyken de her 2 sn'de yeniden çizilmesi.** Sürekli CPU ve enerji tüketimi olur. Kullanıcı bir bakım uygulamasının kendisinin pil ve CPU yediğini görür. Bu Keel'in varlık gerekçesiyle çelişir. Dosyadaki Control Center örneği (yaklaşık %3 CPU) bunun gerçekçi olduğunu düşündürüyor, ama resmi ölçüm değil. - olasılık: orta-yüksek - etki: orta - geri alınabilir: evet (ayar anahtarı veya geri alma ile)

2. **C: `ImageRenderer` veya SwiftUI etiket görünümünün macOS 14'te güvenilmez olması.** Olası sorunlar: etiket güncellenmez, bayatlar, boyut veya renk (koyu/açık tema) bozulur, bellek sızıntısı olur. Kaynakların hiçbiri açılıp okunmamış. Bu kısmı yalnızca Mac'te ve gerçek sürümlerde test edebiliriz. Linux CI hiçbirini yakalayamaz. - olasılık: orta - etki: orta - geri alınabilir: evet

3. **C: Notch'lu ekranlarda simgenin genişleyip gizlenmesi.** Genişleyen simge menü çubuğunda yer bulamaz. Kullanıcı Keel'e hiç ulaşamayabilir. Çıkış ve açma düğmeleri pencerenin içinde olduğu için, menü çubuğundan yönetilen uygulamada bu bir erişilebilirlik sorunu olur. - olasılık: orta - etki: orta - geri alınabilir: evet (ama kullanıcı simgeyi görmediği için sorunu fark edemez, `menuBarVisible` anahtarına ulaşması gerekir)

4. **Test edilemeyen kod ve CLAUDE.md ihlali eğilimi.** Geçmiş mantığı (`SystemStatus.appending`) `App/` katmanında. CLAUDE.md "mantık `KeelCore`'da" diyor. B veya C, `RollingHistory` gibi bir şeyi `KeelCore`'a almadan yazılırsa, yeni bellek geçmişi dizisi de `App/`'e eklenir ve test edilemeyen mantık büyür. Mevcut kırpma mantığı için bugün test yok, yani yeni özellik testsiz borcun üstüne biner. - olasılık: yüksek (varsayılan yol bu) - etki: düşük-orta - geri alınabilir: evet

5. **Yanıltıcı arayüz: bellek grafiği.** "Kullanılan bellek" grafiği, macOS'ta normal olan yüksek kullanımı kullanıcıya sorun gibi gösterir (önbellek ve sıkıştırılmış bellek). Bakım uygulaması "belleğin dolu olması" izlenimi verip temizleme baskısı yaratırsa, bu abartılı vaat ve dolaylı bir ürün güven sorunudur. PLAN satır 54 çizgisi baskıyı öne çıkarıyor. Yanlış metrik seçilirse kullanıcıya yanlış güven veya yanlış panik verilir. - olasılık: orta - etki: orta - geri alınabilir: evet

6. **Kapsam sürüklenmesi: ölçüm döngüsünün hızını pencere durumuna bağlamak (D'nin eki).** Bu `SystemStatus` döngüsünü değiştirir ve Performans ekranını etkiler. Sıcaklık (4 sn) ve disk/pil (30 sn) için farklı aralıklar olduğundan döngü karmaşık. Hız değişimi geçmiş dizilerinin zaman eksenini bozar. 30 örnek artık 60 sn değil, kimi aralıkta 150-300 sn eder. Sparkline'lar eksen etiketi olmadan yanlış zaman ölçeği öğretir. Eşzamanlılık hatası riski de var: her iş türünden en fazla biri çalışır kuralı (satır 97-126) bozulursa üst üste ölçüm yığılır. - olasılık: orta - etki: orta - geri alınabilir: evet

7. **`Sparkline`'ın ortak bileşene taşınması.** `private struct`'ı taşırken Performans ekranında (5 yerde kullanılıyor) görsel gerileme olabilir. Bunu yakalayacak görsel test yok. - olasılık: düşük-orta - etki: düşük - geri alınabilir: evet

8. **Öncelik ve bakım yükü.** Üç davadır Faz 2 sırası sahibine sorulmuş ve cevap gelmemiş. Bu maddenin sahip tarafından önemsendiği bilinmiyor. İki ayrı işe (B ve C) bölünen "canlı grafik" maddesi, ürünün asıl değerini (güvenli temizlik) ilerletmeyen bir görsel işe geliştirici zamanı harcar. Rakip (Stats, iStat) zaten bu alanda güçlü ve ücretsiz. Keel'in bu alanda rekabet etmesi için bir gerekçe dosyada yok. - olasılık: orta - etki: düşük-orta - geri alınabilir: evet

### Pazarlıksız ilke ihlali
Yok. Özellik salt okunur. Silme, `SafetyPolicy`, yönetici yetkisi, ağ ve Keel AI veri akışına dokunmuyor. Dosyadaki §2.8 (root yok) yorumuna katılıyorum: mevcut okuyucular root gerektirmiyor. Uyarı olarak şunu not ediyorum. §1 "bağımlılık mümkün olduğunca sıfır" için Swift Charts'ın dış bağımlılık sayılmadığı yorumu doğrulanmadı. Charts kullanılacaksa bu yorum hakim tarafından açıkça onaylanmalı. Bence `Sparkline` zaten yeterli, Charts gerekmez. Geçmiş verisinin Keel AI'ya gönderilmesi bu davanın kapsamı dışında kalmalı (PLAN satır 154), karara açıkça yazılmalı.

### İtirazım hangi koşulda düşer
İtirazım şu koşulların tümü sağlanırsa düşer. B kapsamıyla, C olmadan ilerlenir.
1. Kapsam B ile sınırlıdır. Simge statik kalır. C, "Mac'te Activity Monitor/Instruments ile enerji ve CPU ölçümü + macOS 14 etiket davranışı + notch kontrolü" şartıyla ayrı bir mahkemeye bırakılır. Bu şart karara yazılır.
2. Geçmiş kırpma mantığı (`RollingHistory` benzeri) `KeelCore`'a alınır ve Linux'ta testle birleştirilir (sınır durumları: boş, tam dolu, taşma, `historyLength` değişimi). Bellek geçmişi de aynı yapıyla eklenir.
3. Bellek grafiğinde metrik olarak ham "kullanılan" yerine baskı ya da en azından yanıltmayan bir etiket seçilir. Ya da bellek grafiği bu aşamada hiç eklenmez.
4. `SystemStatus` ölçüm döngüsünün hızı bu işte değiştirilmez. Pencere durumuna bağlı hız ayarı ayrı bir karar olur. Döngü maliyeti ayrıca ölçülmeden kapsama alınmaz.
5. Faz 2 öncelik sorusu için sahip onayı alınır ya da kararda "öncelik insana ait" denerek İNSAN ONAYI istenir. Bu üç davadır cevapsız olduğundan, benim önerim bu maddeyi diğer iki aday (kopya bulucu, güncelleyici vb.) karşısında düşük öncelikli tutmaktır.
6. `Sparkline` taşınırken Performans ekranındaki kullanımlar elle kontrol edilir ve PR'da ekran görüntüsüyle gösterilir. Yeni bağımlılık eklenmez.

Dürüstlük notu: B'ye karşı ciddi bir güvenlik itirazım yok. Ana itirazım C'ye ve belirsiz kapsama yönelik. B küçük, salt okunur ve geri alınabilir.
