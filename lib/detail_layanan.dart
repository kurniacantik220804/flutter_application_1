import 'package:flutter/material.dart';

class DetailLayananScreen extends StatelessWidget {
  final String title;
  final String harga;
  final String deskripsi;
  final IconData icon;

  const DetailLayananScreen({
    super.key,
    required this.title,
    required this.harga,
    required this.deskripsi,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.pinkAccent),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 80, color: Colors.pink),
            const SizedBox(height: 24),
            Text(
              harga,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(deskripsi, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking berhasil!')),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Booking Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor:
                      Colors
                          .white, // Menambahkan foregroundColor untuk warna teks
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
