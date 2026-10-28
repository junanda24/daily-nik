# Design: daily_nik

## Stack

- Dart SDK `^3.0.0` (via Flutter SDK 3.47.7 / Dart 3.13.5 di mesin ini).
- Pure Dart library — tanpa `dart:io`, tanpa Flutter — supaya bisa dipakai
  di Flutter, server Dart, dan CLI.
- Zero dependency runtime. Dev: `lints` (recommended) + `test`.
- Mengikuti pedoman Effective Dart: nama publik deskriptif, konstruktor
  `const` di mana masuk akal, dokumentasi `///` di semua API publik.

## Struktur file

```
lib/
  daily_nik.dart        # barrel export (satu-satunya import publik)
  src/
    nik.dart            # Nik, NikGender, parsing, umur, format, JSON
    nik_exception.dart  # NikFormatException + NikFormatReason
    provinces.dart      # const Map<String, String> 38 kode provinsi
test/
  daily_nik_test.dart   # parse, gender, validasi, provinsi, umur, format
example/
  main.dart             # demo CLI: parse 2 NIK sintetis, cetak hasilnya
```

## Alur parse (nik.dart)

1. `input.trim()` → hapus spasi, `.`, `-` (pemisah yang umum ditempel
   dari form). Kosong setelah ini → `empty`.
2. Panjang != 16 → `wrongLength`. Karakter non-digit → `nonDigit`.
3. Potong: provinsi `[0:2]`, kabupaten `[2:4]`, kecamatan `[4:6]`,
   hari `[6:8]`, bulan `[8:10]`, tahun `[10:12]`, urut `[12:16]`.
4. Provinsi tidak ada di map → `unknownProvince`. Kabupaten `00` →
   `invalidRegency`. Kecamatan `00` → `invalidDistrict`. Urut `0000` →
   `invalidSequence`.
5. Gender dari hari: `<= 40` laki-laki, `> 40` perempuan (hari − 40).
   Hari hasil 1–31 dan bulan 1–12, lalu validasi tanggal kalender nyata
   dengan mencoba konstruksi `DateTime` dan membandingkan komponennya
   kembali (menangkap 29 Feb non-kabisat, 31 April, dsb.) →
   `invalidBirthDate` bila tidak cocok.
6. Tahun: aturan abad relatif terhadap `referenceDate` (lihat spec R2).
7. Tanggal lahir > `referenceDate` (perbandingan tanggal saja, jam
   diabaikan) → `futureBirthDate`.

## Keranjang state (ARCHITECTURE.md)

Package ini stateless: tidak ada state yang disimpan. Satu-satunya data
statis adalah `const` map provinsi (data referensi, bukan state). Objek
`Nik` immutable — semua field `final`, tidak ada setter.

## Yang tidak dilakukan

- Tidak ada lookup kabupaten/kota/kecamatan (lihat proposal: dataset
  terlalu besar & tidak stabil untuk ditebak).
- Tidak ada validasi Dukcapil (butuh akses resmi, di luar jangkauan
  package offline).
- Tidak ada logging NIK mentah di mana pun.
