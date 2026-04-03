class ServerDateTimeParser {
  const ServerDateTimeParser._();

  static final RegExp _hasTimezoneSuffix = RegExp(r'(Z|[+-]\d{2}:\d{2})$');

  static DateTime? parseNullable(
    dynamic value, {
    bool assumeUtcIfNoOffset = true,
  }) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.isUtc ? value.toLocal() : value;
    }

    if (value is! String) {
      return null;
    }

    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }

    var normalized = raw;
    if (assumeUtcIfNoOffset &&
        _hasTimeComponent(raw) &&
        !_hasTimezoneSuffix.hasMatch(raw)) {
      normalized = raw.replaceFirst(' ', 'T');
      normalized = '${normalized}Z';
    }

    final parsed = DateTime.parse(normalized);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static DateTime parseRequired(
    dynamic value, {
    DateTime? fallback,
    bool assumeUtcIfNoOffset = true,
  }) {
    return parseNullable(value, assumeUtcIfNoOffset: assumeUtcIfNoOffset) ??
        fallback ??
        DateTime.now();
  }

  static bool _hasTimeComponent(String value) {
    return value.contains('T') || value.contains(' ');
  }
}
