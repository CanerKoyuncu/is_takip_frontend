/// Araç Parçaları Yapılandırma Dosyası
///
/// Bu dosya, SVG'den yüklenecek araç parçalarının whitelist'ini içerir.
/// Sadece burada tanımlı ID'ler hasar haritasında gösterilir.
///
/// Yeni parça eklemek için:
/// 1. SVG'de parçanın ID'sini öğrenin (örn: 'sol-on-kapi')
/// 2. Aşağıdaki map'e ID ve görünen ismini ekleyin
/// 3. Hot reload yapın

/// Yüklenecek araç parçaları whitelist'i
/// Key: SVG'deki ID, Value: Kullanıcıya gösterilecek isim
const Map<String, String> vehiclePartsWhitelist = {
  // Ön parçalar
  'kaput': 'Kaput',
  'on-tampon': 'Ön Tampon',
  'on-cam': 'Ön Cam',
  'on-tampon-demir': 'Ön Tampon Demiri',
  'on-tampon-civata': 'Ön Tampon Civataları',

  // Arka parçalar
  'bagaj-kapisi': 'Bagaj Kapağı',
  'arka-tampon': 'Arka Tampon',
  'arka-cam': 'Arka Cam',
  'arka-tampon-sol-stop': 'Arka Sol Stop',
  'arka-tampon-sag-stop': 'Arka Sağ Stop',

  // Sol taraf
  'sol-on-camurluk': 'Sol Ön Çamurluk',
  'sol-arka-camurluk': 'Sol Arka Çamurluk',
  'sol-on-dodik': 'Sol Ön Çamurluk Dodiği',
  'sol-arka-dodik': 'Sol Arka Çamurluk Dodiği',
  'sol-on-kapi': 'Sol Ön Kapı',
  'sol-arka-kapi': 'Sol Arka Kapı',
  'sol-on-etek': 'Sol Ön Marşpiyel',
  'sol-arka-etek': 'Sol Arka Marşpiyel',
  'sol-on-sis': 'Sol Ön Sis Farı',
  'sol-on-cam': 'Sol Ön Cam',
  'sol-arka-cam': 'Sol Arka Cam',
  'sol-arka-kelebek': 'Sol Arka Kelebek Cam',
  'sol-on-kapi-kolu': 'Sol Ön Kapı Kolu',
  'sol-arka-kapi-kolu': 'Sol Arka Kapı Kolu',

  // Sağ taraf
  'sag-on-camurluk': 'Sağ Ön Çamurluk',
  'sag-arka-camurluk': 'Sağ Arka Çamurluk',
  'sag-on-dodik': 'Sağ Ön Çamurluk Dodiği',
  'sag-arka-dodik': 'Sağ Arka Çamurluk Dodiği',
  'sag-on-kapi': 'Sağ Ön Kapı',
  'sag-arka-kapi': 'Sağ Arka Kapı',
  'sag-on-etek': 'Sağ Ön Marşpiyel',
  'sag-arka-etek': 'Sağ Arka Marşpiyel',
  'sag-on-sis': 'Sağ Ön Sis Farı',
  'sag-on-cam': 'Sağ Ön Cam',
  'sag-arka-cam': 'Sağ Arka Cam',
  'yakit-depo-kapagi': 'Yakıt Deposu Kapağı',
  'sag-arka-kapi-kolu': 'Sağ Arka Kapı Kolu',

  // Lastikler
  'on-sol-lastik': 'Ön Sol Lastik',
  'sol-arka-lastik': 'Arka Sol Lastik',
  'on-sag-lastik': 'Ön Sağ Lastik',
  'arka-sag-lastik': 'Arka Sağ Lastik',

  // Jantlar
  'sol-on-jant': 'Sol Ön Jant',
  'sol-arka-jant': 'Sol Arka Jant',
  'sag-on-jant': 'Sağ Ön Jant',
  'sag-arka-jant': 'Sağ Arka Jant',

  // Tavan ve diğerleri
  'tavan': 'Tavan',
  'sunroof': 'Sunroof',
};

/// Teknik ID'leri anlamlı ID'lere çeviren map (opsiyonel)
/// Eğer SVG'de teknik ID varsa ve anlamlı bir isimle eşleştirmek istiyorsanız kullanın
const Map<String, String> technicalIdMapping = {
  'path682': 'sag-orta-cam',
  // İleride başka teknik ID'ler eklenebilir
};
