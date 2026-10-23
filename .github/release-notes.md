## Kurulum

1. Aşağıdan **Keel-{{VERSION}}.dmg** dosyasını indir ve aç.
2. **Keel**'i **Applications** (Uygulamalar) klasörüne sürükle.
3. İlk açılışta macOS "Apple, Keel'in kötü amaçlı yazılım içermediğini doğrulayamadı" der. Keel henüz Apple Developer ID ile imzalanmadığı için bu normal. Açmak için:
   - Keel'i bir kez açmayı dene, uyarıyı **Bitti** ile kapat.
   - **Sistem Ayarları → Gizlilik ve Güvenlik**'e git, en altta Keel için **Yine de Aç**'a bas ve şifreni gir.

   Olmazsa Terminal'de şunu çalıştır, sonra Keel'i normal aç:
   ```
   xattr -dr com.apple.quarantine /Applications/Keel.app
   ```

macOS 14 Sonoma veya üstü gerekir. Apple silicon (M1–M5) ve Intel Mac'lerde çalışır.

## Keel neler yapar

- **Akıllı Tarama:** Tek tıkla sağlık puanı ve yapılacaklar.
- **Temizlik:** Önbellekler, günlükler, tarayıcı ve geliştirici önbellekleri. Her şey Çöp Kutusu'na gider, geri alınabilir.
- **Performans:** İşlemci, GPU, bellek, SSD, ağ, sıcaklıklar ve fanlar. Fanlar elle hızlandırılabilir (yönetici şifresi ister).
- **Optimizasyon:** Yoğun uygulamalar, girişte açılanlar, arka plan servisleri.
- **Uygulamalar:** Artık dosyalarıyla birlikte kaldırma.
- **Büyük Dosyalar:** Büyük ve eski dosyaları bulma.
- **Keel AI:** Mac'in hakkında sohbet. Kendi ChatGPT (Codex) veya Claude (Claude Code) hesabınla ya da macOS 26'da Apple Intelligence ile çalışır. Hiçbir şey sen onaylamadan değişmez.

Keel AI için Claude Code veya Codex'i kurmak isteğe bağlıdır; Keel AI ekranı nasıl kurulacağını gösterir.
