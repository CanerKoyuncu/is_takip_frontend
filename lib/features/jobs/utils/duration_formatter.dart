class DurationFormatter {
  const DurationFormatter._();

  static String longFromSeconds(num seconds) {
    final totalMinutes = _totalMinutesFromSeconds(seconds);
    return _formatMinutes(totalMinutes, shortLabels: false);
  }

  static String longFromHours(num hours) {
    return longFromSeconds(hours * 3600);
  }

  static String shortFromSeconds(num seconds) {
    final totalMinutes = _totalMinutesFromSeconds(seconds);
    return _formatMinutes(totalMinutes, shortLabels: true);
  }

  static String shortFromHours(num hours) {
    return shortFromSeconds(hours * 3600);
  }

  static int _totalMinutesFromSeconds(num seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) {
      return 0;
    }
    return (seconds / 60).round();
  }

  static String _formatMinutes(int totalMinutes, {required bool shortLabels}) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return shortLabels
          ? '$hours s $minutes dk'
          : '$hours saat $minutes dakika';
    }
    if (hours > 0) {
      return shortLabels ? '$hours s' : '$hours saat';
    }
    return shortLabels ? '$minutes dk' : '$minutes dakika';
  }
}
