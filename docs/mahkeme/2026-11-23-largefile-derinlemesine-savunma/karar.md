# Karar: Büyük Dosyalar silicide derinlemesine savunma (§2.3, §2.4) ve paket tespitinin `isPackage` özelliğine geçirilmesi

**KARAR:** DEĞİŞTİRİLEREK KABUL
**İNSAN ONAYI GEREKİR:** HAYIR (Kural 4 tetikleyicisi yok: root/helper/LaunchDaemon yok, kalıcı silme yok, `SafetyPolicy.swift` değiştirilmiyor, cihaz dışına veri çıkmıyor, yeni bağımlılık yok; yalnızca `LargeFiles.swift` içinde silici ve tarayıcı korumaları sıkılaştırılıyor.)

## Oylar
| Jüri | Oy | Güven | Veto |
|---|---|---|---|
| Güvenlik uzmanı | KOŞULLU | 4 | HAYIR |
| macOS sistem uzmanı | KABUL | 5 | HAYIR |
| Sıradan Mac kullanıcısı | KABUL | 5 | HAYIR |
| Kıdemli Swift mühendisi | KABUL | 5 | HAYIR |
| Ürün yöneticisi ve rakip analisti | KABUL | 5 | HAYIR |

## Gerekçe
`LargeFileRemover.perform()` gizli klasör/dosyaları (`~/.ssh`, `~/.gnupg`, `~/Documents/.secret`, `UF_HIDDEN`) ve `.app` dışındaki paket içlerini (`.photoslibrary`, `.rtfd`, `.vmwarevm`, `.fcpbundle`, `.xcodeproj`) kendi doğrulamasında reddetmiyordu; tarayıcı da 16 sabit uzantıyla sınırlıydı. Linux `swift-corelibs-foundation`'da `isPackageKey` her noktalı klasöre `true` döndüğü ve macOS'ta sahibi kurulu olmayan paketler `isPackageKey == false` dönebildiği için Seçenek B, genişletilmiş `packageExtensions` tabanı + `#if os(macOS)` `isPackageKey` birleşimi, `appData` owner muafiyeti (gerçek `Info.plist` paketi hariç; alt paketler red) ve `SafetyPolicy.isSameOrDescendant` tabanlı gizli bileşen kontrolüyle kabul edildi.

## Uygulama planı
1. `LargeFiles.swift`: Genişletilmiş `packageExtensions`, `hasBundleInfoPlist` ve platform-ayrımlı `isPackage` (yalnız dizinler).
2. `LargeFileScanner.scan()` ve `appDataLocation`: `SafetyPolicy` kanonik yol yardımcıları, `appData` owner muafiyeti (gerçek `Info.plist` hariç), Linux'ta `.skipsPackageDescendants` yerine `isPackage` ile yanlış pozitif engeli.
3. `LargeFileRemover.perform()`: `realHome` + `isSameOrDescendant`, tüm bileşenlerde `.` ve macOS'ta `~/Library` hariç `isHiddenKey` reddi, ata klasörlerde `isPackage` reddi (`appData` owner muaf, alt paketler red).
4. `LargeFilesTests.swift`: Gizli yollar, symlink ebeveyn, tüm paket uzantıları, düzenli dosya ve noktalı klasör yanlış pozitifleri, `appData` owner vs alt paketler, `#if os(macOS)` `UF_HIDDEN` ve `#else` Linux `Info.plist` testleri.
