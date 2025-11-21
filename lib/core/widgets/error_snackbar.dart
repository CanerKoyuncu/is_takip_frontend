/// Snackbar Yardımcı Sınıfı
///
/// Bu sınıf, kullanıcıya bilgi mesajları göstermek için kullanılır.
/// Hata, başarı ve bilgi mesajları için farklı renklerde snackbar'lar gösterir.
///
/// Özellikler:
/// - Hata mesajları (kırmızı)
/// - Başarı mesajları (yeşil)
/// - Bilgi mesajları (mavi)
/// - Floating snackbar (ekranın altında yüzen)
/// - Kapatma butonu

import 'package:flutter/material.dart';

/// Snackbar yardımcı sınıfı
///
/// Static metodlar ile kolayca snackbar göstermeyi sağlar.
/// Singleton pattern kullanır (instance oluşturulamaz).
class ErrorSnackbar {
  // Private constructor - bu sınıf sadece static metodlar içerir
  ErrorSnackbar._();

  /// Hata snackbar'ı gösterir
  ///
  /// Kullanıcıya hata mesajı gösterir. Kırmızı renkte ve hata ikonu ile.
  ///
  /// Parametreler:
  /// - context: BuildContext (snackbar'ı göstermek için)
  /// - message: Gösterilecek hata mesajı
  /// - duration: Snackbar'ın ekranda kalma süresi (varsayılan: 4 saniye)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // İçerik: ikon + mesaj
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        // Kırmızı arka plan (hata rengi)
        backgroundColor: Colors.red.shade700,
        // Ekranda kalma süresi
        duration: duration,
        // Floating davranış (ekranın altında yüzen)
        behavior: SnackBarBehavior.floating,
        // Kapatma butonu
        action: SnackBarAction(
          label: 'Kapat',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Başarı snackbar'ı gösterir
  ///
  /// Kullanıcıya başarı mesajı gösterir. Yeşil renkte ve başarı ikonu ile.
  ///
  /// Parametreler:
  /// - context: BuildContext
  /// - message: Gösterilecek başarı mesajı
  /// - duration: Ekranda kalma süresi (varsayılan: 3 saniye)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // İçerik: başarı ikonu + mesaj
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        // Yeşil arka plan (başarı rengi)
        backgroundColor: Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Bilgi snackbar'ı gösterir
  ///
  /// Kullanıcıya bilgi mesajı gösterir. Mavi renkte ve bilgi ikonu ile.
  ///
  /// Parametreler:
  /// - context: BuildContext
  /// - message: Gösterilecek bilgi mesajı
  /// - duration: Ekranda kalma süresi (varsayılan: 3 saniye)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // İçerik: bilgi ikonu + mesaj
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        // Mavi arka plan (bilgi rengi)
        backgroundColor: Colors.blue.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
