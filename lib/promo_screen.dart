import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final ThemeController themeController = ThemeController.to;

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

                _buildPromoCard(
                  context,
                  'Diskon 30% Potong Rambut',
                  'Berlaku hingga 31 Mei 2025',
                  'Nikmati potongan rambut dengan harga spesial! Dapatkan diskon 30% untuk layanan potong rambut kami.',
                  colors.primary,
                  Icons.cut,
                  'Rp 25.000',
                  'Rp 17.500',
                ),

                _buildPromoCard(
                  context,
                  'Buy 1 Get 1 Facial',
                  'Berlaku hingga 15 Juni 2025',
                  'Bawa teman Anda dan nikmati layanan facial bersama! Beli 1 treatment facial, dapatkan 1 treatment gratis.',
                  colors.secondary,
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
                      colors: [colors.primary, colors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Membership Special',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
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
                          foregroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Theme Change Demo Section
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: themeController.getThemedDecoration(
                    withShadow: true,
                    borderRadius: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ubah Tema Aplikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pilih tema favorit Anda untuk pengalaman yang lebih personal!',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: AppThemeType.values.map((theme) {
                          Color themeColor;
                          switch (theme) {
                            case AppThemeType.pink:
                              themeColor = const Color(0xFFFF4081);
                              break;
                            case AppThemeType.purple:
                              themeColor = const Color(0xFF9C27B0);
                              break;
                            case AppThemeType.teal:
                              themeColor = const Color(0xFF009688);
                              break;
                          }
                          
                          final isSelected = themeController.selectedTheme == theme;
                          
                          return GestureDetector(
                            onTap: () => themeController.changeTheme(theme),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected 
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    theme.icon,
                                    color: Colors.white,
                                    size: isSelected ? 28 : 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    theme.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSelected ? 12 : 10,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                            color: color,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Promo $title berhasil diklaim!'),
                          backgroundColor: color,
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