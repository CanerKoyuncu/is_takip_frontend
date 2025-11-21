/// Giriş Ekranı
///
/// Bu ekran, kullanıcının uygulamaya giriş yapmasını sağlar.
/// Kullanıcı adı ve şifre ile kimlik doğrulama yapar.
///
/// Özellikler:
/// - Form validasyonu
/// - Şifre görünürlük toggle'ı
/// - Hata mesajı gösterimi
/// - Son giriş zamanı gösterimi
/// - Yükleme durumu göstergesi

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Giriş ekranı widget'ı
///
/// Kullanıcının kimlik doğrulama bilgilerini girmesini sağlar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Giriş ekranı state sınıfı
///
/// Form state'ini ve kullanıcı etkileşimlerini yönetir.
class _LoginScreenState extends State<LoginScreen> {
  // Form validasyonu için key
  final _formKey = GlobalKey<FormState>();
  // Kullanıcı adı input controller'ı
  final _usernameController = TextEditingController();
  // Şifre input controller'ı
  final _passwordController = TextEditingController();
  // Şifre görünürlük durumu (varsayılan: gizli)
  bool _obscurePassword = true;

  /// Widget dispose edildiğinde çağrılır
  ///
  /// Controller'ları temizler ve memory leak'leri önler.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Form gönderim işlemini yönetir
  ///
  /// Form validasyonunu kontrol eder, giriş işlemini başlatır
  /// ve başarılı olursa dashboard'a yönlendirir.
  Future<void> _handleSubmit() async {
    // Auth provider'ı al
    final authProvider = context.read<AuthProvider>();
    // Önceki hata mesajlarını temizle
    authProvider.clearError();

    // Form validasyonunu kontrol et
    if (!_formKey.currentState!.validate()) {
      return; // Validasyon başarısızsa işlemi durdur
    }

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();
    // Giriş işlemini başlat
    final success = await authProvider.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    // Widget hala mount edilmiş mi kontrol et
    if (!mounted) return;

    // Giriş başarılıysa dashboard'a yönlendir
    if (success) {
      context.go('/dashboard');
      return;
    }

    // Giriş başarısızsa hata mesajını göster
    final message = authProvider.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar() // Önceki snackbar'ı kapat
        ..showSnackBar(
          SnackBar(content: Text(message)),
        ); // Hata mesajını göster
    }
  }

  /// Widget ağacını oluşturur
  ///
  /// Giriş formunu, butonları ve durum mesajlarını gösterir.
  @override
  Widget build(BuildContext context) {
    // Auth provider'ı izle (state değişikliklerini dinle)
    final authProvider = context.watch<AuthProvider>();
    // Son giriş zamanını al
    final lastLoginAt = authProvider.lastLoginAt;
    // Son giriş zamanını Türkçe formatında formatla
    final lastLoginText = lastLoginAt != null
        ? DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(lastLoginAt)
        : null;

    return Scaffold(
      body: GestureDetector(
        // Ekrana dokunulduğunda klavyeyi kapat
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                // Maksimum genişlik (büyük ekranlarda ortalanmış görünüm)
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      // Uygulama başlığı
                      Text(
                        'Servis İş Takip',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Uygulama açıklaması
                      Text(
                        'Kaporta ve boya servisi için iş takip sistemi',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Kullanıcı adı input alanı
                      TextFormField(
                        controller: _usernameController,
                        autofocus: true, // Sayfa açıldığında otomatik odaklan
                        textInputAction:
                            TextInputAction.next, // Sonraki alana geç
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          // Boş olamaz validasyonu
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 16),
                      // Şifre input alanı
                      TextFormField(
                        controller: _passwordController,
                        textInputAction:
                            TextInputAction.done, // Enter'a basınca gönder
                        obscureText: _obscurePassword, // Şifre gizleme
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          // Şifre görünürlük toggle butonu
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          // Boş olamaz validasyonu
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                        // Enter'a basınca formu gönder
                        onFieldSubmitted: (_) => _handleSubmit(),
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 24),
                      // Giriş butonu
                      FilledButton.icon(
                        onPressed: authProvider.isLoading
                            ? null // Yükleniyorsa butonu devre dışı bırak
                            : _handleSubmit,
                        icon: authProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          authProvider.isLoading
                              ? 'Giriş yapılıyor'
                              : 'Giriş Yap',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Kiosk modu butonu
                      OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => context.go('/kiosk'),
                        icon: const Icon(Icons.touch_app),
                        label: const Text('Kiosk Modu'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      // Hata mesajı gösterimi
                      if (authProvider.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          authProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Son giriş zamanı gösterimi
                      if (lastLoginText != null)
                        Text(
                          'Son giriş: $lastLoginText',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
