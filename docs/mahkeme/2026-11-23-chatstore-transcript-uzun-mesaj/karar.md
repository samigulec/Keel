# Karar: ChatStore.transcript uzun son mesaj veri akışı düzeltmesi

**KARAR:** DEĞİŞTİRİLEREK KABUL
**İNSAN ONAYI GEREKİR:** HAYIR (Kural 4'teki tetikleyicilerin hiçbiri yok: root/helper/LaunchDaemon yok; kalıcı silme ya da `SafetyPolicy` değişikliği yok; yeni dış bağımlılık, imzalama/notarization/lisans konusu veya geri alınamayan adım yok. Yeni bir veri sınıfı ya da yeni dış alıcı eklenmiyor; yalnızca kullanıcının yeniden açtığı yerel sohbet geçmişinin mevcut 6.000 karakterlik aktarım bütçesindeki kırpma ve ayraç hesabı hatası gideriliyor, bütçe kesin biçimde `<= maxCharacters` sınırına çekiliyor ve boş transkriptte gereksiz etiket gönderimi kaldırılıyor. Güvenlik jürisi de `VETO: HAYIR` vermiştir.)

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 4 | HAYIR |
| Sıradan Mac kullanıcısı | KABUL | 5 | HAYIR |
| Kıdemli Swift mühendisi | KABUL | 5 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KABUL | 5 | HAYIR |

## Gerekçe
`App/Features/Assistant/ChatStore.swift:80-90` içindeki `transcript(_:maxCharacters:)` son mesaj `maxCharacters` (6.000) sınırını aştığında ilk adımda kırılıp `""` dönüyor, `"\n\n"` ayraçlarını bütçeden düşmüyor ve `AssistantModel.swift:179-182` boş transkriptte `<previous_conversation>\n\n</previous_conversation>` etiketi gönderiyordu.

Savcının transkript ve sarmalamanın `KeelCore`'da Linux testli olması, B3 ortadan kırpma + açık `"\n…\n"` işareti ve `maxCharacters` değerinin parametrik kalması itirazları kabul edildi; avukatın Seçenek B çözümü güvenlik jürisinin bütçe ve uç durum test koşullarıyla birleştirildi.

## Uygulama planı
1. `Packages/KeelCore/Sources/KeelCore/AI/ChatTranscript.swift`: `build`, `wrap`, `applying` saf fonksiyonları (B3 ortadan kırpma, `"\n\n"` ve `"\n…\n"` bütçe içinde, `<= 0` ve küçük bütçe koruması, boşta `<previous_conversation>` bastırma).
2. `Packages/KeelCore/Tests/KeelCoreTests/ChatTranscriptTests.swift`: B3 kırpma, ayraç bütçesi, `.notice`/boş girdi, küçük/negatif bütçeler, Unicode grafem bütünlüğü ve parametrik bütçe testleri.
3. `App/Features/Assistant/ChatStore.swift`: `ChatStore.transcript` `ChatTranscript.build`'a delege eder (`SavedChat` şeması korunur).
4. `App/Features/Assistant/AssistantModel.swift`: `open(_:)` boş transkripti `nil` saklar; `send(_:)` `ChatTranscript.applying` kullanır ve `restoredTranscript = nil` sıfırlar.

## Kabul kriterleri
- [x] `swift test --package-path Packages/KeelCore` geçiyor.
- [x] `ChatTranscript` ve `ChatTranscriptTests` `KeelCore`'da Linux + macOS uyumlu.
- [x] `xcodegen generate && xcodebuild build` hatasız geçiyor.
- [x] `SafetyPolicy`, `SavedChat` JSON şeması ve dış veri politikası değişmedi.
