# Mahkeme gündemi

Günlük mahkeme konularını önce buradan, sonra `docs/PLAN.md`'deki `- [ ]`
maddelerinden seçer. Bu dosyayı sen düzenlersin; ajanlar yalnızca
"Ajan önerileri" bölümüne ekleme yapabilir.

## Sıradaki konular (senin eklediklerin, yukarıdan aşağı)

<!-- Örnek: - Menü çubuğuna pil sağlığı göstergesi -->

## Bekleyen insan onayları

Hakim "İNSAN ONAYI GEREKİR: EVET" dediğinde konu buraya düşer. Cevabını
konunun altına yaz; ajanlar cevaplanmış konuyu `/gelistir` sırasına alır.

### Kopya dosya bulucu ([karar](2026-10-27-kopya-dosya-bulucu/karar.md))
1. Faz 2'deki açık maddelerden hangisi önce yapılsın?
2. Adım 0 ölçüm aracını kendi Mac'inde çalıştırmayı kabul ediyor musun?
3. Eşik uygun mu? (en az 20 kopya grubu ve en fazla 1 GB üstü yer)

Cevap:

### Sahipsiz artıklar ([karar](2026-10-28-sahipsiz-artiklar/karar.md))
Karar: yalnızca Aşama 0 (silme yapmayan, salt okunur ölçüm) kabul; silme yapan her aşama reddedildi.
1. Öncelik: Faz 2 açık maddeleri (sahipsiz artıklar, uygulama güncelleyici, menü çubuğu canlı grafikleri, kopya dosya bulucu, LaunchAgent aç/kapat) arasında Aşama 0 şimdi mi yapılsın, yoksa madde gerekçeli notla ertelensin mi (Seçenek A)?
2. Ölçüm: Aşama 0 aracını kendi Mac'inde çalıştırıp çıktıyı elle gözden geçirmeyi kabul ediyor musun? Hangi makine ve macOS sürümü? Setapp, Homebrew Cask, Microsoft Office ya da harici diskte uygulama kurulu mu?
3. Eşik: Aşama 1 mahkemesine gidebilmek için yanlış pozitif eşiği ne olsun? (Hakimin önerisi: 6 konumda elle doğrulanmış yanlış pozitif sıfır; aşılırsa Seçenek A.)
4. Araç biçimi: KeelCore'a eklenecek küçük bir komut satırı aracı mı (hakimin önerisi), yoksa uygulamada yalnızca DEBUG derlemede görünen bir ekran mı?

Cevap:

## Ajan önerileri (onaylarsan "Sıradaki konular"a taşı)

- Büyük Dosyalar bulucusunda paket tespiti sabit 16 uzantılık listeye
  dayanıyor; `.rtfd`, sanal makine paketleri gibi bilinmeyen paketlerin içi
  normal klasör sanılabilir. (Kaynak: kopya dosya bulucu kararı, kapsam dışı
  notu)
