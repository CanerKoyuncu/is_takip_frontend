# Font Dosyası Kurulumu

PDF oluşturma için Noto Sans font dosyasına ihtiyaç vardır.

## Kurulum Adımları

1. **Google Fonts'tan İndirin:**
   - https://fonts.google.com/noto/specimen/Noto+Sans adresine gidin
   - "Download family" butonuna tıklayın
   - ZIP dosyasını indirin

2. **Font Dosyasını Çıkarın:**
   - İndirilen ZIP dosyasını açın
   - `NotoSans.ttf` dosyasını bulun (veya herhangi bir Noto Sans TTF dosyası)

3. **Dosyayı Bu Klasöre Kopyalayın:**
   - `NotoSans.ttf` → `assets/fonts/NotoSans.ttf`

4. **Flutter Komutlarını Çalıştırın:**
   ```bash
   flutter clean
   flutter pub get
   ```

5. **Uygulamayı Yeniden Başlatın**

## Notlar

- Font dosyası **TTF formatında** olmalıdır (WOFF2 çalışmaz)
- Dosya geçerli bir TTF dosyası olmalıdır (HTML veya bozuk dosyalar çalışmaz)
- `NotoSans.ttf` dosyası hem Regular hem Bold olarak kullanılacaktır
- Eğer font yükleme hatası alırsanız, build klasörünü temizleyin: `flutter clean`

