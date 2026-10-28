# daily_nik — Decoder & Validator NIK

Satu baris kode, dan 16 digit NIK berubah dari sekadar nomor menjadi data:
provinsi, tanggal lahir, jenis kelamin, umur — tanpa server, tanpa
database, tanpa dependensi.

```dart
import 'package:daily_nik/daily_nik.dart';

final nik = Nik.parse('3171010101900001');
print(nik.provinceName); // DKI Jakarta
print(nik.birthDate);    // 1990-01-01
print(nik.gender.label); // Laki-laki
print(nik.age);          // umur dalam tahun penuh
print(nik.masked);       // 317101******0001 — aman untuk UI/log
```

> ⚠️ Semua NIK di README, test, dan contoh ini **SINTETIS** — disusun
> dari pola struktur NIK, bukan milik siapa pun. Jangan pernah memakai
> NIK orang asli untuk testing.

## Kenapa ide ini dipilih

Hampir semua form aplikasi Indonesia yang meminta NIK hanya menyimpannya
sebagai string buta. Padahal strukturnya sudah ditetapkan regulasi (PP
Nomor 37 Tahun 2007, Pasal 33): 16 digit itu menyimpan provinsi,
kabupaten/kota, kecamatan, tanggal lahir (dengan kode +40 untuk
perempuan), dan nomor urut. Package ini membaca struktur itu, sehingga
form bisa mengisi otomatis provinsi, tanggal lahir, dan umur dari NIK —
tanpa satu pun request server. Di registry Dart yang sudah ada baru
sebatas validator boolean; decoder lengkap dengan nama provinsi, umur,
dan format tampil yang aman privasi inilah celahnya.

## Fitur

- `Nik.parse(String)` → objek `Nik` bertipe, lengkap dengan alasan error
  spesifik (`NikFormatException` + `NikFormatReason`: `empty`,
  `wrongLength`, `nonDigit`, `unknownProvince`, `invalidRegency`,
  `invalidDistrict`, `invalidBirthDate`, `invalidSequence`,
  `futureBirthDate`).
- `Nik.tryParse(String?)` → `null` bila tidak valid (tidak pernah throw).
- `Nik.isValid(String?)` → cek boolean, aman untuk `null`.
- `provinceCode` + `provinceName` — semua **38 provinsi** Indonesia.
- `regencyCode` + `districtCode` — kode kabupaten/kota & kecamatan.
- `birthDate` — tanggal lahir asli (`DateTime`), termasuk aturan +40
  untuk perempuan (hari tertulis 41–71).
- `gender` — `NikGender.male` / `NikGender.female`, dengan
  `gender.label` Bahasa Indonesia.
- `age` / `ageOn(DateTime)` — umur ulang tahun penuh (bukan selisih
  tahun kasar).
- `formatted` — `31.71.01.010190.0001`, enak dibaca manusia.
- `masked` — `317101******0001`, aman untuk UI dan log.
- `toJson()` / `Nik.fromJson()` — serialisasi bolak-balik.
- `toString()` **tidak pernah** mencetak NIK lengkap.
- Menerima pemisah spasi, titik, dan strip di input
  (`"3171-01-010190-0001"` sama dengan `"3171010101900001"`).
- Pure Dart, **zero dependency** — jalan di Flutter, server Dart, dan CLI.

## Cara pakai

Belum diterbitkan ke pub.dev (keputusan publish ada di Junan). Sementara
itu, pakai lewat dependensi git:

```yaml
dependencies:
  daily_nik:
    git:
      url: https://github.com/junanda24/daily-nik.git
```

Lalu:

```dart
import 'package:daily_nik/daily_nik.dart';

void main() {
  // 1. Parse — throw NikFormatException bila tidak valid.
  final nik = Nik.parse('3273015506000002');
  print(nik.provinceName); // Jawa Barat
  print(nik.birthDate);    // 2000-06-15
  print(nik.gender.label); // Perempuan (hari tertulis 55 = tanggal 15)

  // 2. Validasi form — tanpa throw.
  if (!Nik.isValid(inputDariUser)) {
    print('NIK tidak valid, periksa lagi ya.');
  }

  // 3. Tampilkan dengan aman.
  print(nik.masked); // 327301******0002
}
```

### Aturan tahun 2 digit

NIK hanya menyimpan 2 digit tahun, jadi abadnya ditentukan relatif
terhadap tanggal referensi (default: hari ini): `yy <= yy(referensi)` →
2000+yy, selain itu → 1900+yy. Parameter `referenceDate` di `parse` /
`tryParse` / `isValid` memungkinkan perilaku ini diuji secara
deterministik dan dipakai untuk data historis.

## Cara menjalankan dari source

```bash
export PATH="$HOME/workspace/.sdks/flutter/bin:$PATH"  # bila perlu
flutter pub get
flutter test        # 32 test, harus hijau
flutter analyze     # harus bersih
dart run example/main.dart
dart pub publish --dry-run   # cek kesiapan publish (tidak mem-publish)
```

## Tech stack

- Dart SDK `^3.0.0`, pure Dart (tanpa Flutter, tanpa `dart:io`).
- Dev dependencies: `lints` (recommended), `test`.
- Tanpa backend, tanpa database, tanpa network — sesuai sifat datanya
  yang statis dan sensitif.

## Struktur folder

```
lib/
  daily_nik.dart         # export publik
  src/
    nik.dart             # Nik, NikGender, parsing, umur, format, JSON
    nik_exception.dart   # NikFormatException + NikFormatReason
    provinces.dart       # 38 kode provinsi -> nama
test/
  daily_nik_test.dart    # 32 test
example/
  main.dart              # demo CLI
openspec/changes/archive/2026-10-28-nik/
  proposal.md, specs/nik/spec.md, design.md, tasks.md
```

## Batasan jujur (yang disengaja tidak dibuat)

- **Nama kabupaten/kota & kecamatan tidak dipetakan.** Dataset
  resminya mencakup 500+ kabupaten dan 7000+ kecamatan dan berubah
  lewat pemekaran; menebak namanya adalah fabrikasi. Package
  mengembalikan kodenya apa adanya.
- **Bukan verifikasi Dukcapil.** NIK yang strukturnya valid belum tentu
  terdaftar. Package ini membaca struktur, bukan membuktikan keaslian.
- **Tidak ada OCR/scan KTP.** Itu tugas package lain; package ini
  menerima string NIK yang sudah diekstrak.

## Privasi — baca sebelum memakai di produksi

NIK adalah data pribadi yang dilindungi. Package ini dirancang supaya
tidak menambah risiko:

1. Semua komputasi lokal — NIK tidak pernah dikirim ke server oleh
   package ini, dan tidak perlu dikirim hanya untuk memakai package ini.
2. Jangan pernah me-log NIK mentah; pakai `masked` atau `toString()`.
3. Proses NIK hanya atas persetujuan pemiliknya, sesuai keperluan form
   yang sedang diisi.
4. Jangan menyimpan NIK lebih lama dari yang diperlukan aplikasimu.

## Catatan saat build

- Keputusan abad (tahun 2 digit) awalnya rawan ambigu untuk usia ~100
  tahun; aturan relatif-terhadap-referensi dipilih karena membuat
  tanggal lahir tidak pernah jatuh di masa depan kecuali memang
  tanggalnya belum lewat di tahun berjalan — dan kasus itu justru
  ditolak eksplisit sebagai `futureBirthDate`.
- Validasi tanggal memakai trik konstruksi-ulang `DateTime` (Dart me-
  _roll over_ tanggal mustahil seperti 30 Februari menjadi 2 Maret),
  jadi komponen tanggal dicek ulang setelah konstruksi.
- `toString()` yang menyembunyikan NIK sempat terasa "kurang
  informatif" saat debugging — tapi itu memang tujuannya: log adalah
  tempat kebocoran paling sering terjadi.

## Link

- Repo: https://github.com/junanda24/daily-nik
- Rilis: 2026-10-28 (versi 0.1.0, program "1 Hari 1 Project")
- Lisensi: MIT
