/// Decoder & validator NIK (Nomor Induk Kependudukan) — pure Dart,
/// zero dependency.
///
/// ```dart
/// import 'package:daily_nik/daily_nik.dart';
///
/// final nik = Nik.parse('3171010101900001');
/// print(nik.provinceName); // DKI Jakarta
/// print(nik.gender.label); // Laki-laki
/// print(nik.masked);       // 317101******0001
/// ```
library;

export 'src/nik.dart';
export 'src/nik_exception.dart';
export 'src/provinces.dart';
