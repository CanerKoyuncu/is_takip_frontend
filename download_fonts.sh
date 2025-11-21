#!/bin/bash
# Script to download Noto Sans fonts from a reliable source

echo "Noto Sans font dosyalarını indiriliyor..."

# Create fonts directory if it doesn't exist
mkdir -p assets/fonts

# Download fonts using a method that works
# Using raw.githubusercontent.com with proper headers
curl -L -H "Accept: application/octet-stream" \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans-Regular.ttf" \
  -o assets/fonts/NotoSans-Regular.ttf

curl -L -H "Accept: application/octet-stream" \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans-Bold.ttf" \
  -o assets/fonts/NotoSans-Bold.ttf

# Verify the files are actual TTF files
if file assets/fonts/NotoSans-Regular.ttf | grep -q "TrueType"; then
  echo "✓ NotoSans-Regular.ttf başarıyla indirildi"
else
  echo "✗ NotoSans-Regular.ttf indirme başarısız - dosya TTF değil"
  echo "Alternatif: Lütfen font dosyalarını manuel olarak şu adresten indirin:"
  echo "https://fonts.google.com/noto/specimen/Noto+Sans"
  rm -f assets/fonts/NotoSans-Regular.ttf
fi

if file assets/fonts/NotoSans-Bold.ttf | grep -q "TrueType"; then
  echo "✓ NotoSans-Bold.ttf başarıyla indirildi"
else
  echo "✗ NotoSans-Bold.ttf indirme başarısız - dosya TTF değil"
  rm -f assets/fonts/NotoSans-Bold.ttf
fi

echo ""
echo "Font dosyaları hazır. Şimdi 'flutter pub get' çalıştırın."

