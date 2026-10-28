import 'package:daily_nik/daily_nik.dart';

/// Demo `daily_nik` — jalankan dengan `dart run example/main.dart`.
///
/// Semua NIK di sini SINTETIS (disusun dari pola struktur NIK).
void main() {
  const samples = [
    // Laki-laki, lahir 1 Januari 1990, DKI Jakarta.
    '3171010101900001',
    // Perempuan, lahir 15 Juni 2000, Jawa Barat (hari tertulis 55).
    '3273015506000002',
    // Bukan NIK: sengaja tidak valid, untuk demo error-nya.
    '9971010101900001',
  ];

  for (final sample in samples) {
    final nik = Nik.tryParse(sample, referenceDate: DateTime(2026, 10, 28));
    if (nik == null) {
      try {
        Nik.parse(sample);
      } on NikFormatException catch (e) {
        print('$sample -> TIDAK VALID (${e.reason.name})');
      }
      continue;
    }
    print('${nik.formatted} (${nik.masked})');
    print('  Provinsi   : ${nik.provinceName}');
    print('  Lahir      : ${nik.birthDate.year}-'
        '${nik.birthDate.month.toString().padLeft(2, '0')}-'
        '${nik.birthDate.day.toString().padLeft(2, '0')}');
    print('  Gender     : ${nik.gender.label}');
    print('  Umur       : ${nik.ageOn(DateTime(2026, 10, 28))} tahun');
    print('  Nomor urut : ${nik.sequence}');
  }
}
