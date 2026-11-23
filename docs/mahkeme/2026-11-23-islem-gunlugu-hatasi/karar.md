# Karar: Silme ve geri alma işlem günlüğü yazılamazsa sessiz kalmama (§2.7)

**KARAR:** DEĞİŞTİRİLEREK KABUL
**İNSAN ONAYI GEREKİR:** HAYIR (Kural 4 tetikleyicisi yok: root/helper yok, kalıcı silme kuralı ya da `SafetyPolicy`/`UninstallPolicy` değişikliği yok, `logError` yalnızca yerel arayüzde gösteriliyor ve cihaz dışına çıkmıyor, `TrashRestorer` kilitlenmiyor.)

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KOŞULLU | 5 | HAYIR |
| Sıradan Mac kullanıcısı | KOŞULLU | 4 | HAYIR |
| Kıdemli Swift mühendisi | KABUL | 5 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KABUL | 5 | HAYIR |

## Gerekçe
`CleanupExecutor`, `TrashRestorer`, `Uninstaller` ve `LargeFileRemover` içindeki `try? log?.append(...)` çağrıları günlük yazma hatalarını sessizce yutuyordu. İşlem öncesi `verifyWritable()` ön kilidi (Seçenek C / Hibrit C+B), disk doluyken (`ENOSPC`) yer açmaya çalışan kullanıcıyı ve `TrashRestorer` kurtarma yolunu kilitleme riski nedeniyle reddedildi; PR #8 emsaliyle uyumlu Seçenek B (`logError` özet alanı + tüm UI/SmartCare/Assistant ekranlarında kesilmeden uyarı + 4 modülde deterministik birim test) kabul edildi.

## Uygulama planı
1. `ActionLog.swift` içine `ActionLogTracker` (ilk hata + başarısız kayıt sayacı) ve 4 rapora `public var logError: String? = nil`.
2. `CleanupExecutor`, `TrashRestorer`, `Uninstaller`, `LargeFileRemover` yürütücülerinde `try?` kaldırılıp `ActionLogTracker` ile `report.logError` doldurulur.
3. `CleanupExecutorTests`, `UndoTests`, `ApplicationsTests`, `LargeFilesTests` paketlerine yazılamayan `ActionLog` testleri eklenir.
4. `Undo.summary`, `SmartCareModel.cleanRecommended`, `CleanupView`, `ApplicationsView`, `LargeFilesView`, `SmartScanView`, `AssistantModel` tüketicileri `logError`'ı kesilmeden uyarı ikonu/rengiyle gösterir.
