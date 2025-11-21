/// Loading Snackbar Widget
///
/// Yükleme durumunu snackbar içinde gösteren widget.
/// Uzun süren işlemler için kullanılır (fotoğraf yükleme, dosya indirme vb.)

import 'package:flutter/material.dart';

/// Loading snackbar gösterir
///
/// Snackbar içinde loading indicator ve mesaj gösterir.
class LoadingSnackbar {
  /// Loading snackbar gösterir
  ///
  /// Parametreler:
  /// - context: BuildContext
  /// - message: Gösterilecek mesaj (varsayılan: "Yükleniyor...")
  /// - duration: Snackbar süresi (varsayılan: 30 saniye)
  ///
  /// Döner: ScaffoldFeatureController - Snackbar'ı kapatmak için
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    String message = 'Yükleniyor...',
    Duration duration = const Duration(seconds: 30),
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Loading snackbar'ı kapatır
  ///
  /// Parametreler:
  /// - context: BuildContext
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
