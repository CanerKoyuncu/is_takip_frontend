/// Hasar Raporu Modeli
///
/// İş emirleri sırasında oluşturulan araç hasar raporlarını temsil eder.

class DamageReport {
  DamageReport({
    required this.id,
    required this.jobOrderId,
    required this.damages,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Hasar raporu ID'si
  final String id;

  /// İş emri ID'si
  final String jobOrderId;

  /// Hasarlı parçalar ve aksiyonlar
  /// Format: {"part-id": ["boya", "kaporta"]}
  final Map<String, List<String>> damages;

  /// Hasar notları
  final String? notes;

  /// Oluşturulma tarihi
  final DateTime? createdAt;

  /// Son güncelleme tarihi
  final DateTime? updatedAt;

  /// JSON'dan DamageReport oluştur
  factory DamageReport.fromJson(Map<String, dynamic> json) {
    return DamageReport(
      id: json['id'] as String? ?? '',
      jobOrderId: json['jobOrderId'] as String? ?? '',
      damages: _parseDamages(json['damages']),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// DamageReport'u JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobOrderId': jobOrderId,
      'damages': damages,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Hasarlar bölümünü parse et
  static Map<String, List<String>> _parseDamages(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.cast<String, dynamic>().map((key, val) {
        final actions = val is List ? List<String>.from(val) : <String>[];
        return MapEntry(key, actions);
      });
    }
    return {};
  }

  /// DamageReport'un kopyasını oluştur (güncelleme için)
  DamageReport copyWith({
    String? id,
    String? jobOrderId,
    Map<String, List<String>>? damages,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DamageReport(
      id: id ?? this.id,
      jobOrderId: jobOrderId ?? this.jobOrderId,
      damages: damages ?? this.damages,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'DamageReport(id: $id, jobOrderId: $jobOrderId, damages: $damages)';
}

/// Hasar Raporu Taslağı (oluşturma sırasında kullanılır)
class DamageReportDraft {
  DamageReportDraft({this.damages = const {}, this.notes});

  /// Hasarlı parçalar ve aksiyonlar
  final Map<String, List<String>> damages;

  /// Hasar notları
  final String? notes;

  /// Taslağın kopyasını oluştur
  DamageReportDraft copyWith({
    Map<String, List<String>>? damages,
    String? notes,
  }) {
    return DamageReportDraft(
      damages: damages ?? this.damages,
      notes: notes ?? this.notes,
    );
  }

  /// DamageReport'a çevir
  DamageReport toDamageReport({
    required String id,
    required String jobOrderId,
  }) {
    return DamageReport(
      id: id,
      jobOrderId: jobOrderId,
      damages: damages,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'DamageReportDraft(damages: $damages, notes: $notes)';
}
