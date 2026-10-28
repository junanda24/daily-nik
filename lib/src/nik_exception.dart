/// Alasan spesifik kenapa sebuah string gagal di-parse sebagai NIK.
///
/// Satu alasan per kegagalan, supaya aplikasi bisa menampilkan pesan
/// yang tepat di form, bukan sekadar "NIK tidak valid".
enum NikFormatReason {
  /// Input kosong (atau hanya berisi pemisah/spasi).
  empty,

  /// Setelah normalisasi panjangnya bukan 16 digit.
  wrongLength,

  /// Mengandung karakter selain digit (setelah pemisah dihapus).
  nonDigit,

  /// Kode provinsi tidak ada di daftar 38 provinsi.
  unknownProvince,

  /// Kode kabupaten/kota `00`.
  invalidRegency,

  /// Kode kecamatan `00`.
  invalidDistrict,

  /// Tanggal lahir tidak mungkin (bulan/hari di luar jangkauan atau
  /// tanggal kalender yang tidak ada, mis. 29 Februari di tahun
  /// bukan kabisat).
  invalidBirthDate,

  /// Nomor urut `0000`.
  invalidSequence,

  /// Tanggal lahir berada di masa depan relatif terhadap tanggal
  /// referensi.
  futureBirthDate,
}

/// Dilempar saat parsing gagal karena input bukan NIK yang valid
/// secara struktural.
///
/// Bukan bukti NIK terdaftar di Dukcapil — hanya bukti strukturnya
/// tidak bisa dibaca. Lihat [reason] untuk penyebab pastinya.
class NikFormatException implements Exception {
  /// Membuat exception dengan [reason] dan pesan yang bisa dibaca.
  const NikFormatException(this.reason, [this.message]);

  /// Penyebab kegagalan, untuk branching di kode pemanggil.
  final NikFormatReason reason;

  /// Pesan opsional yang menjelaskan kegagalan dalam Bahasa Indonesia.
  final String? message;

  @override
  String toString() =>
      'NikFormatException(${reason.name}'
      '${message == null ? '' : ': $message'})';
}
