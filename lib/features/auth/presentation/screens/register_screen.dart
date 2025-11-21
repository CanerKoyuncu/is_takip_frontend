/// Kayıt Ekranı
///
/// Bu ekran, kullanıcının yeni hesap oluşturmasını sağlar.
/// Kullanıcı adı, şifre ve opsiyonel email/tam ad ile kayıt yapar.
///
/// Özellikler:
/// - Form validasyonu
/// - Şifre görünürlük toggle'ı
/// - Hata mesajı gösterimi
/// - Yükleme durumu göstergesi

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Kayıt ekranı widget'ı
///
/// Kullanıcının kayıt bilgilerini girmesini sağlar.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// Kayıt ekranı state sınıfı
///
/// Form state'ini ve kullanıcı etkileşimlerini yönetir.
class _RegisterScreenState extends State<RegisterScreen> {
  // Form validasyonu için key
  final _formKey = GlobalKey<FormState>();
  // Kullanıcı adı input controller'ı
  final _usernameController = TextEditingController();
  // Şifre input controller'ı
  final _passwordController = TextEditingController();
  // Şifre tekrar input controller'ı
  final _confirmPasswordController = TextEditingController();
  // Email input controller'ı
  final _emailController = TextEditingController();
  // Tam ad input controller'ı
  final _fullNameController = TextEditingController();
  // Şifre görünürlük durumu (varsayılan: gizli)
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Widget dispose edildiğinde çağrılır
  ///
  /// Controller'ları temizler ve memory leak'leri önler.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  /// Form gönderim işlemini yönetir
  ///
  /// Form validasyonunu kontrol eder, kayıt işlemini başlatır
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
    // Kayıt işlemini başlat
    final success = await authProvider.register(
      username: _usernameController.text,
      password: _passwordController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      fullName: _fullNameController.text.isNotEmpty
          ? _fullNameController.text
          : null,
    );

    // Widget hala mount edilmiş mi kontrol et
    if (!mounted) return;

    // Kayıt başarılıysa dashboard'a yönlendir
    if (success) {
      context.go('/dashboard');
      return;
    }

    // Kayıt başarısızsa hata mesajını göster
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
  /// Kayıt formunu, butonları ve durum mesajlarını gösterir.
  @override
  Widget build(BuildContext context) {
    // Auth provider'ı izle (state değişikliklerini dinle)
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
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
                        'Yeni Hesap Oluştur',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Uygulama açıklaması
                      Text(
                        'Servis iş takip sistemine kayıt olun',
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
                          labelText: 'Kullanıcı Adı *',
                          prefixIcon: Icon(Icons.person_outline),
                          helperText: 'En az 3 karakter',
                        ),
                        validator: (value) {
                          // Boş olamaz validasyonu
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          if (value.trim().length < 3) {
                            return 'Kullanıcı adı en az 3 karakter olmalı';
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
                        textInputAction: TextInputAction.next,
                        obscureText: _obscurePassword, // Şifre gizleme
                        decoration: InputDecoration(
                          labelText: 'Şifre *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'En az 4 karakter',
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
                          if (value.length < 4) {
                            return 'Şifre en az 4 karakter olmalı';
                          }
                          return null;
                        },
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 16),
                      // Şifre tekrar input alanı
                      TextFormField(
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.next,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre Tekrar *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          // Şifre görünürlük toggle butonu
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          // Boş olamaz validasyonu
                          if (value == null || value.isEmpty) {
                            return 'Şifre tekrar gerekli';
                          }
                          // Şifreler eşleşmeli
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 16),
                      // Email input alanı (opsiyonel)
                      TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (Opsiyonel)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          // Email formatı kontrolü (opsiyonel olduğu için boş olabilir)
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Geçerli bir email adresi girin';
                            }
                          }
                          return null;
                        },
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 16),
                      // Tam ad input alanı (opsiyonel)
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Tam Ad (Opsiyonel)',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        // Enter'a basınca formu gönder
                        onFieldSubmitted: (_) => _handleSubmit(),
                        // Kullanıcı yazdıkça hata mesajını temizle
                        onChanged: (_) => authProvider.clearError(),
                      ),
                      const SizedBox(height: 24),
                      // Kayıt butonu
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
                            : const Icon(Icons.person_add),
                        label: Text(
                          authProvider.isLoading
                              ? 'Kayıt yapılıyor'
                              : 'Kayıt Ol',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Giriş ekranına dön linki
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Zaten hesabınız var mı? Giriş yapın',
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
