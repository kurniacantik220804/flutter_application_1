import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'login_2_screen.dart';
import 'detail_layanan.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart'; // Import the new screen
import 'promo_screen.dart';
import 'booking_screen.dart';
import 'package:flutter/material.dart';
import 'jadwal_booking_screen.dart'; // Import the booking screen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final autoSizeGroup = AutoSizeGroup();
  var _bottomNavIndex = 0; // default index untuk halaman pertama

  late AnimationController _fabAnimationController;
  late AnimationController _borderRadiusAnimationController;
  late Animation<double> fabAnimation;
  late Animation<double> borderRadiusAnimation;
  late CurvedAnimation fabCurve;
  late CurvedAnimation borderRadiusCurve;
  late AnimationController _hideBottomBarAnimationController;

  final iconList = <IconData>[
    Icons.dashboard_rounded,
    Icons.account_circle_rounded,
    Icons.settings_rounded,
    Icons.history_rounded, // icon untuk riwayat
  ];

  final titleList = ["Dashboard", "Profil", "Pengaturan", "Riwayat"];

  final List<Widget> pages = [
    const DashboardScreen(),
    const ProfilScreen(),
    const MainScreen(),
    const RiwayatScreen(), // Halaman riwayat yang baru
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _borderRadiusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    fabCurve = CurvedAnimation(
      parent: _fabAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
    borderRadiusCurve = CurvedAnimation(
      parent: _borderRadiusAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    fabAnimation = Tween<double>(begin: 0, end: 1).animate(fabCurve);
    borderRadiusAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(borderRadiusCurve);

    _hideBottomBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    Future.delayed(
      const Duration(seconds: 1),
      () => _fabAnimationController.forward(),
    );
    Future.delayed(
      const Duration(seconds: 1),
      () => _borderRadiusAnimationController.forward(),
    );
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          _hideBottomBarAnimationController.reverse();
          _fabAnimationController.forward(from: 0);
          break;
        case ScrollDirection.reverse:
          _hideBottomBarAnimationController.forward();
          _fabAnimationController.reverse(from: 1);
          break;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _borderRadiusAnimationController.dispose();
    _hideBottomBarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification,
        child: IndexedStack(index: _bottomNavIndex, children: pages),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.spa, color: Colors.white),
        onPressed: () {
          _fabAnimationController.reset();
          _borderRadiusAnimationController.reset();
          _borderRadiusAnimationController.forward();
          _fabAnimationController.forward();

          // Navigate to promo screen instead of just showing a snackbar
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? Colors.pinkAccent : Colors.grey;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconList[index], size: 24, color: color),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AutoSizeText(
                  titleList[index],
                  maxLines: 1,
                  style: TextStyle(color: color),
                  group: autoSizeGroup,
                ),
              ),
            ],
          );
        },
        backgroundColor: Colors.white,
        activeIndex: _bottomNavIndex,
        splashColor: Colors.pinkAccent,
        notchAndCornersAnimation: borderRadiusAnimation,
        splashSpeedInMilliseconds: 300,
        notchSmoothness: NotchSmoothness.defaultEdge,
        gapLocation: GapLocation.center,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        hideAnimationController: _hideBottomBarAnimationController,
        shadow: BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 12,
          spreadRadius: 0.5,
          color: Colors.pinkAccent.withOpacity(0.3),
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.spa, color: Colors.white),
            SizedBox(width: 8),
            Text('Salon Cantik'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifikasi terbaru')),
              );
            },
          ),
        ],
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section with user name
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pink[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          'Pelanggan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Promo slider
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.pink[50],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🎉 PROMO SPESIAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Diskon 20% untuk pelanggan baru!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PromoScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Lihat Promo'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 80),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    top: 0,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upcoming booking reminder (if any)
            FutureBuilder(
              future: _checkForUpcomingBookings(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_available,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Booking Mendatang',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kamu memiliki booking aktif. Cek detail di halaman Riwayat.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          onPressed: () {
                            // Switch to history tab
                            // This requires a method to update _bottomNavIndex in parent widget
                            // For now we'll just navigate to RiwayatScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RiwayatScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Layanan Unggulan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to a full services page (not implemented yet)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lihat semua layanan')),
                    );
                  },
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Featured services grid
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

            // Beauty tips section
            Text(
              'Tips Kecantikan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTipCard(
                    context,
                    'Rahasia Rambut Sehat',
                    'Konsumsi vitamin dan protein yang cukup untuk pertumbuhan rambut yang sehat',
                    Icons.favorite,
                  ),
                  _buildTipCard(
                    context,
                    'Jaga Kulit Wajah',
                    'Gunakan tabir surya setiap hari untuk mencegah penuaan dini',
                    Icons.wb_sunny,
                  ),
                  _buildTipCard(
                    context,
                    'Makeup Natural',
                    'Gunakan warna-warna yang mendekati warna kulit untuk tampilan alami',
                    Icons.face,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
      BuildContext context, String title, String content, IconData icon) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.pink[50]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.pinkAccent,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Show tip details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tips detail akan segera hadir')),
                    );
                  },
                  child: Text(
                    'Selengkapnya',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Mock function to check if there are upcoming bookings
  Future<bool> _checkForUpcomingBookings() async {
    final box = GetStorage();
    if (box.hasData('bookings')) {
      List<dynamic> bookings = box.read('bookings');
      if (bookings.isNotEmpty) {
        return true;
      }
    }
    return false;
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
          // Navigate to detail layanan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLayanan(
                title: title,
                harga: harga,
                icon: icon,
                deskripsi: _getLayananDeskripsi(title),
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
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // Navigate to the booking schedule screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LayananCard(
                        icon: icon,
                        title: title,
                        harga: harga,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLayananDeskripsi(String title) {
    switch (title) {
      case 'Potong Rambut':
        return 'Layanan potong rambut profesional sesuai dengan model yang diinginkan. Termasuk hair styling dan cuci rambut.';
      case 'Facial Wajah':
        return 'Perawatan wajah yang membantu membersihkan, menghidrasi, dan menyegarkan kulit wajah Anda.';
      case 'Makeup':
        return 'Layanan rias wajah untuk berbagai acara formal maupun kasual dengan produk berkualitas tinggi.';
      case 'Creambath':
        return 'Perawatan rambut intensif dengan krim nutrisi untuk menjaga kesehatan dan kilau rambut Anda.';
      default:
        return 'Layanan perawatan kecantikan dan kesehatan oleh tim profesional kami.';
    }
  }
}
