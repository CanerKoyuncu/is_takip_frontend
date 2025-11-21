/// Uygulama Tema Yapılandırması
///
/// Bu dosya, uygulamanın görsel temasını tanımlar.
/// Material Design 3 kullanarak modern ve tutarlı bir görünüm sağlar.
///
/// Özellikler:
/// - Material Design 3 desteği
/// - Seed color tabanlı renk şeması
/// - Özelleştirilmiş widget temaları (AppBar, Button, Input, Chip)

import 'package:flutter/material.dart';

/// Uygulama tema sınıfı
///
/// Tüm tema yapılandırmaları bu sınıfta tanımlanır.
class AppTheme {
  /// Açık tema (Light Theme)
  ///
  /// Uygulamanın varsayılan temasıdır.
  /// Material Design 3 kullanarak modern bir görünüm sağlar.
  static ThemeData get light {
    // Tema rengi - mavi tonları (Material Design 3 seed color)
    const seedColor = Color(0xFF2F5DA1);

    return ThemeData(
      // Material Design 3 kullan
      useMaterial3: true,
      // Seed color'dan otomatik renk şeması oluştur
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      // Scaffold arka plan rengi (beyaz)
      scaffoldBackgroundColor: Colors.white,
      // AppBar teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, // Gölge yok (modern görünüm)
        centerTitle: true, // Başlık ortada
      ),
      // Input field teması
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(), // Dış çerçeveli input
      ),
      // Elevated button teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48), // Minimum yükseklik
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
          ),
        ),
      ),
      // Chip teması
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Tam yuvarlak köşeler
        ),
      ),
    );
  }
}
