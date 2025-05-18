import 'package:flutter/material.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riwayat'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildHistoryCard(
                    'Potong Rambut',
                    'Rp 25.000',
                    '12 May 2025',
                    Colors.blue,
                    Icons.cut,
                  ),
                  _buildHistoryCard(
                    'Facial Wajah',
                    'Rp 40.000',
                    '5 May 2025',
                    Colors.green,
                    Icons.spa,
                  ),
                  _buildHistoryCard(
                    'Make Up',
                    'Rp 70.000',
                    '1 May 2025',
                    Colors.orange,
                    Icons.brush,
                  ),
                  _buildHistoryCard(
                    'Creambath',
                    'Rp 30.000',
                    '28 April 2025',
                    Colors.purple,
                    Icons.waves,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    String title,
    String price,
    String date,
    Color color,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Text('Tanggal: $date', style: TextStyle(color: Colors.grey)),
        trailing: Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
        ),
      ),
    );
  }
}
