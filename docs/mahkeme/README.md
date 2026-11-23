# Keel Mahkemesi

Keel'i geliştiren ajanlar önemli bir kararı tek başına vermez. Önce mahkeme
toplanır: tek bir AI'nın "harika fikir" deyip geçmesi yerine, öneri iki
taraftan tartışılır ve farklı uzmanlar birbirinden habersiz oy verir.

```
araştırmacı ──► dava dosyası
                   │
         ┌─────────┴─────────┐
       savcı              avukat          (paralel, birbirini görmez)
     "neden batar"     "neden tutar"
         └─────────┬─────────┘
                   ▼
   5 jüri, gizli oy (paralel, birbirini görmez)
   güvenlik* · macOS · kullanıcı · mühendis · ürün
                   │
                   ▼
                 hakim ──► karar + uygulama planı
                   │
          (kabul edilirse /gelistir)
                   ▼
       kodlama ──► hakim denetimi ──► PR (birleştirme kararı insanın)
```

\* Güvenlik jürisinin vetosu var: `docs/PLAN.md`'deki pazarlıksız
güvenlik ilkelerini çiğneyen bir öneri, çoğunluk istese bile kabul edilmez.

## Ne zaman mahkeme kurulur

- Yeni özellik ya da yol haritası maddesi
- Mimari karar, yeni bağımlılık
- Silme, `SafetyPolicy`, yönetici yetkisi ya da Keel AI veri akışına
  dokunan her değişiklik

Küçük hata düzeltmeleri, yazım, stil ve testi olan küçük refactor'lar için
mahkeme gerekmez.

## Kullanım (Claude Code'da)

```
/mahkeme kopya dosya bulucu ekleyelim mi
/gelistir                       # PLAN.md'deki sıradaki işi yargıla ve yap
/gelistir menü çubuğuna canlı grafik
```

Ajan tanımları: `.claude/agents/`. Komutlar: `.claude/commands/`.

## Kararlar

| Tarih | Konu | Karar | İnsan onayı | Kayıt |
|---|---|---|---|---|
| 2026-10-27 | Kopya dosya bulucu | DEĞİŞTİRİLEREK KABUL (5 KOŞULLU, veto yok) | EVET: öncelik + Adım 0 ölçümü (cevaplandı 2026-11-23) | [2026-10-27-kopya-dosya-bulucu](2026-10-27-kopya-dosya-bulucu/karar.md) |
| 2026-10-28 | Sahipsiz artıklar | DEĞİŞTİRİLEREK KABUL: yalnızca Aşama 0 salt okunur ölçüm (3 KOŞULLU / 2 RED, veto yok) | EVET: öncelik, ölçüm, eşik, araç biçimi (cevaplandı 2026-11-23) | [2026-10-28-sahipsiz-artiklar](2026-10-28-sahipsiz-artiklar/karar.md) |
| 2026-10-29 | Uygulama güncelleyici | DEĞİŞTİRİLEREK KABUL: yalnızca Aşama 0 ağsız, salt okunur kaynak dağılımı ölçümü (5 KOŞULLU, veto yok) | EVET: öncelik, ortak ölçüm, ölçüm ortamı, eşik, ağ ilkesi (cevaplandı 2026-11-23) | [2026-10-29-uygulama-guncelleyici](2026-10-29-uygulama-guncelleyici/karar.md) |
| 2026-10-29 | Menü çubuğunda canlı grafikler | DEĞİŞTİRİLEREK KABUL: yalnızca açılan pencerede CPU ve ağ mini grafikleri (B), simge grafiği ayrı mahkemeye (5 KOŞULLU, veto yok) | EVET: öncelik, kapsam (B/C), Mac'te doğrulama, görünüm (cevaplandı 2026-11-23) | [2026-10-29-menu-cubugu-canli-grafikler](2026-10-29-menu-cubugu-canli-grafikler/karar.md) |
| 2026-10-30 | Kullanıcı LaunchAgent'larını aç/kapat | DEĞİŞTİRİLEREK KABUL: madde yeni özellik değil, kapanış işi; servis aç/kapat için ayrı `startup.log` kaydı, `.user`/çift-etiket testleri, "süreç durdurulur" uyarısı; satır 144 Mac doğrulamasına kadar `[x]` olmaz (5 KOŞULLU, veto yok) | HAYIR (5 soru GUNDEM'de, cevaplandı 2026-11-23) | [2026-10-30-kullanici-launchagent-ac-kapat](2026-10-30-kullanici-launchagent-ac-kapat/karar.md) |
