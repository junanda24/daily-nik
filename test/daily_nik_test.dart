import 'package:daily_nik/daily_nik.dart';
import 'package:test/test.dart';

// Semua NIK di file ini SINTETIS: disusun dari pola struktur NIK,
// bukan milik orang nyata mana pun. Jangan pakai NIK asli di test.
void main() {
  // Tanggal referensi tetap supaya test tidak bergantung pada hari
  // eksekusi (tahun 2 digit dipetakan relatif terhadap tanggal ini).
  final reference = DateTime(2026, 10, 28);

  group('parse laki-laki', () {
    test('membaca semua field dari NIK sintetis', () {
      final nik = Nik.parse('3171010101900001', referenceDate: reference);
      expect(nik.raw, '3171010101900001');
      expect(nik.provinceCode, '31');
      expect(nik.provinceName, 'DKI Jakarta');
      expect(nik.regencyCode, '71');
      expect(nik.districtCode, '01');
      expect(nik.birthDate, DateTime(1990, 1, 1));
      expect(nik.gender, NikGender.male);
      expect(nik.gender.label, 'Laki-laki');
      expect(nik.sequence, 1);
    });

    test('menerima pemisah spasi, titik, dan strip', () {
      expect(
        Nik.parse('3171-01-010190-0001', referenceDate: reference).raw,
        '3171010101900001',
      );
      expect(
        Nik.parse('31.71.01.010190.0001', referenceDate: reference).raw,
        '3171010101900001',
      );
      expect(
        Nik.parse(' 3171010101900001 ', referenceDate: reference).raw,
        '3171010101900001',
      );
    });
  });

  group('jenis kelamin perempuan (+40)', () {
    test('hari 41 dibaca sebagai tanggal 1 perempuan', () {
      final nik = Nik.parse('3171014101900001', referenceDate: reference);
      expect(nik.gender, NikGender.female);
      expect(nik.gender.label, 'Perempuan');
      expect(nik.birthDate, DateTime(1990, 1, 1));
    });

    test('hari 55 dibaca sebagai tanggal 15 perempuan', () {
      final nik = Nik.parse('3273015506000002', referenceDate: reference);
      expect(nik.gender, NikGender.female);
      expect(nik.birthDate, DateTime(2000, 6, 15));
      expect(nik.provinceName, 'Jawa Barat');
      expect(nik.sequence, 2);
    });
  });

  group('tahun 2 digit & tanggal kabisat', () {
    test('tahun 55 dipetakan ke 1955, tahun 05 ke 2005', () {
      expect(
        Nik.parse('3171011503550004', referenceDate: reference).birthDate,
        DateTime(1955, 3, 15),
      );
      expect(
        Nik.parse('3171010202050005', referenceDate: reference).birthDate,
        DateTime(2005, 2, 2),
      );
    });

    test('batas abad: 26 -> 2026, 27 -> 1927', () {
      expect(
        Nik.parse('3171010101260006', referenceDate: reference).birthDate,
        DateTime(2026, 1, 1),
      );
      expect(
        Nik.parse('3171010101270007', referenceDate: reference).birthDate,
        DateTime(1927, 1, 1),
      );
    });

    test('29 Februari diterima di tahun kabisat saja', () {
      expect(
        Nik.parse('3171012902000003', referenceDate: reference).birthDate,
        DateTime(2000, 2, 29),
      );
      expect(
        () => Nik.parse('3171012902010001', referenceDate: reference),
        throwsA(
          isA<NikFormatException>().having(
            (e) => e.reason,
            'reason',
            NikFormatReason.invalidBirthDate,
          ),
        ),
      );
    });
  });

  group('validasi & alasan error', () {
    final cases = <String, NikFormatReason>{
      '': NikFormatReason.empty,
      '   ': NikFormatReason.empty,
      '317101010190000': NikFormatReason.wrongLength,
      '31710101019000011': NikFormatReason.wrongLength,
      '317101010190000A': NikFormatReason.nonDigit,
      '9971010101900001': NikFormatReason.unknownProvince,
      '3100010101900001': NikFormatReason.invalidRegency,
      '3171000101900001': NikFormatReason.invalidDistrict,
      '3171010001900001': NikFormatReason.invalidBirthDate,
      '3171013201900001': NikFormatReason.invalidBirthDate,
      '3171014001900001': NikFormatReason.invalidBirthDate,
      '3171017201900001': NikFormatReason.invalidBirthDate,
      '3171010113900001': NikFormatReason.invalidBirthDate,
      '3171010101900000': NikFormatReason.invalidSequence,
      // 31 Desember 2026 masih masa depan pada tanggal referensi.
      '3171013112260001': NikFormatReason.futureBirthDate,
    };
    for (final entry in cases.entries) {
      test('${entry.key.isEmpty ? '(kosong)' : entry.key} -> ${entry.value.name}',
          () {
        expect(
          () => Nik.parse(entry.key, referenceDate: reference),
          throwsA(
            isA<NikFormatException>().having(
              (e) => e.reason,
              'reason',
              entry.value,
            ),
          ),
        );
        expect(
          Nik.tryParse(entry.key, referenceDate: reference),
          isNull,
        );
        expect(Nik.isValid(entry.key, referenceDate: reference), isFalse);
      });
    }
  });

  group('tryParse & isValid', () {
    test('tryParse mengembalikan null, bukan throw', () {
      expect(Nik.tryParse(null), isNull);
      expect(Nik.tryParse('bukan-nik'), isNull);
      expect(
        Nik.tryParse('3171010101900001', referenceDate: reference),
        isNotNull,
      );
    });

    test('isValid tidak pernah throw', () {
      expect(Nik.isValid(null), isFalse);
      expect(Nik.isValid(''), isFalse);
      expect(
        Nik.isValid('3171010101900001', referenceDate: reference),
        isTrue,
      );
    });
  });

  group('provinsi', () {
    test('semua 38 kode provinsi punya nama dan bisa di-parse', () {
      expect(provinceNames.length, 38);
      for (final entry in provinceNames.entries) {
        final nik = Nik.parse(
          '${entry.key}71010101900001',
          referenceDate: reference,
        );
        expect(nik.provinceCode, entry.key);
        expect(nik.provinceName, entry.value);
      }
    });
  });

  group('umur', () {
    test('umur ulang tahun penuh', () {
      final nik = Nik.parse('3171010101900001', referenceDate: reference);
      expect(nik.ageOn(DateTime(2026, 1, 1)), 36);
      expect(nik.ageOn(DateTime(2025, 12, 31)), 35);
      expect(nik.ageOn(DateTime(1990, 1, 1)), 0);
    });

    test('belum ulang tahun di tahun berjalan dihitung setahun lebih muda',
        () {
      final nik = Nik.parse('3171011503550004', referenceDate: reference);
      expect(nik.ageOn(DateTime(2026, 3, 14)), 70);
      expect(nik.ageOn(DateTime(2026, 3, 15)), 71);
    });
  });

  group('format tampil, privasi, JSON', () {
    test('formatted mengelompokkan sesuai struktur', () {
      final nik = Nik.parse('3171010101900001', referenceDate: reference);
      expect(nik.formatted, '31.71.01.010190.0001');
    });

    test('masked menyembunyikan 6 digit tengah', () {
      final nik = Nik.parse('3171010101900001', referenceDate: reference);
      expect(nik.masked, '317101******0001');
    });

    test('toString tidak pernah mengandung NIK lengkap', () {
      final nik = Nik.parse('3171010101900001', referenceDate: reference);
      expect(nik.toString(), isNot(contains('3171010101900001')));
      expect(nik.toString(), contains('DKI Jakarta'));
    });

    test('toJson/fromJson bolak-balik tanpa kehilangan data', () {
      final nik = Nik.parse('3171014101900001', referenceDate: reference);
      final json = nik.toJson();
      expect(json['nik'], '3171014101900001');
      expect(json['provinceName'], 'DKI Jakarta');
      expect(json['gender'], 'female');
      expect(json['sequence'], 1);
      expect(json['birthDate'], contains('1990-01-01'));
      final restored = Nik.fromJson(json);
      expect(restored, nik);
      expect(restored.hashCode, nik.hashCode);
    });

    test('equality berdasarkan NIK mentah', () {
      final a = Nik.parse('3171010101900001', referenceDate: reference);
      final b = Nik.parse('3171010101900001', referenceDate: reference);
      final c = Nik.parse('3171014101900001', referenceDate: reference);
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
