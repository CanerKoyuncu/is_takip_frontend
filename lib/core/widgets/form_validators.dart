/// Form Validators
///
/// Ortak form validasyon fonksiyonları.
/// Tüm form ekranlarında kullanılabilir.

/// Form validasyon yardımcı fonksiyonları
class FormValidators {
  FormValidators._();

  /// Boş olmamalı validasyonu
  ///
  /// Parametreler:
  /// - value: Kontrol edilecek değer
  /// - errorMessage: Hata mesajı (varsayılan: "Bu alan gerekli")
  ///
  /// Döner: String? - Hata mesajı veya null
  static String? required(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Bu alan gerekli';
    }
    return null;
  }

  /// Minimum uzunluk validasyonu
  ///
  /// Parametreler:
  /// - value: Kontrol edilecek değer
  /// - minLength: Minimum uzunluk
  /// - errorMessage: Hata mesajı (opsiyonel)
  ///
  /// Döner: String? - Hata mesajı veya null
  static String? minLength(
    String? value,
    int minLength, {
    String? errorMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required(value);
    }
    if (value.trim().length < minLength) {
      return errorMessage ?? 'En az $minLength karakter olmalı';
    }
    return null;
  }

  /// Email formatı validasyonu
  ///
  /// Parametreler:
  /// - value: Kontrol edilecek email
  /// - errorMessage: Hata mesajı (opsiyonel)
  ///
  /// Döner: String? - Hata mesajı veya null
  static String? email(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email opsiyonel olabilir
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return errorMessage ?? 'Geçerli bir email adresi girin';
    }
    return null;
  }

  /// Şifre eşleşme validasyonu
  ///
  /// Parametreler:
  /// - value: Kontrol edilecek şifre
  /// - password: Karşılaştırılacak şifre
  /// - errorMessage: Hata mesajı (opsiyonel)
  ///
  /// Döner: String? - Hata mesajı veya null
  static String? passwordMatch(
    String? value,
    String password, {
    String? errorMessage,
  }) {
    if (value == null || value.isEmpty) {
      return required(value);
    }
    if (value != password) {
      return errorMessage ?? 'Şifreler eşleşmiyor';
    }
    return null;
  }

  /// Telefon numarası validasyonu
  ///
  /// Parametreler:
  /// - value: Kontrol edilecek telefon
  /// - errorMessage: Hata mesajı (opsiyonel)
  ///
  /// Döner: String? - Hata mesajı veya null
  static String? phone(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return required(value);
    }
    // Basit telefon validasyonu (sadece rakamlar ve + işareti)
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return errorMessage ?? 'Geçerli bir telefon numarası girin';
    }
    return null;
  }
}

