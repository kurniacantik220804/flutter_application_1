import 'package:flutter/material.dart';
import 'detail_layanan.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text("Salon Cantik"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat Datang di Salon Cantik!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Layanan Unggulan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                LayananCard(
                  icon: Icons.cut,
                  title: 'Potong Rambut',
                  harga: 'Rp 25.000',
                ),
                LayananCard(
                  icon: Icons.spa,
                  title: 'Facial Wajah',
                  harga: 'Rp 40.000',
                ),
                LayananCard(
                  icon: Icons.brush,
                  title: 'Makeup',
                  harga: 'Rp 70.000',
                ),
                LayananCard(
                  icon: Icons.local_florist,
                  title: 'Creambath',
                  harga: 'Rp 30.000',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎉 Dapatkan diskon 20% untuk pelanggan baru! '
                'Kunjungi salon kami hari ini dan rasakan layanan terbaik dari kami.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LayananCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String harga;

  const LayananCard({
    super.key,
    required this.icon,
    required this.title,
    required this.harga,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DetailLayananScreen(
                    title: title,
                    harga: harga,
                    deskripsi:
                        'Layanan $title dengan kualitas terbaik untuk kebutuhan kecantikan Anda.',
                    icon: icon,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.pinkAccent),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(harga, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
