/// Loading Indicator Widget
///
/// Standart loading indicator widget'ı. Uygulama genelinde
/// yükleme durumlarını göstermek için kullanılır.
///
/// Özellikler:
/// - Merkezi konumlandırma
/// - Özelleştirilebilir boyut
/// - Tema uyumlu renkler

import 'package:flutter/material.dart';

/// Standart loading indicator widget'ı
///
/// Merkezi konumlandırılmış CircularProgressIndicator gösterir.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 2,
    this.color,
  });

  /// Loading indicator boyutu (varsayılan: 32)
  final double size;

  /// Stroke genişliği (varsayılan: 2)
  final double strokeWidth;

  /// Özel renk (varsayılan: tema primary rengi)
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Küçük loading indicator (snackbar ve butonlar için)
class SmallLoadingIndicator extends StatelessWidget {
  const SmallLoadingIndicator({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: Colors.white,
      ),
    );
  }
}
