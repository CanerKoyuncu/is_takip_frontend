import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis İş Takip'),
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İş Yönetimi Bölümü
              _SectionHeader(
                title: 'İş Yönetimi',
                icon: Icons.business_center_outlined,
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.assignment_outlined,
                title: 'İş Emirleri',
                description: 'Tüm iş emirlerini görüntüleyin ve yönetin',
                color: scheme.primaryContainer,
                onTap: () => context.go('/dashboard/job-orders'),
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.map_outlined,
                title: 'Yeni İş Emri Oluştur',
                description: 'Araç hasar haritasından yeni iş emri oluşturun',
                color: scheme.secondaryContainer,
                onTap: () => context.go('/dashboard/vehicle-parts'),
              ),
              const SizedBox(height: 24),

              // Görev Yönetimi Bölümü
              _SectionHeader(
                title: 'Görev Yönetimi',
                icon: Icons.task_outlined,
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.task_alt,
                title: 'Görevlerim',
                description: 'Size atanmış görevleri görüntüleyin ve yönetin',
                color: scheme.secondaryContainer,
                onTap: () => context.go('/dashboard/my-tasks'),
              ),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.add_task,
                title: 'Müsait Görevler',
                description: 'Henüz atanmamış görevleri görüntüleyin ve alın',
                color: scheme.tertiaryContainer,
                onTap: () => context.go('/dashboard/available-tasks'),
              ),
              // Supervisor ve üzeri için ek görev yönetimi seçenekleri
              if (context.watch<AuthProvider>().canCreateJob) ...[
                const SizedBox(height: 12),
                _DashboardCard(
                  icon: Icons.assignment_ind,
                  title: 'Tüm Atanmış Görevler',
                  description:
                      'Tüm personellere atanmış görevleri görüntüleyin',
                  color: scheme.primaryContainer,
                  onTap: () => context.go('/dashboard/all-assigned-tasks'),
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  icon: Icons.pending_actions,
                  title: 'Bekleyen Görevler',
                  description: 'Henüz başlanmamış görevleri görüntüleyin',
                  color: scheme.secondaryContainer,
                  onTap: () => context.go('/dashboard/pending-tasks'),
                ),
              ],
              const SizedBox(height: 24),

              // Yönetim & Raporlar Bölümü
              if (context.watch<AuthProvider>().canCreateJob ||
                  context.watch<AuthProvider>().isAdmin) ...[
                _SectionHeader(
                  title: 'Yönetim & Raporlar',
                  icon: Icons.assessment_outlined,
                ),
                const SizedBox(height: 12),
                if (context.watch<AuthProvider>().canCreateJob)
                  _DashboardCard(
                    icon: Icons.access_time,
                    title: 'Mesai Saatleri Raporu',
                    description:
                        'İşçilerin mesai saatlerini görüntüleyin ve raporlayın',
                    color: scheme.primaryContainer,
                    onTap: () => context.go('/dashboard/worker-hours-report'),
                  ),
                if (context.watch<AuthProvider>().canCreateJob &&
                    context.watch<AuthProvider>().isAdmin)
                  const SizedBox(height: 12),
                if (context.watch<AuthProvider>().isAdmin)
                  _DashboardCard(
                    icon: Icons.people_outline,
                    title: 'Personel Yönetimi',
                    description:
                        'Personelleri görüntüleyin, ekleyin ve yönetin',
                    color: scheme.tertiaryContainer,
                    onTap: () => context.go('/dashboard/workers'),
                  ),
                const SizedBox(height: 24),
              ],

              // Diğer Bölümü
              _SectionHeader(title: 'Diğer', icon: Icons.info_outline),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.info_outline,
                title: 'Uygulama Hakkında',
                description: 'Uygulama bilgileri ve versiyon',
                color: scheme.surfaceContainerHighest,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Servis İş Takip',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.directions_car_outlined),
                  children: const [
                    Text(
                      'Kaporta ve boya servisleri için iş takibi ve hasar işaretleme sistemi.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı widget'ı
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Dashboard kartı widget'ı
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
