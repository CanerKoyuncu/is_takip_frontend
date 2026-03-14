/// Araç Parçaları Veri Tanımı
///
/// Tüm araç parçaları bu dosyada JSON-benzeri bir yapıda tanımlanmıştır.
/// Hem SVG yükleyici (SvgVehiclePartLoader) hem de widget konfigürasyonu
/// (VehicleMapConfiguration) bu veriyi kullanır.
///
/// Alan açıklamaları:
/// - id              : SVG grubu ID'si (zorunlu)
/// - name            : Türkçe görünen isim (zorunlu)
/// - allowedActions  : İzin verilen hasar işlemleri
/// - allowBoundsHitTest: true → bounding-box ile hit test yap (lastik, jant gibi)
/// - aliasFor        : Bu ID, SVG'de başka bir ID olarak geçer (path682 gibi)
/// - spareParts      : Bu parça için gereken yedek parçalar listesi
///   - name          : Yedek parça adı
///   - supplySource  : 'sigorta' | 'kendi'
///   - quantity      : Adet (varsayılan: 1)

// ignore_for_file: prefer_single_quotes

/// Tedarik kaynağı — sigorta tedariği mi yoksa kendi alımı mı.
enum PartSupplySource {
  /// Sigorta şirketi tarafından temin edilir.
  sigorta,

  /// İşletme tarafından temin edilir.
  kendi,
}

/// Bir araç parçasının yedek parça kalemi.
class SparePartItem {
  const SparePartItem({
    required this.name,
    required this.supplySource,
    this.quantity = 1,
    this.partCode,
    this.notes,
  });

  /// Yedek parçanın adı (örn. "Kaput Paneli")
  final String name;

  /// Kim temin eder — sigorta mı, biz mi?
  final PartSupplySource supplySource;

  /// Gereken adet
  final int quantity;

  /// OEM veya tedarikçi parça kodu (opsiyonel — kullanıcı tarafından girilebilir)
  final String? partCode;

  /// Parçaya özel not (opsiyonel)
  final String? notes;

  factory SparePartItem.fromMap(Map<String, dynamic> map) {
    return SparePartItem(
      name: map['name'] as String,
      supplySource: map['supplySource'] == 'sigorta'
          ? PartSupplySource.sigorta
          : PartSupplySource.kendi,
      quantity: (map['quantity'] as int?) ?? 1,
      partCode: map['partCode'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'supplySource': supplySource.name,
        'quantity': quantity,
        if (partCode != null) 'partCode': partCode,
        if (notes != null) 'notes': notes,
      };

  SparePartItem copyWith({
    String? name,
    PartSupplySource? supplySource,
    int? quantity,
    Object? partCode = _sentinel,
    Object? notes = _sentinel,
  }) {
    return SparePartItem(
      name: name ?? this.name,
      supplySource: supplySource ?? this.supplySource,
      quantity: quantity ?? this.quantity,
      partCode: partCode == _sentinel ? this.partCode : partCode as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
    );
  }
}

// Sentinel for distinguishing null from "not provided" in copyWith
const Object _sentinel = Object();

/// Tek bir araç parçasının tam tanımı.
///
/// SVG yükleyici ve hasar haritası widget'ı bu modeli paylaşarak
/// veri çoğaltmasını önler.
class VehiclePartDefinition {
  const VehiclePartDefinition({
    required this.id,
    required this.name,
    this.allowedActions = const [],
    this.allowBoundsHitTest = false,
    this.spareParts = const [],
    this.aliasFor,
  });

  /// SVG grup ID'si — `_defaultPartConfigs` anahtarı olarak kullanılır.
  final String id;

  /// Türkçe görünen isim.
  final String name;

  /// Bu parça için izin verilen hasar işlemleri.
  /// Örnek: ['boya', 'kaporta', 'degisim', 'temizle']
  final List<String> allowedActions;

  /// Bounding-box hit-test kullan (lastik, jant gibi yuvarlak/büyük parçalar).
  final bool allowBoundsHitTest;

  /// Bu parça için gereken yedek parçalar.
  final List<SparePartItem> spareParts;

  /// SVG'deki gerçek ID farklıysa (örn. 'path682' → 'sag-orta-cam').
  final String? aliasFor;

  factory VehiclePartDefinition.fromMap(Map<String, dynamic> map) {
    final rawSpareParts = map['spareParts'] as List<dynamic>? ?? const [];
    return VehiclePartDefinition(
      id: map['id'] as String,
      name: map['name'] as String,
      allowedActions: List<String>.from(
        map['allowedActions'] as List<dynamic>? ?? const [],
      ),
      allowBoundsHitTest: (map['allowBoundsHitTest'] as bool?) ?? false,
      spareParts: rawSpareParts
          .map((e) => SparePartItem.fromMap(e as Map<String, dynamic>))
          .toList(growable: false),
      aliasFor: map['aliasFor'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Tüm araç parçaları — JSON benzeri const tanım
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> kVehiclePartsData = [
  // ===== TAMPON VE KAPUT =====
  {
    'id': 'on-tampon',
    'name': 'Ön Tampon',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Ön Tampon Gövdesi', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'on-tampon-demir',
    'name': 'Ön Tampon Demiri',
    'allowedActions': ['boya', 'degisim'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Tampon Demiri', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'on-tampon-civata',
    'name': 'Ön Tampon Civataları',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Civata Seti', 'supplySource': 'kendi', 'quantity': 4},
    ],
  },
  {
    'id': 'arka-tampon',
    'name': 'Arka Tampon',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Arka Tampon Gövdesi', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'arka-tampon-sol-stop',
    'name': 'Arka Sol Stop',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Stop Lambası', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'arka-tampon-sag-stop',
    'name': 'Arka Sağ Stop',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Stop Lambası', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  // ===== KAPUT VE BAGAJ =====
  {
    'id': 'kaput',
    'name': 'Kaput',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Kaput Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Kaput Menteşesi', 'supplySource': 'kendi', 'quantity': 2},
      {'name': 'Kaput Kilidi', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'bagaj-kapisi',
    'name': 'Bagaj Kapağı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Bagaj Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Bagaj Menteşesi', 'supplySource': 'kendi', 'quantity': 2},
    ],
  },
  {
    'id': 'tavan',
    'name': 'Tavan',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Tavan Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sunroof',
    'name': 'Sunroof',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sunroof Camı', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Sunroof Mekanizması', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  // ===== SOL ÖN TARAF =====
  {
    'id': 'sol-on-camurluk',
    'name': 'Sol Ön Çamurluk',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Ön Çamurluk Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-kapi',
    'name': 'Sol Ön Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Ön Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Kapı İç Mekanizması', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-kapı',
    'name': 'Sol Ön Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'aliasFor': 'sol-on-kapi',
    'spareParts': [
      {'name': 'Sol Ön Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-etek',
    'name': 'Sol Marşpiyel',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Ön Marşpiyel', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-dodik',
    'name': 'Sol Ön Marşpiyel',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Ön Dodik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-sis',
    'name': 'Sol Ön Sis Farı',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Sis Farı', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Sis Farı Çerçevesi', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== SOL ARKA TARAF =====
  {
    'id': 'sol-arka-camurluk',
    'name': 'Sol Arka Çamurluk',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Arka Çamurluk Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-kapi',
    'name': 'Sol Arka Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Arka Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Kapı İç Mekanizması', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-kapı',
    'name': 'Sol Arka Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'aliasFor': 'sol-arka-kapi',
    'spareParts': [
      {'name': 'Sol Arka Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-dodik',
    'name': 'Sol Arka Marşpiyel',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Arka Dodik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-kapi-kolu',
    'name': 'Sol Ön Kapı Kolu',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Kapı Kolu', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-kapi-kolu',
    'name': 'Sol Arka Kapı Kolu',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Kapı Kolu', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== SAĞ ÖN TARAF =====
  {
    'id': 'sag-on-camurluk',
    'name': 'Sağ Ön Çamurluk',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Ön Çamurluk Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-kapi',
    'name': 'Sağ Ön Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Ön Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Kapı İç Mekanizması', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-kapı',
    'name': 'Sağ Ön Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'aliasFor': 'sag-on-kapi',
    'spareParts': [
      {'name': 'Sağ Ön Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-etek',
    'name': 'Sağ Ön Marşpiyel',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Ön Marşpiyel', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-dodik',
    'name': 'Sağ Ön Marşpiyel',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Ön Dodik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-sis',
    'name': 'Sağ Ön Sis Farı',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Sis Farı', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Sis Farı Çerçevesi', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-kapi-kolu',
    'name': 'Sağ Ön Kapı Kolu',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Kapı Kolu', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== SAĞ ARKA TARAF =====
  {
    'id': 'sag-arka-camurluk',
    'name': 'Sağ Arka Çamurluk',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Arka Çamurluk Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-kapi',
    'name': 'Sağ Arka Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Arka Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Kapı İç Mekanizması', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-kapı',
    'name': 'Sağ Arka Kapı',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'aliasFor': 'sag-arka-kapi',
    'spareParts': [
      {'name': 'Sağ Arka Kapı Paneli', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-etek',
    'name': 'Sağ Arka Marşpiyel',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Arka Marşpiyel', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-dodik',
    'name': 'Sağ Arka Marşpiyel',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Arka Dodik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-kapi-kolu',
    'name': 'Sağ Arka Kapı Kolu',
    'allowedActions': ['boya', 'kaporta', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Kapı Kolu', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== CAMLAR =====
  {
    'id': 'on-cam',
    'name': 'Ön Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Ön Cam', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Cam Fitili', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'arka-cam',
    'name': 'Arka Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Arka Cam', 'supplySource': 'sigorta', 'quantity': 1},
      {'name': 'Cam Fitili', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-on-cam',
    'name': 'Sol Ön Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Ön Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-cam',
    'name': 'Sol Arka Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Arka Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-kelebek',
    'name': 'Sol Arka Kelebek Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sol Kelebek Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-cam',
    'name': 'Sağ Ön Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Ön Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-orta-cam',
    'name': 'Sağ Orta Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Orta Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    // Teknik SVG ID alias — gerçek anlam: sag-orta-cam
    'id': 'path682',
    'name': 'Sağ Orta Cam',
    'allowedActions': ['degisim', 'temizle'],
    'aliasFor': 'sag-orta-cam',
    'spareParts': [
      {'name': 'Sağ Orta Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-cam',
    'name': 'Sağ Arka Cam',
    'allowedActions': ['degisim', 'temizle'],
    'spareParts': [
      {'name': 'Sağ Arka Kapı Camı', 'supplySource': 'sigorta', 'quantity': 1},
    ],
  },
  // ===== LASTİKLER =====
  {
    'id': 'on-sol-lastik',
    'name': 'Ön Sol Lastik',
    'allowedActions': ['degisim', 'temizle'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Lastik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-lastik',
    'name': 'Arka Sol Lastik',
    'allowedActions': ['degisim', 'temizle'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Lastik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'on-sag-lastik',
    'name': 'Ön Sağ Lastik',
    'allowedActions': ['degisim', 'temizle'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Lastik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'arka-sag-lastik',
    'name': 'Arka Sağ Lastik',
    'allowedActions': ['degisim', 'temizle'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Lastik', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== JANTLAR =====
  {
    'id': 'sol-on-jant',
    'name': 'Sol Ön Jant',
    'allowedActions': ['boya', 'degisim'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Jant', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-on-jant',
    'name': 'Sağ Ön Jant',
    'allowedActions': ['boya', 'degisim'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Jant', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sol-arka-jant',
    'name': 'Sol Arka Jant',
    'allowedActions': ['boya', 'degisim'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Jant', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  {
    'id': 'sag-arka-jant',
    'name': 'Sağ Arka Jant',
    'allowedActions': ['boya', 'degisim'],
    'allowBoundsHitTest': true,
    'spareParts': [
      {'name': 'Jant', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
  // ===== YAKIT DEPOSU =====
  {
    'id': 'yakit-depo-kapagi',
    'name': 'Yakıt Deposu Kapağı',
    'allowedActions': ['boya', 'degisim', 'temizle'],
    'spareParts': [
      {'name': 'Yakıt Deposu Kapağı', 'supplySource': 'kendi', 'quantity': 1},
    ],
  },
];
