import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/database/promo_service.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final ThemeController themeController = ThemeController.to;
  final PromoService promoService = Get.put(PromoService());

  @override
  void initState() {
    super.initState();
    // Load promo saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      promoService.loadPromos();
    });
  }

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
          actions: [
            // Tombol refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => promoService.loadPromos(),
            ),
            // Menu dengan opsi tambahan
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Info Promo'),
                    ],
                  ),
                  onTap: () => _showPromoInfo(),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: themeController.getBackgroundGradient(),
          ),
          child: RefreshIndicator(
            onRefresh: () => promoService.loadPromos(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(colors),
                  const SizedBox(height: 24),

                  // Loading indicator
                  if (promoService.isLoading.value)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // Promo statistics
                    _buildPromoStatistics(colors),
                    const SizedBox(height: 20),

                    // Available promos
                    if (promoService.availablePromos.isNotEmpty) ...[
                      _buildSectionHeader(
                          'Promo Tersedia', colors.primary, Icons.local_offer),
                      const SizedBox(height: 12),
                      ...promoService.availablePromos
                          .map((promo) => _buildPromoCard(
                                context,
                                promo,
                                colors,
                              ))
                          .toList(),
                      const SizedBox(height: 20),
                    ],

                    // Message when no promos available
                    if (promoService.availablePromos.isEmpty)
                      _buildNoPromosMessage(),
                  ],

                  // Bottom spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_giftcard,
              color: colors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Promo Spesial Salon Cantik',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Dapatkan penawaran terbaik untuk perawatan kecantikan Anda',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text(
                'Setiap promo hanya dapat diklaim sekali',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoStatistics(dynamic colors) {
    final stats = promoService.getPromoStatistics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Promo',
            '${stats['total']}',
            Icons.local_offer,
            colors.primary,
          ),
          _buildStatItem(
            'Tersedia',
            '${stats['available']}',
            Icons.card_giftcard,
            Colors.green,
          ),
          _buildStatItem(
            'Diklaim',
            '${stats['claimed']}',
            Icons.check_circle,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    Map<String, dynamic> promo,
    dynamic colors,
  ) {
    IconData cardIcon = _getIconFromString(promo['icon']);

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
              colors.primary.withOpacity(0.05),
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
                      color: colors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cardIcon,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          promo['validity'],
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
                promo['description'],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promo['promo_price'] != 'GRATIS')
                          Text(
                            '${promo['original_price']}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        Text(
                          promo['promo_price'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: promo['promo_price'] == 'GRATIS'
                                ? Colors.green
                                : colors.primary,
                            fontSize: 18,
                          ),
                        ),
                        if (promo['discount_percent'] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${promo['discount_percent']}% OFF',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Langsung klaim tanpa konfirmasi
                      await promoService.claimPromo(promo['title']);
                    },
                    icon: const Icon(Icons.redeem, size: 18),
                    label: const Text('Klaim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPromosMessage() {
    return Container(
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
            Icons.inbox_outlined,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Promo Tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saat ini tidak ada promo yang tersedia. Silakan cek kembali nanti untuk promo menarik!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPromoInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Informasi Promo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(Icons.check_circle,
                  'Setiap promo hanya dapat diklaim sekali'),
              _buildInfoItem(
                  Icons.schedule, 'Promo memiliki masa berlaku tertentu'),
              _buildInfoItem(Icons.person, 'Harus login untuk mengklaim promo'),
              _buildInfoItem(Icons.refresh,
                  'Tarik ke bawah untuk memperbarui daftar promo'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'cut':
        return Icons.cut;
      case 'spa':
        return Icons.spa;
      case 'brush':
        return Icons.brush;
      case 'straighten':
        return Icons.straighten;
      default:
        return Icons.local_offer;
    }
  }
}
