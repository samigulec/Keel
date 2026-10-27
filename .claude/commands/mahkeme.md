---
description: Bir geliştirme kararını Keel Mahkemesi'nde yargıla (araştırma, savcı, avukat, gizli jüri, hakim)
argument-hint: <karar verilecek konu, örn. "kopya dosya bulucu ekleyelim mi">
---

Keel Mahkemesi'ni topla. Konu: **$ARGUMENTS**

Sen mahkemenin yazı işlerisin: ajanları sırayla çağırır, metinleri **aynen**
taşırsın. Kendi yorumunu eklemezsin, kimseye oy önermezsin, metinleri
kısaltmazsın.

## 0. Hazırlık
- Konudan kısa bir slug çıkar (küçük harf, tire; Türkçe karakter yok).
- Klasör: `docs/mahkeme/<YYYY-MM-DD>-<slug>/`

## 1. Dava dosyası
`arastirmaci` ajanını çağır, konuyu ver. Çıktıyı `dosya.md` olarak kaydet.

## 2. İddia ve savunma (paralel)
`savci` ve `avukat` ajanlarını **aynı anda** çağır. İkisine de yalnızca
`dosya.md`'nin tam metnini ver. Birbirlerinin yazdığını görmezler.
Çıktıları `iddianame.md` ve `savunma.md` olarak kaydet.

## 3. Jüri (paralel, gizli oy)
Şu beş ajanı **tek seferde, paralel** çağır:
`juri-guvenlik`, `juri-macos`, `juri-kullanici`, `juri-muhendis`, `juri-urun`.

Her birine **aynı** girdiyi ver: dosya + iddianame + savunma (tam metin).
Hiçbir jüriye başka bir jürinin oyunu verme; bu kural kesindir.
Çıktıları sırayla `oylar.md` dosyasına ekle.

Bir jürinin çıktısı istenen biçimde değilse (OY/GÜVEN/VETO satırları yoksa)
yalnızca o jüriyi bir kez daha çağır ve biçimi hatırlat.

## 4. Karar
`hakim` ajanını çağır; dosya, iddianame, savunma ve tüm oyları ver.
Çıktıyı `karar.md` olarak kaydet.

## 5. Kayıt ve rapor
- `docs/mahkeme/README.md` içindeki tabloya bir satır ekle:
  tarih, konu, karar, insan onayı, klasör linki.
- Kullanıcıya kısa bir özet ver: karar, oy dağılımı (ör. 4 KABUL / 1 RED),
  en önemli gerekçe, insan onayı gerekip gerekmediği, karar dosyasının yolu.

Bu komut **kod yazmaz**. Kodlama için `/gelistir` kullanılır.
