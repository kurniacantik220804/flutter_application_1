class Produk {
  final String id;
  final String namaProduk;
  final double hargaProduk;

  Produk({required this.id, required this.namaProduk, required this.hargaProduk});

  factory Produk.fromMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'],
      namaProduk: map['nama_produk'],
      hargaProduk: (map['harga_produk'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_produk': namaProduk,
      'harga_produk': hargaProduk,
    };
  }
}
