/// Servis İş Takip Uygulaması - Ana Uygulama Widget'ı
///
/// Bu dosya uygulamanın ana widget'ını içerir. Tüm uygulama yapısı,
/// routing, state management ve tema ayarları burada yapılandırılır.
///
/// Görevleri:
/// - Provider'ları (AuthProvider, JobsProvider) başlatır
/// - Routing yapılandırmasını yapar
/// - Tema ayarlarını uygular
/// - Uygulama yaşam döngüsü olaylarını dinler
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service_factory.dart';
import 'core/services/auth_api_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/jobs/providers/jobs_provider.dart';

/// Ana uygulama widget'ı
///
/// Bu widget tüm uygulamanın kök widget'ıdır. MaterialApp.router kullanarak
/// routing yapılandırmasını yapar ve Provider'ları uygulama genelinde
/// erişilebilir hale getirir.
class ServisIsTakipApp extends StatefulWidget {
  const ServisIsTakipApp({super.key});

  @override
  State<ServisIsTakipApp> createState() => _ServisIsTakipAppState();
}

/// Ana uygulama widget'ının state sınıfı
///
/// WidgetsBindingObserver mixin'i ile uygulama yaşam döngüsü olaylarını dinler.
/// Bu sayede uygulama arka plana gidip geldiğinde gerekli işlemler yapılabilir.
class _ServisIsTakipAppState extends State<ServisIsTakipApp>
    with WidgetsBindingObserver {
  // Kimlik doğrulama state'ini yöneten provider
  AuthProvider? _authProvider;

  // Routing yapılandırmasını yöneten router
  AppRouter? _appRouter;

  // İş emirleri state'ini yöneten provider
  JobsProvider? _jobsProvider;

  // Başlatma durumu
  bool _isInitialized = false;

  /// Widget başlatıldığında çağrılır
  ///
  /// Bu metodda:
  /// - Uygulama yaşam döngüsü observer'ı eklenir
  /// - Provider'lar oluşturulur
  /// - Router yapılandırılır
  /// - API servisleri başlatılır
  @override
  void initState() {
    super.initState();
    // Uygulama yaşam döngüsü olaylarını dinlemek için observer eklenir
    WidgetsBinding.instance.addObserver(this);

    // Async initialization
    _initializeApp();
  }

  /// Uygulamayı başlatır
  ///
  /// API servislerini, provider'ları ve router'ı başlatır.
  Future<void> _initializeApp() async {
    try {
      // API servislerini başlat
      final apiService = ApiServiceFactory.getApiService();

      // Auth API service'i oluştur (cookies otomatik yönetilecek)
      final authApiService = AuthApiService(apiService);

      // Kimlik doğrulama provider'ı oluşturulur
      _authProvider = AuthProvider(authApiService: authApiService);

      // Mevcut token'ı kontrol et (cookies'den)
      await _authProvider!.checkAuthStatus();

      // Router, auth provider'ı kullanarak yapılandırılır
      // Router, kullanıcının giriş durumuna göre yönlendirme yapar
      _appRouter = AppRouter(_authProvider!);

      // JobsApiService, backend ile iletişim için kullanılır
      final jobsApiService = ApiServiceFactory.getJobsApiService();
      _jobsProvider = JobsProvider(jobsApiService: jobsApiService);

      // Başlatma tamamlandı
      _isInitialized = true;

      // State'i güncelle
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda da provider'ları oluştur (fallback)
      final apiService = ApiServiceFactory.getApiService();
      final authApiService = AuthApiService(apiService);
      _authProvider = AuthProvider(authApiService: authApiService);
      _appRouter = AppRouter(_authProvider!);
      final jobsApiService = ApiServiceFactory.getJobsApiService();
      _jobsProvider = JobsProvider(jobsApiService: jobsApiService);
      _isInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Widget dispose edildiğinde çağrılır
  ///
  /// Kaynakları temizler ve observer'ı kaldırır.
  @override
  void dispose() {
    // Uygulama yaşam döngüsü observer'ı kaldırılır
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama yaşam döngüsü değiştiğinde çağrılır
  ///
  /// Uygulama arka plana gidip geldiğinde iş emirlerini yeniler.
  /// Bu sayede kullanıcı uygulamaya geri döndüğünde güncel verileri görür.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana geldiğinde iş emirlerini yenile
    // Bu sayede kullanıcı uygulamaya geri döndüğünde güncel verileri görür
    if (state == AppLifecycleState.resumed && _jobsProvider != null) {
      _jobsProvider!.refreshJobs();
    }
  }

  /// Widget ağacını oluşturur
  ///
  /// MultiProvider ile tüm provider'ları uygulama genelinde erişilebilir hale getirir.
  /// MaterialApp.router ile routing yapılandırmasını yapar ve tema ayarlarını uygular.
  @override
  Widget build(BuildContext context) {
    // Başlatma tamamlanmadıysa loading göster
    if (!_isInitialized ||
        _authProvider == null ||
        _appRouter == null ||
        _jobsProvider == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      // Provider'ları uygulama genelinde erişilebilir hale getirir
      // Bu sayede herhangi bir widget'tan bu provider'lara erişilebilir
      providers: [
        // Kimlik doğrulama provider'ı
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider!),
        // İş emirleri provider'ı
        ChangeNotifierProvider<JobsProvider>.value(value: _jobsProvider!),
      ],
      child: MaterialApp.router(
        // Debug banner'ını gizle (geliştirme modunda gösterilir)
        debugShowCheckedModeBanner: false,
        // Uygulama başlığı
        title: 'Servis İş Takip',
        // Uygulama teması (açık tema)
        theme: AppTheme.light,
        // Router yapılandırması
        // GoRouter ile sayfa yönlendirmeleri yapılır
        routerConfig: _appRouter!.router,
        // Desteklenen diller (sadece Türkçe)
        supportedLocales: const [Locale('tr')],
        // Varsayılan dil (Türkçe)
        locale: const Locale('tr'),
        // Lokalizasyon delegate'leri
        // Material Design, Widget ve Cupertino (iOS) widget'ları için Türkçe çeviriler
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
