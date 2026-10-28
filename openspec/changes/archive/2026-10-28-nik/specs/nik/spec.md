# Spec: daily_nik

## Struktur NIK (16 digit)

| Digit | Arti |
|-------|------|
| 1–2   | Kode provinsi (38 kode, lihat `provinces.dart`) |
| 3–4   | Kode kabupaten/kota |
| 5–6   | Kode kecamatan |
| 7–12  | Tanggal lahir DDMMYY; hari +40 untuk perempuan |
| 13–16 | Nomor urut |

## Requirements

### R1 — Parse

- SHALL: `Nik.parse(String)` mengembalikan `Nik` untuk NIK 16 digit yang
  valid.
  - WHEN input `"3171010101900001"` THEN `provinceCode == "31"`,
    `provinceName == "DKI Jakarta"`, `regencyCode == "71"`,
    `districtCode == "01"`, `birthDate == DateTime(1990, 1, 1)`,
    `gender == NikGender.male`, `sequence == 1`, `raw` sama dengan input.
- SHALL: `Nik.parse` menerima pemisah spasi, titik, dan strip di input
  (mis. `"3171-01-010190-0001"`) dan menormalkannya sebelum validasi.
- SHALL: `Nik.tryParse` mengembalikan `null` (bukan throw) untuk input
  tidak valid, dan `null` untuk input `null`.
- SHALL: `Nik.isValid` mengembalikan `bool` tanpa throw untuk input apa
  pun termasuk `null`.

### R2 — Jenis kelamin & tanggal lahir

- SHALL: hari 01–31 berarti laki-laki; hari 41–71 berarti perempuan
  dengan hari = nilai − 40.
  - WHEN input `"3171014101900001"` THEN `gender == NikGender.female`
    dan `birthDate == DateTime(1990, 1, 1)`.
- SHALL: tahun 2 digit dipetakan dengan aturan: `yy <= yy(reference)`
  → 2000+yy, selain itu → 1900+yy. `reference` default `DateTime.now()`
  dan bisa di-inject lewat parameter `referenceDate` (untuk test).
- SHALL: tanggal kalender yang mustahil ditolak: 29 Februari di tahun
  bukan kabisat, 30 Februari, bulan 00/13, hari 00/32/40/72.
- SHALL: tanggal lahir di masa depan relatif terhadap `referenceDate`
  ditolak (`NikFormatReason.futureBirthDate`).

### R3 — Validasi & error yang bisa dibedakan

- SHALL: setiap kegagalan parse melempar `NikFormatException` dengan
  `reason` yang spesifik, bukan pesan string generik:
  `empty`, `wrongLength`, `nonDigit`, `unknownProvince`,
  `invalidRegency`, `invalidDistrict`, `invalidBirthDate`,
  `invalidSequence`, `futureBirthDate`.
- SHALL: kode provinsi di luar 38 kode ditolak (`unknownProvince`).
- SHALL: kode kabupaten/kota `00` ditolak, kode kecamatan `00` ditolak,
  nomor urut `0000` ditolak.

### R4 — Provinsi

- SHALL: `provinceName` mengembalikan nama provinsi untuk semua 38 kode
  (11–19, 21, 31–36, 51–53, 61–65, 71–76, 81–82, 91–96).

### R5 — Umur

- SHALL: `ageOn(DateTime)` menghitung umur ulang tahun penuh (belum
  ulang tahun tahun ini → umur − 1).
  - WHEN lahir 1990-01-01 THEN `ageOn(DateTime(2026, 1, 1)) == 36`
    dan `ageOn(DateTime(2025, 12, 31)) == 35`.
- SHALL: `age` sama dengan `ageOn(DateTime.now())`.

### R6 — Format tampil & privasi

- SHALL: `formatted` mengelompokkan sesuai struktur:
  `"3171010101900001"` → `"31.71.01.010190.0001"`.
- SHALL: `masked` menyembunyikan 6 digit tengah:
  `"3171010101900001"` → `"317101******0001"`.
- SHALL: `toString()` TIDAK mengandung NIK lengkap.
- SHALL: `toJson()` mengembalikan map dengan kunci `nik`, `provinceCode`,
  `provinceName`, `regencyCode`, `districtCode`, `birthDate` (ISO-8601),
  `gender` (`"male"`/`"female"`), `sequence`; `Nik.fromJson` membalikannya.

### R7 — Kualitas package

- SHALL: zero dependency (hanya dev_dependencies `lints` + `test`).
- SHALL: `flutter test` hijau, `flutter analyze` tanpa error,
  `dart pub publish --dry-run` lolos.
- SHALL: semua NIK di test/contoh adalah sintetis; tidak ada NIK orang
  nyata di repo ini.
