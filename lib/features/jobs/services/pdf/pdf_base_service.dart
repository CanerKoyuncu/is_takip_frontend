import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

/// PDF Temel Servis
///
/// Font ve Logo gibi ortak kaynakların yüklenmesini merkezi olarak yönetir.
class PdfBaseService {
  PdfBaseService._();

  static const String _primaryLogoAsset = 'assets/logo.png';

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
      // Workspace'te mevcut olan tek logo dosyasını önce doğrudan dene.
      final logoData = await rootBundle.load(_primaryLogoAsset);
      _logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      debugPrint('✓ PDF Logosu yüklendi: $_primaryLogoAsset');
      return;
    } catch (_) {
      // Web fallback'e geçilecek.
    }

    try {
      // Web Fallback
      if (kIsWeb) {
        final baseUrl = Uri.base.origin;
        final fallbackUrls = [
          '$baseUrl/assets/assets/logo.png',
          '$baseUrl/assets/logo.png',
        ];

        for (final url in fallbackUrls) {
          try {
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              _logoImage = pw.MemoryImage(response.bodyBytes);
              debugPrint('✓ PDF Logosu Web üzerinden yüklendi: $url');
              return;
            }
          } catch (_) {
            // Diğer fallback URL'ini dene.
          }
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
