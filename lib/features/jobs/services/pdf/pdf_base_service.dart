import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

/// PDF Temel Servis
///
/// Font ve Logo gibi ortak kaynakların yüklenmesini merkezi olarak yönetir.
class PdfBaseService {
  PdfBaseService._();

  static pw.ImageProvider? _logoImage;
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  /// Fontları yükler (Türkçe Karakter Desteği)
  static Future<void> ensureFontsLoaded() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
      _regularFont = pw.Font.ttf(fontData);
      _boldFont = pw.Font.ttf(fontData);
      debugPrint('✓ PDF Fontları başarıyla yüklendi.');
    } catch (e) {
      debugPrint('✗ PDF Font yükleme hatası: $e');
      // Fallback: NotoSans.ttf yoksa standart pdf fontu kullan (Türkçe karakter sorunu olabilir)
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  /// Şirket logosunu yükler
  static Future<void> ensureLogoLoaded() async {
    if (_logoImage != null) return;

    try {
      final possiblePaths = [
        'assets/logo.png',
        'assets/images/logo.png',
        'assets/images/company_logo.png',
      ];

      for (final path in possiblePaths) {
        try {
          final logoData = await rootBundle.load(path);
          _logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
          debugPrint('✓ PDF Logosu yüklendi: $path');
          return;
        } catch (_) {
          continue;
        }
      }

      // Web Fallback
      if (kIsWeb) {
        try {
          final baseUrl = Uri.base.origin;
          final response = await http.get(
            Uri.parse('$baseUrl/assets/logo.png'),
          );
          if (response.statusCode == 200) {
            _logoImage = pw.MemoryImage(response.bodyBytes);
            debugPrint('✓ PDF Logosu Web üzerinden yüklendi.');
            return;
          }
        } catch (e) {
          debugPrint('Web Logo yükleme hatası: $e');
        }
      }
    } catch (e) {
      debugPrint('✗ Logo yükleme hatası: $e');
    }
  }

  static pw.Font get regularFont => _regularFont ?? pw.Font.helvetica();
  static pw.Font get boldFont => _boldFont ?? pw.Font.helveticaBold();
  static pw.ImageProvider? get logoImage => _logoImage;

  /// Standart PDF Teması (Türkçe karakter desteği dahil)
  static pw.ThemeData getTheme() {
    return pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      italic: regularFont,
      boldItalic: boldFont,
    );
  }
}
