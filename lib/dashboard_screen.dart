import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'detail_layanan.dart';
import 'promo_screen.dart';
import 'riwayat_screen.dart';
import 'beauty_tips_screen.dart';
import 'theme_controller.dart';
import 'theme_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  Future<bool>? _upcomingBookingsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _upcomingBookingsFuture = _checkForUpcomingBookings();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();

        return ThemedScaffold(
          appBar: ThemedAppBar(
            title: 'Salon Cantik',
            automaticallyImplyLeading: false,
            actions: [
              ThemedIconButton(
                icon: Icons.notifications_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi terbaru')),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingSection(colors),
                  const SizedBox(height: 20),

                  _buildPromoSection(context, colors),
                  const SizedBox(height: 20),

                  FutureBuilder<bool>(
                    future: _upcomingBookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _buildFeaturedServicesHeader(context, colors),
                  const SizedBox(height: 12),

                  _buildFeaturedServices(colors),
                  const SizedBox(height: 20),

                  _buildBeautyTipsSection(context, colors),

                  // Padding bottom untuk mencegah overflow dengan bottom navigation
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(ThemeColors colors) {
    return AnimatedThemedContainer(
      padding: const EdgeInsets.all(20),
      withGradient: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.person, size: 35, color: colors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Text(
                  'Pelanggan Setia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(BuildContext context, ThemeColors colors) {
    return ThemedCard(
      padding: const EdgeInsets.all(16),
      withGradient: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  text: '🎉 PROMO SPESIAL',
                  isPrimary: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diskon 20% untuk\npelanggan baru!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ThemedButton(
                  text: 'Lihat Promo',
                  height: 36,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PromoScreen()),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.card_giftcard, size: 40, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServicesHeader(
      BuildContext context, ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const ThemedText(
          text: 'Layanan Unggulan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lihat semua layanan')),
            );
          },
          child: ThemedText(
            text: 'Lihat Semua',
            isPrimary: true,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedServices(ThemeColors colors) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        LayananCard(
          icon: Icons.cut,
          title: 'Potong Rambut',
          harga: 'Rp 25.000',
          colors: colors,
        ),
        LayananCard(
          icon: Icons.spa,
          title: 'Facial Wajah',
          harga: 'Rp 40.000',
          colors: colors,
        ),
        LayananCard(
          icon: Icons.brush,
          title: 'Makeup',
          harga: 'Rp 70.000',
          colors: colors,
        ),
        LayananCard(
          icon: Icons.local_florist,
          title: 'Creambath',
          harga: 'Rp 30.000',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildBeautyTipsSection(BuildContext context, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          text: 'Tips Kecantikan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTipCard(
                context,
                'Rambut Sehat',
                'Konsumsi vitamin untuk rambut',
                Icons.favorite,
                colors,
              ),
              _buildTipCard(
                context,
                'Kulit Glowing',
                'Tips perawatan kulit harian',
                Icons.face,
                colors,
              ),
              _buildTipCard(
                context,
                'Makeup Natural',
                'Tutorial makeup untuk pemula',
                Icons.brush,
                colors,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, String title, String content,
      IconData icon, ThemeColors colors) {
    return ThemedCard(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BeautyTipsScreen()),
      ),
      child: SizedBox(
        width: 164, // 180 - 16 (padding)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: colors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ThemedText(
                text: 'Detail',
                isPrimary: true,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkForUpcomingBookings() async {
    try {
      final box = GetStorage();
      if (box.hasData('bookings')) {
        List<dynamic> bookings = box.read('bookings');
        return bookings.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class LayananCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String harga;
  final ThemeColors colors;

  const LayananCard({
    super.key,
    required this.icon,
    required this.title,
    required this.harga,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLayanan(
            title: title,
            harga: harga,
            icon: icon,
            deskripsi: _getLayananDeskripsi(title),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            harga,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Booking',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getLayananDeskripsi(String title) {
    const deskripsiMap = {
      'Potong Rambut':
          'Layanan potong rambut profesional sesuai dengan model yang diinginkan. Termasuk hair styling dan cuci rambut.',
      'Facial Wajah':
          'Perawatan wajah yang membantu membersihkan, menghidrasi, dan menyegarkan kulit wajah Anda.',
      'Makeup':
          'Layanan rias wajah untuk berbagai acara formal maupun kasual dengan produk berkualitas tinggi.',
      'Creambath':
          'Perawatan rambut intensif dengan krim nutrisi untuk menjaga kesehatan dan kilau rambut Anda.',
    };

    return deskripsiMap[title] ??
        'Layanan perawatan kecantikan dan kesehatan oleh tim profesional kami.';
  }
}
