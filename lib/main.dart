/// Servis İş Takip Uygulaması - Ana Giriş Noktası
///
/// Bu dosya uygulamanın başlangıç noktasıdır. Uygulama başlatıldığında
/// ilk olarak bu fonksiyon çalışır.
///
/// Görevleri:
/// - Flutter widget binding'ini başlatır
/// - Türkçe tarih formatlamasını yükler
/// - Ana uygulama widget'ını çalıştırır

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

/// Uygulamanın ana giriş fonksiyonu
///
/// Bu fonksiyon uygulama başlatıldığında otomatik olarak çağrılır.
/// Flutter framework'ünün başlatılması, .env dosyasının yüklenmesi ve
/// Türkçe lokalizasyon ayarlarının yapılması burada gerçekleştirilir.
Future<void> main() async {
  // Flutter widget binding'ini başlatır
  // Bu, Flutter'ın widget ağacını yönetebilmesi için gereklidir
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  // Development ortamında kullanılacak yapılandırmalar
  // .env.example'dan kopyalanıp .env dosyası oluşturulmalı
  await dotenv.load(fileName: ".env");

  // Türkçe tarih formatlamasını yükler
  // Bu sayede tarihler Türkçe formatında gösterilir (örn: "Ocak", "Pazartesi")
  await initializeDateFormatting('tr_TR');

  // Ana uygulama widget'ını çalıştırır
  // ServisIsTakipApp widget'ı tüm uygulamanın kök widget'ıdır
  runApp(const ServisIsTakipApp());
}
