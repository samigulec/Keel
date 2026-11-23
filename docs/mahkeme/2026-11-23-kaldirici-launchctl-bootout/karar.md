# Karar: Uygulama kaldırırken veya sıfırlarken LaunchAgent arka plan görevini `launchctl bootout` ile durdurma

**KARAR:** DEĞİŞTİRİLEREK KABUL
**İNSAN ONAYI GEREKİR:** HAYIR (Root/yönetici yetkisi yok, yalnızca `gui/<uid>` kullanıcı oturumu; kalıcı silme yok, tüm dosyalar Çöp Kutusu'na taşınır; `SafetyPolicy.swift` değiştirilmiyor; `launchctl disable` çağrılmadığı ve `bootout` hatasında fail-closed kalındığı için geri alınamayan durum oluşmuyor.)

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KABUL | 5 | HAYIR |
| Sıradan Mac kullanıcısı | KABUL | 5 | HAYIR |
| Kıdemli Swift mühendisi | KABUL | 5 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KABUL | 5 | HAYIR |

## Gerekçe
`Uninstaller.perform` `~/Library/LaunchAgents` içindeki plist dosyalarını doğrudan Çöp Kutusu'na taşıyor, `launchd` görevi bellekte tutmaya devam ediyordu. `ApplicationsModel` ilgili dosyaları boyut sırasıyla verdiği için küçük plist dosyaları en sona kalıyordu. Seçenek B, hem `UninstallPolicy.evaluateFile` hem `LaunchAgentStopper` katmanlarında `O_NOFOLLOW` + normal `.plist`, geçerli `Label`, case-insensitive `com.apple.*` ve Keel etiketi koruması, kabuksuz `Process` ile `/bin/launchctl bootout gui/<uid>/<label>`, `0`/`3`/`113` dışı hatalarda fail-closed ve `.launchAgents` hedeflerinin `.app` ve diğer dosyalardan önce durdurulup taşınması koşullarıyla kabul edildi.

## Uygulama planı
1. `Packages/KeelCore/Sources/KeelCore/Applications/LaunchAgentStopper.swift`: `O_NOFOLLOW` + `fstat` doğrulama, iç `<key>Label</key>` ve `com.apple.*`/Keel/`.`/`..`/`/` koruması, kabuksuz `Process` `/bin/launchctl bootout gui/<uid>/<label>`, `0/3/113` toleransı, diğerlerinde fail-closed.
2. `Packages/KeelCore/Sources/KeelCore/Applications/Uninstaller.swift`: `UninstallPolicy.evaluateFile` kanonik `Library/LaunchAgents` hedeflerini tam doğrulamadan geçirir; `Uninstaller.perform` LaunchAgent hedeflerini `.app` ve diğer dosyalardan önce durdurup taşır, sonucu `ActionLog.Entry.detail`'e yazar.
3. `App/Features/Applications/ApplicationsView.swift`: Onay metni yalnızca `.launchAgents` varsa arka plan görevlerinin durdurulacağını ve Geri Al'da sonraki oturumda başlayacağını belirtir.
4. `Packages/KeelCore/Tests/KeelCoreTests/ApplicationsTests.swift`: Sahte runner ile sıra, `0/3/113`, fail-closed, symlink, `com.apple.*`, Keel ve geçersiz etiket testleri.
