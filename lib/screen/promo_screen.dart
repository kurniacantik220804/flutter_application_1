import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final ThemeController themeController = ThemeController.to;

  // Daftar untuk melacak voucher yang sudah diklaim - updated untuk 4 voucher
  final List<bool> _claimedVouchers = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = themeController.getThemeColors();

      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Promo Spesial'),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: themeController.getBackgroundGradient(),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo Spesial Salon Cantik',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dapatkan penawaran terbaik untuk perawatan kecantikan Anda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),

                // Voucher 1 - Diskon Potong Rambut (30%)
                if (!_claimedVouchers[0])
                  _buildPromoCard(
                    context,
                    'Diskon 30% Potong Rambut',
                    'Berlaku hingga 31 Mei 2025',
                    'Nikmati potongan rambut dengan harga spesial! Dapatkan diskon 30% untuk layanan potong rambut kami.',
                    colors.primary,
                    Icons.cut,
                    'Rp 25.000',
                    'Rp 17.500',
                    0,
                  ),

                // Voucher 2 - Diskon Perawatan Wajah (15%)
                if (!_claimedVouchers[1])
                  _buildPromoCard(
                    context,
                    'Diskon 15% Perawatan Wajah',
                    'Berlaku hingga 15 Juni 2025',
                    'Dapatkan perawatan wajah terbaik dengan diskon spesial 15% untuk semua layanan perawatan wajah.',
                    colors.secondary,
                    Icons.spa,
                    'Rp 40.000',
                    'Rp 34.000',
                    1,
                  ),

                // Voucher 3 - Paket Hemat Makeup
                if (!_claimedVouchers[2])
                  _buildPromoCard(
                    context,
                    'Paket Hemat Makeup',
                    'Stok terbatas!',
                    'Paket spesial makeup untuk acara formal dengan harga spesial dan bonus produk kecantikan dari sponsor kami.',
                    Colors.orange,
                    Icons.brush,
                    'Rp 70.000',
                    'Rp 55.000',
                    2,
                  ),

                // Voucher 4 - Free Layanan Catok Rambut
                if (!_claimedVouchers[3])
                  _buildPromoCard(
                    context,
                    'Free Layanan Catok Rambut',
                    'Berlaku hingga 30 Juni 2025',
                    'Dapatkan layanan catok rambut gratis untuk setiap pembelian layanan perawatan rambut lainnya.',
                    Colors.purple,
                    Icons.straighten,
                    'Rp 20.000',
                    'GRATIS',
                    3,
                  ),

                // Pesan jika semua voucher sudah diklaim
                if (_claimedVouchers.every((claimed) => claimed))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Semua Promo Telah Diklaim!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Terima kasih telah menggunakan semua promo kami. Nantikan promo menarik lainnya!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Bottom spacing
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
    });
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
    int voucherIndex,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          validity,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        if (promoPrice != 'GRATIS') ...[
                          TextSpan(
                            text: '$originalPrice ',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        TextSpan(
                          text: promoPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                promoPrice == 'GRATIS' ? Colors.green : color,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _claimedVouchers[voucherIndex] = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Promo $title berhasil diklaim!'),
                          backgroundColor: color,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Klaim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
