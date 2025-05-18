import 'package:flutter/material.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text('Promo Spesial'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Spesial Salon Cantik',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dapatkan penawaran terbaik untuk perawatan kecantikan Anda',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            _buildPromoCard(
              context,
              'Diskon 30% Potong Rambut',
              'Berlaku hingga 31 Mei 2025',
              'Nikmati potongan rambut dengan harga spesial! Dapatkan diskon 30% untuk layanan potong rambut kami.',
              Colors.blue,
              Icons.cut,
              'Rp 25.000',
              'Rp 17.500',
            ),

            _buildPromoCard(
              context,
              'Buy 1 Get 1 Facial',
              'Berlaku hingga 15 Juni 2025',
              'Bawa teman Anda dan nikmati layanan facial bersama! Beli 1 treatment facial, dapatkan 1 treatment gratis.',
              Colors.green,
              Icons.spa,
              'Rp 40.000',
              'Untuk 2 orang',
            ),

            _buildPromoCard(
              context,
              'Paket Hemat Makeup',
              'Stok terbatas!',
              'Paket spesial makeup untuk acara formal dengan harga spesial dan bonus produk kecantikan dari sponsor kami.',
              Colors.orange,
              Icons.brush,
              'Rp 70.000',
              'Rp 55.000',
            ),

            // Special Member Section
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Special',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daftar menjadi member dan dapatkan diskon 10% untuk semua layanan sepanjang tahun!',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur membership akan segera hadir!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pinkAccent,
                    ),
                    child: Text('Daftar Sekarang'),
                  ),
                ],
              ),
            ),

            // Bottom spacing
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    String title,
    String validity,
    String description,
    Color color,
    IconData icon,
    String originalPrice,
    String promoPrice,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        validity,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$originalPrice ',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: promoPrice,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Promo $title berhasil diklaim!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Klaim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
