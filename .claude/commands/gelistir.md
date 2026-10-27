---
description: Bir sonraki işi mahkemeden geçir, kabul edilirse kodla, denetlet ve PR aç
argument-hint: [konu - boş bırakılırsa docs/PLAN.md'deki sıradaki iş]
---

Keel'de bir geliştirme döngüsü çalıştır. Konu: **$ARGUMENTS**

## 1. Konuyu belirle
- Konu verildiyse onu kullan.
- Boşsa `docs/PLAN.md` yol haritasında, en erken fazdaki ilk işaretlenmemiş
  (`[x]` olmayan) maddeyi seç. Faz 3 ve Faz 4 maddelerini atla (yetki,
  imza ve yayın konuları insan işi). Seçtiğin maddeyi kullanıcıya söyle.

## 2. Hazırlık
- `git status` temiz olmalı. Değilse dur ve kullanıcıya söyle.
- `main`'den yeni dal aç: `claude/<slug>` (CI bu dallarda çalışır).

## 3. Mahkeme
`.claude/commands/mahkeme.md` dosyasındaki adımları (0–5) bu konu için
uygula.

Sonra `karar.md`'ye bak:
- **RED** ise: mahkeme kayıtlarını commit et, dalı gönder, kullanıcıya
  kararı ve gerekçeyi bildir. **Dur.**
- **İNSAN ONAYI GEREKİR: EVET** ise: kayıtları commit et, kullanıcıya neden
  onay gerektiğini ve planı özetle. **Dur, kod yazma.** Kullanıcı onaylarsa
  bu komut "onaylandı" notuyla tekrar çalıştırılır ve 4. adımdan devam edilir.
- Aksi hâlde devam et.

## 4. Uygulama
- `karar.md`'deki uygulama planını adım adım uygula. Plan dışına çıkma;
  plan yetersizse dur ve nedenini yaz.
- Mantık `Packages/KeelCore`'a, arayüz `App/`'e. Platforma özel kod
  `#if os(macOS)` ile ayrılır.
- Silme ya da sistem değişikliği yapan her kod için test yaz.
- Testleri çalıştır: `swift test --package-path Packages/KeelCore`.
  macOS'taysan uygulamayı da derle:
  `xcodegen generate && xcodebuild build -project Keel.xcodeproj -scheme Keel -destination 'platform=macOS'`.

## 5. Denetim
- `hakim` ajanını denetim için çağır: `karar.md` + `git diff main...HEAD`.
- Değişiklik silme, `SafetyPolicy`, yetki ya da Keel AI veri akışına
  dokunuyorsa `juri-guvenlik`'i de diff üzerinde çağır.
- DÜZELTME GEREKLİ ise düzelt ve tekrar denetlet. En fazla 2 tur; hâlâ
  geçmiyorsa dur ve kullanıcıya açık sorunları bildir.

## 6. Teslim
- `docs/PLAN.md`'de ilgili maddeyi `[x]` yap (yalnızca tamamen bittiyse).
- Commit et, dalı gönder, PR aç. PR açıklamasında: karar özeti, oy
  dağılımı, `karar.md` linki, test sonucu.
- **`main`'e asla doğrudan gönderme, PR'ı kendin birleştirme.** Birleştirme
  kararı kullanıcının.
- Kullanıcıya kısa rapor: ne yapıldı, PR linki, bilinen açıklar.
