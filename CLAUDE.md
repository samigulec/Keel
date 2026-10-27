# Keel - ajanlar için çalışma kuralları

Proje özeti ve kurulum: `README.md`. Plan, güvenlik ilkeleri ve yol haritası:
`docs/PLAN.md`. Çalışmaya başlamadan önce ikisini de oku.

## Keel Mahkemesi

Önemli kararlar tek başına verilmez; önce `/mahkeme` ile yargılanır, kod
`/gelistir` ile yazılır. Ayrıntılar: `docs/mahkeme/README.md`.

Mahkeme şu durumlarda zorunlu:
- yeni özellik ya da yol haritası maddesi
- mimari karar, yeni bağımlılık
- silme, `SafetyPolicy`, yönetici yetkisi ya da Keel AI veri akışına
  dokunan her değişiklik

Küçük hata düzeltmeleri, yazım ve stil için gerekmez.

## Değişmez kurallar

- `docs/PLAN.md` §2 "Güvenlik ilkeleri (pazarlıksız)" her şeyin üstündedir.
- Silme yapan her kod `SafetyPolicy`'den geçer ve testsiz birleşmez.
- Mantık `Packages/KeelCore`'da (Linux'ta test edilebilir), arayüz `App/`'te.
- `Keel.xcodeproj` üretilen dosyadır; proje ayarı için `project.yml`.
- Testler: `swift test --package-path Packages/KeelCore`.
- `main`'e doğrudan gönderme yok, PR'ı ajan birleştirmez.
- Hakim `İNSAN ONAYI GEREKİR: EVET` dediyse kod yazılmaz; kullanıcıya sorulur.
