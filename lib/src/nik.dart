import 'nik_exception.dart';
import 'provinces.dart';

/// Jenis kelamin yang terkode di NIK.
///
/// Di NIK, perempuan ditandai dengan hari lahir +40 (mis. lahir tanggal
/// 1 untuk perempuan tertulis 41). Laki-laki memakai hari apa adanya.
enum NikGender {
  /// Laki-laki (hari lahir 01–31).
  male,

  /// Perempuan (hari lahir tertulis 41–71).
  female;

  /// Label Bahasa Indonesia untuk UI.
  String get label => switch (this) {
        NikGender.male => 'Laki-laki',
        NikGender.female => 'Perempuan',
      };

  /// Nilai yang dipakai di JSON (`"male"` / `"female"`).
  String get value => name;
}

/// Hasil decode satu Nomor Induk Kependudukan (NIK) 16 digit.
///
/// Objek ini immutable dan tidak pernah menyimpan apa pun selain hasil
/// decode dari string inputnya sendiri. Tidak ada network, tidak ada
/// lookup eksternal: semua field dihitung lokal dari 16 digit.
///
/// Struktur NIK (PP Nomor 37 Tahun 2007, Pasal 33):
/// `PP KK CC DDMMYY SSSS` — provinsi, kabupaten/kota, kecamatan,
/// tanggal lahir (hari +40 untuk perempuan), nomor urut.
///
/// Penting: NIK yang lolos parse di sini baru terbukti _strukturnya_
/// valid. Package ini tidak memverifikasi apakah NIK tersebut terdaftar
/// di Dukcapil.
///
/// Contoh:
/// ```dart
/// final nik = Nik.parse('3171010101900001');
/// print(nik.provinceName); // DKI Jakarta
/// print(nik.birthDate);    // 1990-01-01 00:00:00.000
/// print(nik.gender.label); // Laki-laki
/// ```
class Nik {
  /// Membaca [input] sebagai NIK dan mengembalikan hasil decode-nya.
  ///
  /// Pemisah spasi, titik, dan strip diabaikan (`"3171-01-010190-0001"`
  /// sama dengan `"3171010101900001"`).
  ///
  /// [referenceDate] dipakai untuk dua hal: menentukan abad dari tahun
  /// 2 digit, dan menolak tanggal lahir di masa depan. Default-nya
  /// tanggal hari ini; parameter ini ada supaya perilaku parse bisa
  /// diuji secara deterministik.
  ///
  /// Throws [NikFormatException] dengan [NikFormatReason] yang spesifik
  /// bila input tidak bisa dibaca. Gunakan [tryParse] bila ingin hasil
  /// `null` daripada exception.
  factory Nik.parse(String input, {DateTime? referenceDate}) {
    final reference = _dateOnly(referenceDate ?? DateTime.now());
    final digits = _normalize(input);
    if (digits.isEmpty) {
      throw const NikFormatException(
        NikFormatReason.empty,
        'NIK kosong.',
      );
    }
    if (digits.length != 16) {
      throw NikFormatException(
        NikFormatReason.wrongLength,
        'NIK harus 16 digit, didapat ${digits.length} digit.',
      );
    }
    if (!_isAllDigits(digits)) {
      throw const NikFormatException(
        NikFormatReason.nonDigit,
        'NIK hanya boleh berisi angka.',
      );
    }

    final provinceCode = digits.substring(0, 2);
    final regencyCode = digits.substring(2, 4);
    final districtCode = digits.substring(4, 6);
    final rawDay = int.parse(digits.substring(6, 8));
    final month = int.parse(digits.substring(8, 10));
    final shortYear = int.parse(digits.substring(10, 12));
    final sequence = int.parse(digits.substring(12, 16));

    final provinceName = provinceNames[provinceCode];
    if (provinceName == null) {
      throw NikFormatException(
        NikFormatReason.unknownProvince,
        'Kode provinsi $provinceCode tidak dikenal.',
      );
    }
    if (regencyCode == '00') {
      throw const NikFormatException(
        NikFormatReason.invalidRegency,
        'Kode kabupaten/kota tidak boleh 00.',
      );
    }
    if (districtCode == '00') {
      throw const NikFormatException(
        NikFormatReason.invalidDistrict,
        'Kode kecamatan tidak boleh 00.',
      );
    }
    if (sequence == 0) {
      throw const NikFormatException(
        NikFormatReason.invalidSequence,
        'Nomor urut tidak boleh 0000.',
      );
    }

    final gender = rawDay > 40 ? NikGender.female : NikGender.male;
    final day = gender == NikGender.female ? rawDay - 40 : rawDay;
    final year = shortYear <= reference.year % 100
        ? 2000 + shortYear
        : 1900 + shortYear;

    final birthDate = _validDate(year, month, day);
    if (birthDate == null) {
      throw NikFormatException(
        NikFormatReason.invalidBirthDate,
        'Tanggal lahir $day/$month/$year tidak ada di kalender.',
      );
    }
    if (birthDate.isAfter(reference)) {
      throw const NikFormatException(
        NikFormatReason.futureBirthDate,
        'Tanggal lahir masih di masa depan.',
      );
    }

    return Nik._(
      raw: digits,
      provinceCode: provinceCode,
      provinceName: provinceName,
      regencyCode: regencyCode,
      districtCode: districtCode,
      birthDate: birthDate,
      gender: gender,
      sequence: sequence,
    );
  }

  const Nik._({
    required this.raw,
    required this.provinceCode,
    required this.provinceName,
    required this.regencyCode,
    required this.districtCode,
    required this.birthDate,
    required this.gender,
    required this.sequence,
  });

  /// Mencoba membaca [input] sebagai NIK.
  ///
  /// Mengembalikan `null` untuk input `null` atau tidak valid, tidak
  /// pernah throw. Untuk mengetahui _kenapa_ gagal, pakai [parse] dan
  /// tangkap [NikFormatException].
  static Nik? tryParse(String? input, {DateTime? referenceDate}) {
    if (input == null) return null;
    try {
      return Nik.parse(input, referenceDate: referenceDate);
    } on NikFormatException {
      return null;
    }
  }

  /// `true` bila [input] adalah NIK yang valid secara struktural.
  ///
  /// Tidak pernah throw, termasuk untuk input `null`.
  static bool isValid(String? input, {DateTime? referenceDate}) =>
      tryParse(input, referenceDate: referenceDate) != null;

  /// Membuat [Nik] dari map hasil [toJson].
  ///
  /// Kunci `nik` wajib ada; field lainnya diabaikan dan dihitung ulang
  /// dari NIK itu sendiri, jadi map yang diedit manual tidak bisa
  /// memalsukan hasil decode.
  factory Nik.fromJson(Map<String, dynamic> json) {
    final raw = json['nik'];
    if (raw is! String) {
      throw const NikFormatException(
        NikFormatReason.empty,
        'Field "nik" pada JSON harus berupa string.',
      );
    }
    return Nik.parse(raw);
  }

  /// 16 digit NIK, sudah dinormalisasi (tanpa pemisah).
  final String raw;

  /// Kode provinsi, digit 1–2.
  final String provinceCode;

  /// Nama provinsi dari [provinceCode].
  final String provinceName;

  /// Kode kabupaten/kota, digit 3–4.
  ///
  /// Hanya kode yang dikembalikan: nama kabupaten/kota sengaja tidak
  /// dipetakan (lihat README, bagian "Batasan jujur").
  final String regencyCode;

  /// Kode kecamatan, digit 5–6.
  ///
  /// Hanya kode yang dikembalikan, dengan alasan yang sama seperti
  /// [regencyCode].
  final String districtCode;

  /// Tanggal lahir (jam 00:00).
  final DateTime birthDate;

  /// Jenis kelamin yang terkode di NIK.
  final NikGender gender;

  /// Nomor urut, digit 13–16, sebagai angka (1–9999).
  final int sequence;

  /// NIK yang dikelompokkan sesuai strukturnya, enak dibaca manusia.
  ///
  /// Contoh: `"3171010101900001"` → `"31.71.01.010190.0001"`.
  String get formatted =>
      '${raw.substring(0, 2)}.${raw.substring(2, 4)}.'
      '${raw.substring(4, 6)}.${raw.substring(6, 12)}.'
      '${raw.substring(12, 16)}';

  /// NIK dengan 6 digit tengah disamarkan — aman untuk UI dan log.
  ///
  /// Contoh: `"3171010101900001"` → `"317101******0001"`.
  String get masked => '${raw.substring(0, 6)}******${raw.substring(12)}';

  /// Umur dalam tahun penuh pada [date].
  ///
  /// Seseorang yang belum ulang tahun pada tahun [date] dihitung
  /// setahun lebih muda (umur ulang tahun, bukan selisih tahun).
  int ageOn(DateTime date) {
    final on = _dateOnly(date);
    var age = on.year - birthDate.year;
    if (on.month < birthDate.month ||
        (on.month == birthDate.month && on.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Umur dalam tahun penuh hari ini.
  int get age => ageOn(DateTime.now());

  /// Serialisasi ke JSON.
  ///
  /// `birthDate` memakai format ISO-8601, `gender` memakai
  /// `"male"`/`"female"`.
  Map<String, Object?> toJson() => {
        'nik': raw,
        'provinceCode': provinceCode,
        'provinceName': provinceName,
        'regencyCode': regencyCode,
        'districtCode': districtCode,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender.value,
        'sequence': sequence,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nik && runtimeType == other.runtimeType && raw == other.raw;

  @override
  int get hashCode => raw.hashCode;

  /// Sengaja TIDAK menampilkan NIK lengkap: log tidak boleh menjadi
  /// tempat kebocoran data pribadi. Pakai [masked] bila perlu
  /// menampilkan NIK.
  @override
  String toString() =>
      'Nik(province: $provinceName, birthDate: ${_isoDate(birthDate)}, '
      'gender: ${gender.label})';
}

/// Menghapus pemisah yang umum ditempel dari form: spasi, titik, strip.
String _normalize(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == ' ' || char == '.' || char == '-') continue;
    buffer.write(char);
  }
  return buffer.toString();
}

bool _isAllDigits(String value) {
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if (code < 0x30 || code > 0x39) return false;
  }
  return true;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Mengembalikan tanggal yang valid, atau `null` bila tidak ada.
///
/// `DateTime` di Dart me-"roll over" tanggal mustahil (mis. 30 Februari
/// menjadi 2 Maret), jadi kecocokan komponen harus dicek ulang.
DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
