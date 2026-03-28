/// Araç teslim alma (intake) modelleri.

/// Teslim alma aşamasındaki bir fotoğrafı temsil eder.
class ReceptionPhoto {
  const ReceptionPhoto({
    required this.originalPath,
    this.annotatedPath,
    this.note,
    this.damageTypes = const [], // Seçilen hasar türleri
    this.partId, // Opsiyonel: Hangi parçaya ait (Örn: front_hood)
    this.partName, // Opsiyonel: Parçanın adı (Örn: Ön Kaput)
  });

  final String originalPath;
  final String? annotatedPath;
  final String? note;
  final List<String> damageTypes;
  final String? partId;
  final String? partName;

  /// Tanımlı standart hasar türleri
  static const List<String> standardizedTypes = [
    'Vuruk',
    'Göçük',
    'Çizik',
    'Sürtme',
    'Leke',
    'Kırık',
  ];

  /// Dosya yolunu veya işaretli yolu döndürür
  String get displayPath => annotatedPath ?? originalPath;

  /// Bilgileri kopyalar ve günceller
  ReceptionPhoto copyWith({
    String? originalPath,
    String? annotatedPath,
    String? note,
    List<String>? damageTypes,
    String? partId,
    String? partName,
  }) {
    return ReceptionPhoto(
      originalPath: originalPath ?? this.originalPath,
      annotatedPath: annotatedPath ?? this.annotatedPath,
      note: note ?? this.note,
      damageTypes: damageTypes ?? this.damageTypes,
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
    );
  }

  /// Map'e dönüştürür (Cache için)
  Map<String, dynamic> toMap() {
    return {
      'originalPath': originalPath,
      'annotatedPath': annotatedPath,
      'note': note,
      'damageTypes': damageTypes,
      'partId': partId,
      'partName': partName,
    };
  }

  /// Map'ten oluşturur (Cache için)
  factory ReceptionPhoto.fromMap(Map<String, dynamic> map) {
    return ReceptionPhoto(
      originalPath: map['originalPath'] as String,
      annotatedPath: map['annotatedPath'] as String?,
      note: map['note'] as String?,
      damageTypes: List<String>.from(map['damageTypes'] ?? []),
      partId: map['partId'] as String?,
      partName: map['partName'] as String?,
    );
  }
}
