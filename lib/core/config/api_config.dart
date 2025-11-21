import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:is_takip/env.dart';

/// API Yapılandırma Sınıfı
///
/// Bu sınıf, backend API ile iletişim için gerekli yapılandırma değerlerini içerir.
/// API base URL, API key ve header isimleri burada tanımlanır.
///
/// Yapılandırma Kaynakları (Öncelik sırası):
/// 1. Environment variable'lar (flutter run --dart-define=VAR=value)
/// 2. .env dosyası (flutter_dotenv paketi ile)
/// 3. Varsayılan değerler (fallback)
///
/// Önemli Notlar:
/// - .env dosyası repository'ye commit edilmez (güvenlik için)
/// - .env.example template olarak saklanır
/// - API key güvenlik açısından kritiktir, asla kod içinde hardcode edilmemelidir
class ApiConfig {
  // Private constructor - bu sınıf singleton pattern kullanır
  ApiConfig._();

  /// API Base URL
  ///
  /// Backend API'nin temel adresini belirtir.
  ///
  /// Yapılandırma kaynakları:
  /// 1. Environment: flutter run -d chrome --dart-define=API_BASE_URL=...
  /// 2. .env dosyası: API_BASE_URL=http://localhost:4001/api
  /// 3. Default: https://pass.cram.services/api (production)
  ///
  /// Development örneği (.env dosyasında):
  ///   API_BASE_URL=http://localhost:4001/api
  ///
  /// Production örneği (environment variable):
  ///   flutter run --dart-define=API_BASE_URL=https://pass.cram.services/api
  static String get baseUrl {
    String url;

    // Önce environment variable kontrol et
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      url = envUrl;
    } else {
      // Sonra .env dosyasından oku
      final dotenvUrl = dotenv.env['API_BASE_URL'];
      if (dotenvUrl != null && dotenvUrl.isNotEmpty) {
        url = dotenvUrl;
      } else {
        // Default: Nginx üzerinden (production ve local development)
        url = 'https://yb.cram.services/api';
      }
    }

    // baseUrl'in /api ile bitmesini garanti et
    // Eğer zaten /api ile bitiyorsa değiştirme
    if (!url.endsWith('/api')) {
      // Eğer / ile bitiyorsa kaldır, sonra /api ekle
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      url = '$url/api';
    }

    return url;
  }

  /// API Key (Kimlik Doğrulama Anahtarı)
  ///
  /// Backend API'ye istek yaparken kimlik doğrulama için kullanılır.
  ///
  /// Yapılandırma kaynakları:
  /// 1. Environment: flutter run -d chrome --dart-define=API_KEY=...
  /// 2. .env dosyası: API_KEY=test
  /// 3. Default: '' (boş - production key gerekli)
  ///
  /// Güvenlik Uyarıları:
  /// - Production key'ini .env'ye koymayın, environment variable olarak set edin
  /// - Development: .env dosyasında API_KEY=test
  /// - Production: flutter run --dart-define=API_KEY=your_production_key
  static String get apiKey {
    // Önce environment variable kontrol et
    const envKey = String.fromEnvironment('API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;

    // Envied ile build-time'da gömülen değer
    final generatedKey = Env.apiKey;
    if (generatedKey.isNotEmpty) return generatedKey;

    // Sonra .env dosyasından oku
    final dotenvKey = dotenv.env['API_KEY'];
    if (dotenvKey != null && dotenvKey.isNotEmpty) return dotenvKey;

    // Default: boş (production key gerekli)
    return '';
  }

  /// API Key Header İsmi
  ///
  /// HTTP isteklerinde API key'in gönderileceği header ismini belirtir.
  /// Backend bu header'ı kontrol ederek kimlik doğrulama yapar.
  static const String apiKeyHeader = 'X-API-Key';
}
