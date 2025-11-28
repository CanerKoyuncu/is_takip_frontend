/// Add Photo Dialog
///
/// Fotoğraf türü seçimi dialog'u.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';

/// Add photo dialog widget'ı
///
/// Kullanıcıya fotoğraf türü seçeneği sunar.
class AddPhotoDialog extends StatelessWidget {
  const AddPhotoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = _PhotoTypeOption.buildList(scheme);

    return AlertDialog(
      title: const Text('Fotoğraf Türü Seçin'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(options.length, (index) {
                final option = options[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == options.length - 1 ? 0 : 8),
                  child: _PhotoTypeTile(
                    option: option,
                    scheme: scheme,
                    onTap: () => Navigator.of(context).pop(option.type),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Her adım için ayrı fotoğraf seçerek ilerlemeyi daha iyi dokümante edebilirsiniz.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}

class _PhotoTypeOption {
  const _PhotoTypeOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final TaskPhotoType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  static List<_PhotoTypeOption> buildList(ColorScheme scheme) {
    return [
      _PhotoTypeOption(
        type: TaskPhotoType.damage,
        icon: Icons.warning_amber_rounded,
        title: TaskPhotoType.damage.label,
        description: 'Görev başlamadan önceki hasar ve araç durumunu kaydedin.',
        color: Colors.orange,
      ),
      _PhotoTypeOption(
        type: TaskPhotoType.onRepair,
        icon: Icons.build_outlined,
        title: TaskPhotoType.onRepair.label,
        description: 'Onarım sırasında alınan ara fotoğraflar.',
        color: scheme.primary,
      ),
      _PhotoTypeOption(
        type: TaskPhotoType.onPaint,
        icon: Icons.format_paint_outlined,
        title: TaskPhotoType.onPaint.label,
        description: 'Boya işlemi sonrasındaki yüzey durumunu gösterir.',
        color: Colors.purple,
      ),
      _PhotoTypeOption(
        type: TaskPhotoType.onClean,
        icon: Icons.cleaning_services_outlined,
        title: TaskPhotoType.onClean.label,
        description: 'Temizlik ve son rötuş aşamasına ait fotoğraflar.',
        color: Colors.teal,
      ),
      _PhotoTypeOption(
        type: TaskPhotoType.completion,
        icon: Icons.check_circle_outline,
        title: TaskPhotoType.completion.label,
        description: 'Görev tamamlandıktan sonraki nihai görünüm.',
        color: scheme.secondary,
      ),
    ];
  }
}

class _PhotoTypeTile extends StatelessWidget {
  const _PhotoTypeTile({
    required this.option,
    required this.scheme,
    required this.onTap,
  });

  final _PhotoTypeOption option;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                size: 24,
                color: option.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
