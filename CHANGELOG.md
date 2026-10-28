# Changelog

## 0.1.0 — 2026-10-28

Rilis awal.

- `Nik.parse()` / `tryParse()` / `isValid()` — decode NIK 16 digit
- `NikFormatException` + 9 `NikFormatReason` spesifik
- Nama 38 provinsi, kode kabupaten/kota & kecamatan
- Tanggal lahir + aturan +40 untuk perempuan, aturan abad tahun 2 digit
- `age` / `ageOn()`, `formatted`, `masked`, `toJson()` / `fromJson()`
- `toString()` yang tidak pernah mencetak NIK lengkap
- Zero dependency, 32 unit test, `flutter analyze` bersih
