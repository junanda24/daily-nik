# Proposal: daily_nik — Decoder & Validator NIK (Nomor Induk Kependudukan)

## Apa & kenapa

Setiap WNI punya 16 digit NIK, dan 16 digit itu ternyata menyimpan cerita:
2 digit provinsi, 2 digit kabupaten/kota, 2 digit kecamatan, 6 digit tanggal
lahir (dengan kode +40 untuk perempuan), dan 4 digit nomor urut. Hampir
semua form aplikasi Indonesia yang meminta NIK hanya menyimpannya sebagai
string buta — padahal dari NIK saja sebuah aplikasi bisa mengisi otomatis
provinsi, tanggal lahir, jenis kelamin, dan umur, tanpa satu pun request
server.

`daily_nik` adalah package Dart murni (pure Dart, zero dependency) yang
membaca 16 digit itu menjadi objek bertipe: provinsi (nama 38 provinsi),
tanggal lahir, jenis kelamin, umur, plus format tampil dan versi tersamarkan
untuk UI. Tidak ada network, tidak ada database, tidak ada data pribadi
yang keluar dari aplikasi — semua komputasi lokal.

## Kenapa ini mengejutkan

"Oh" version: validator boolean `isValid` — sudah ada di registry.
"Wow" version: satu baris `Nik.parse(nik)` dan form yang tadinya kosong
tiba-tiba terisi provinsi, tanggal lahir, dan umur — dari angka yang selama
ini dianggap sekadar nomor antrean. Efek kejutnya ada di sudut pandang:
NIK bukan sekadar identitas, NIK adalah data terstruktur yang selama ini
tidak dibaca siapa-siapa.

## Kenapa bentuk output ini (Dart package, bukan web app)

- Target pemakainya developer (Flutter/Dart), bukan end user yang mengisi
  form sekali. Package adalah bentuk yang benar: sekali ditulis, dipakai di
  semua aplikasi.
- Pure Dart (bukan Flutter) supaya jalan di Flutter, server Dart, dan CLI.
- Zero dependency supaya instalasi tidak pernah konflik.
- Rotasi program harian: kemarin (2026-10-27) npm package, lusa dan
  sebelumnya web app — hari ini giliran Flutter/Dart package (terakhir
  2026-10-19, weton).

## Kenapa tanpa backend

Tidak ada yang perlu dihitung di server. Struktur NIK ditetapkan regulasi
(PP Nomor 37 Tahun 2007 Pasal 33, dirujuk dokumentasi nomiden) dan daftar
38 kode provinsi adalah data statis kecil. Backend hanya akan menambah
latensi, biaya, dan risiko kebocoran data pribadi — tiga hal yang justru
harus dihindari untuk data se sensitif NIK.

## Yang disengaja TIDAK dibuat

- Nama kabupaten/kota dan kecamatan: tidak ada dataset resmi yang ringkas
  dan stabil untuk 500+ kabupaten dan 7000+ kecamatan; menebak namanya
  adalah fabrikasi. Package mengembalikan kode kabupaten/kota dan
  kecamatan apa adanya, dan mendokumentasikan batas ini dengan jujur.
- Verifikasi keaslian NIK ke Dukcapil: package ini membaca struktur,
  bukan membuktikan NIK terdaftar. NIK yang strukturnya valid belum tentu
  terdaftar di Dukcapil.
- OCR/scan KTP: itu package lain (sudah ada di registry), bukan tugas
  decoder string ini.

## Privasi (bagian dari desain, bukan tempelan)

- `toString()` tidak pernah mencetak NIK lengkap — hanya versi
  tersamarkan.
- Ada `masked` khusus untuk tampil di UI/log (`317101******0001`).
- README memperingatkan: proses NIK hanya atas persetujuan pemiliknya,
  jangan pernah me-log NIK mentah, dan jangan mengirim NIK ke server
  hanya untuk memakai package ini.
- Semua NIK di test dan contoh adalah SINTETIS (disusun dari pola
  struktur, bukan milik siapa pun).
