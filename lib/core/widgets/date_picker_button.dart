/// Date Picker Button Widget
///
/// Tarih seçimi için standart buton widget'ı.
/// Filtreleme ve form ekranlarında kullanılır.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date picker button widget'ı
///
/// Tarih seçimi için buton gösterir ve seçilen tarihi gösterir.
class DatePickerButton extends StatelessWidget {
  const DatePickerButton({
    super.key,
    required this.label,
    this.selectedDate,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.locale = const Locale('tr', 'TR'),
  });

  /// Buton etiketi
  final String label;

  /// Seçili tarih
  final DateTime? selectedDate;

  /// Tarih seçildiğinde callback
  final ValueChanged<DateTime>? onDateSelected;

  /// İlk tarih (varsayılan: 2020-01-01)
  final DateTime? firstDate;

  /// Son tarih (varsayılan: bugünden 1 yıl sonra)
  final DateTime? lastDate;

  /// Başlangıç tarihi (varsayılan: seçili tarih veya bugün)
  final DateTime? initialDate;

  /// Locale (varsayılan: tr_TR)
  final Locale locale;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: locale,
    );

    if (picked != null && onDateSelected != null) {
      onDateSelected!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _selectDate(context),
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        selectedDate != null
            ? DateFormat(
                'dd.MM.yyyy',
                locale.languageCode,
              ).format(selectedDate!)
            : label,
      ),
    );
  }
}
