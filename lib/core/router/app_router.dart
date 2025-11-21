/// Uygulama Routing Yapılandırması
///
/// Bu dosya, GoRouter kullanarak uygulamanın sayfa yönlendirmelerini yönetir.
/// Kullanıcının giriş durumuna göre otomatik yönlendirme yapar ve
/// tüm uygulama rotalarını tanımlar.
///
/// Özellikler:
/// - Kimlik doğrulama durumuna göre otomatik yönlendirme
/// - Nested routing (iç içe rotalar)
/// - Parametreli rotalar (jobId gibi)
/// - Extra data ile veri aktarımı
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/jobs/models/vehicle_area.dart';
import '../../features/jobs/presentation/screens/job_order_creation/create_screen.dart';
import '../../features/jobs/presentation/screens/dashboard_screen.dart';
import '../../features/jobs/presentation/screens/job_orders/list_screen.dart';
import '../../features/jobs/presentation/screens/job_orders/detail_screen.dart';
import '../../features/jobs/presentation/screens/job_orders/task_management_screen.dart';
import '../../features/jobs/presentation/screens/job_orders/add_data_screen.dart';
import '../../features/jobs/presentation/screens/job_orders/add_task_screen.dart';
import '../../features/jobs/presentation/screens/job_order_creation/vehicle_parts_screen.dart';
import '../../features/jobs/presentation/screens/kiosk/kiosk_screen.dart';
import '../../features/jobs/presentation/screens/workers/workers_management_screen.dart';
import '../../features/jobs/presentation/screens/workers/worker_hours_report_screen.dart';
import '../../features/jobs/presentation/screens/workers/my_tasks_screen.dart';
import '../../features/jobs/presentation/screens/workers/available_tasks_screen.dart';
import '../../features/jobs/presentation/screens/workers/all_assigned_tasks_screen.dart';
import '../../features/jobs/presentation/screens/workers/pending_tasks_screen.dart';

/// Uygulama router sınıfı
///
/// GoRouter yapılandırmasını yapar ve kimlik doğrulama durumuna göre
/// yönlendirme mantığını uygular.
class AppRouter {
  AppRouter(this._authProvider);

  // Kimlik doğrulama provider'ı - kullanıcının giriş durumunu kontrol etmek için
  final AuthProvider _authProvider;

  // Root navigator key - navigator stack'ini yönetmek için
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// GoRouter yapılandırması
  ///
  /// Tüm uygulama rotalarını tanımlar ve kimlik doğrulama durumuna göre
  /// otomatik yönlendirme yapar.
  late final GoRouter router = GoRouter(
    // Navigator key - navigator stack'ini yönetmek için
    navigatorKey: _rootNavigatorKey,
    // Başlangıç rotası - uygulama açıldığında gösterilecek sayfa
    initialLocation: '/login',
    // Auth provider'ı dinler - kullanıcı giriş/çıkış yaptığında router'ı günceller
    refreshListenable: _authProvider,
    // Yönlendirme mantığı - kullanıcının giriş durumuna göre sayfa yönlendirmesi yapar
    redirect: (context, state) {
      // Kullanıcının giriş yapıp yapmadığını kontrol et
      final isLoggedIn = _authProvider.isAuthenticated;
      // Kullanıcı şu anda hangi sayfada?
      final currentPath = state.matchedLocation;
      // Kullanıcı şu anda login sayfasında mı?
      final loggingIn =
          currentPath == '/login' || currentPath.startsWith('/login');
      // Kullanıcı şu anda kiosk modunda mı?
      final inKiosk =
          currentPath == '/kiosk' || currentPath.startsWith('/kiosk/');
      // Kullanıcı personel yönetimi sayfasında mı?
      final inWorkersPage =
          currentPath == '/dashboard/workers' ||
          currentPath.startsWith('/dashboard/workers');

      // Kullanıcı giriş yapmamışsa
      if (!isLoggedIn) {
        // Eğer zaten login veya kiosk sayfasındaysa yönlendirme yapma
        if (loggingIn || inKiosk) {
          return null;
        }
        // Değilse login sayfasına yönlendir
        return '/login';
      }

      // Kullanıcı giriş yapmış ve login sayfasındaysa
      // Dashboard'a yönlendir (çift giriş yapmaya çalışıyorsa)
      if (loggingIn) {
        return '/dashboard';
      }

      // Personel yönetimi sayfasına erişim kontrolü
      // Sadece admin'ler erişebilir
      // Kullanıcı bilgisi yüklenmişse kontrol et
      if (inWorkersPage) {
        final user = _authProvider.user;
        // Kullanıcı bilgisi henüz yüklenmemişse, redirect yapma (bekle)
        if (user == null) {
          return null;
        }
        // Kullanıcı bilgisi yüklendi, admin kontrolü yap
        if (!_authProvider.isAdmin) {
          // Admin değilse dashboard'a yönlendir
          return '/dashboard';
        }
      }

      // Başka bir yönlendirme gerekmiyorsa null döndür
      return null;
    },
    // Uygulama rotaları - tüm sayfa yönlendirmeleri burada tanımlanır
    routes: [
      // Login sayfası - kimlik doğrulama için
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Dashboard sayfası - ana sayfa (nested routes içerir)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        // Dashboard altındaki alt sayfalar (nested routes)
        routes: [
          // Araç parçaları seçim sayfası
          GoRoute(
            path: '/vehicle-parts',
            name: 'vehicle-parts',
            builder: (context, state) => const VehiclePartsScreen(),
          ),
          // İş emri oluşturma sayfası - Supervisor, manager ve admin'ler erişebilir
          // Extra data ile seçilen parçalar ve işlemler aktarılır
          GoRoute(
            path: '/create-job-order',
            name: 'create-job-order',
            builder: (context, state) {
              // İş emri oluşturma yetkisi kontrolü
              if (!_authProvider.canCreateJob) {
                return const Scaffold(
                  body: Center(child: Text('Bu sayfaya erişim yetkiniz yok.')),
                );
              }

              // Extra data'dan seçimleri al
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null) {
                // Eğer extra data yoksa hata mesajı göster
                return const Scaffold(
                  body: Center(child: Text('Hata: Seçimler bulunamadı.')),
                );
              }

              // Seçilen parça işlemlerini al
              final selections = extra['selections'] as VehiclePartSelections;
              // Parça listesini al
              final parts = extra['parts'] as List<VehiclePart>;

              // İş emri oluşturma ekranını göster
              return CreateJobOrderScreen(selections: selections, parts: parts);
            },
          ),
          // İş emirleri listesi sayfası (nested routes içerir)
          GoRoute(
            path: '/job-orders',
            name: 'job-orders',
            builder: (context, state) => const JobOrdersListScreen(),
            // İş emirleri altındaki alt sayfalar
            routes: [
              // İş emri detay sayfası - jobId parametresi ile
              GoRoute(
                path: ':jobId',
                name: 'job-order-detail',
                builder: (context, state) {
                  // URL'den jobId parametresini al
                  final jobId = state.pathParameters['jobId']!;
                  return JobOrderDetailScreen(jobId: jobId);
                },
                // İş emri detay sayfası altındaki alt sayfalar
                routes: [
                  // Görev yönetimi sayfası
                  GoRoute(
                    path: 'tasks',
                    name: 'job-task-management',
                    builder: (context, state) {
                      final jobId = state.pathParameters['jobId']!;
                      return JobTaskManagementScreen(jobId: jobId);
                    },
                  ),
                  // İş emrine veri ekleme sayfası (fotoğraf vb.)
                  GoRoute(
                    path: 'add-data',
                    name: 'add-data-to-job',
                    builder: (context, state) {
                      final jobId = state.pathParameters['jobId']!;
                      return AddDataToJobScreen(jobId: jobId);
                    },
                  ),
                  // İş emrine görev ekleme sayfası
                  GoRoute(
                    path: 'add-task',
                    name: 'add-task-to-job',
                    builder: (context, state) {
                      final jobId = state.pathParameters['jobId']!;
                      return AddTaskToJobScreen(jobId: jobId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Personel yönetimi sayfası - Sadece admin'ler erişebilir
          // Erişim kontrolü redirect fonksiyonunda yapılıyor
          GoRoute(
            path: '/workers',
            name: 'workers-management',
            builder: (context, state) {
              // Redirect fonksiyonunda kontrol edildiği için buraya gelen kullanıcı admin'dir
              return const WorkersManagementScreen();
            },
          ),
          // İşçi mesai saatleri raporu - Supervisor ve üzeri erişebilir
          GoRoute(
            path: '/worker-hours-report',
            name: 'worker-hours-report',
            builder: (context, state) {
              // Supervisor ve üzeri kontrolü
              if (!_authProvider.canCreateJob) {
                return const Scaffold(
                  body: Center(child: Text('Bu sayfaya erişim yetkiniz yok.')),
                );
              }
              return const WorkerHoursReportScreen();
            },
          ),
          // Personel görevleri - Tüm kullanıcılar erişebilir
          GoRoute(
            path: '/my-tasks',
            name: 'my-tasks',
            builder: (context, state) => const MyTasksScreen(),
          ),
          // Müsait görevler - Tüm kullanıcılar erişebilir
          GoRoute(
            path: '/available-tasks',
            name: 'available-tasks',
            builder: (context, state) => const AvailableTasksScreen(),
          ),
          // Tüm atanmış görevler - Supervisor ve üzeri erişebilir
          GoRoute(
            path: '/all-assigned-tasks',
            name: 'all-assigned-tasks',
            builder: (context, state) {
              if (!_authProvider.canCreateJob) {
                return const Scaffold(
                  body: Center(child: Text('Bu sayfaya erişim yetkiniz yok.')),
                );
              }
              return const AllAssignedTasksScreen();
            },
          ),
          // Bekleyen görevler - Supervisor ve üzeri erişebilir
          GoRoute(
            path: '/pending-tasks',
            name: 'pending-tasks',
            builder: (context, state) {
              if (!_authProvider.canCreateJob) {
                return const Scaffold(
                  body: Center(child: Text('Bu sayfaya erişim yetkiniz yok.')),
                );
              }
              return const PendingTasksScreen();
            },
          ),
        ],
      ),
      // Kiosk modu route'ları
      GoRoute(
        path: '/kiosk',
        name: 'kiosk',
        builder: (context, state) => const KioskScreen(),
      ),
    ],
  );
}
