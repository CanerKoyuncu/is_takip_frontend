/// Jobs Services - Merkezi Export Dosyası
///
/// Bu dosya tüm jobs servislerini organize ve merkezi olarak export eder.
/// Diğer dosyalardan daha temiz import'lar yapılmasını sağlar.

// API Services
export 'api/jobs_api_service.dart';
export 'api/archive_api_service.dart';
export 'api/reception_api_service.dart';
export 'api/reports_api_service.dart';
export 'api/workers_api_service.dart';

// Cache Services
export 'cache/job_creation_cache_service.dart';
export 'cache/photo_cache_service.dart';

// Photo Services
export 'photo/photo_service.dart';

// PDF Services
export 'pdf/pdf_base_service.dart';
export 'pdf/pdf_job_order_service.dart';
export 'pdf/pdf_reception_report_service.dart';
export 'pdf/pdf_report_metadata.dart';
export 'pdf/pdf_styles.dart';
// PDF Helpers (conditional - sadece biri export edilir runtime sırasında)
export 'pdf/pdf_web_helper_stub.dart';

// Not: pdf_web_helper.dart conditional import ile kullanılır
// if (dart.library.html) 'pdf/pdf_web_helper.dart'

// PDF Builders
export 'pdf/pdf_builders/pdf_footer_builder.dart';
export 'pdf/pdf_builders/pdf_header_builder.dart';
export 'pdf/pdf_builders/pdf_helper_widgets.dart';
export 'pdf/pdf_builders/pdf_job_info_builder.dart';
export 'pdf/pdf_builders/pdf_notes_builder.dart';
export 'pdf/pdf_builders/pdf_tasks_builder.dart';
export 'pdf/pdf_builders/pdf_vehicle_info_builder.dart';
