import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'detail_layanan.dart';
import 'promo/promo_screen.dart';
import 'riwayat_screen.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/database/produk_service.dart'; // Import produk_service

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  Future<bool>? _upcomingBookingsFuture;
  late ThemeController _themeController;
  String _userName = 'Pelanggan';
  List<Map<String, dynamic>> _layananList = []; // List layanan dari database
  bool _isLoadingLayanan = true;

  // Inisialisasi dengan nilai default untuk menghindari null
  ThemeColors _cachedColors = const ThemeColors(
    primary: Color(0xFFFF4081),
    secondary: Color(0xFFE91E63),
    background: Color(0xFFFFF0F5),
    surface: Colors.white,
  );
  AppThemeType? _cachedTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _upcomingBookingsFuture = _checkForUpcomingBookings();
    _loadUserName();
    _loadLayananData(); // Load data layanan dari database
  }

  void _initializeController() {
    try {
      _themeController = Get.find<ThemeController>();
      _updateCachedTheme();
    } catch (e) {
      // Fallback jika controller belum diinisialisasi
      Get.put(ThemeController());
      _themeController = Get.find<ThemeController>();
      _updateCachedTheme();
    }
  }

  void _updateCachedTheme() {
    try {
      final currentTheme = _themeController.selectedTheme;
      if (_cachedTheme != currentTheme) {
        _cachedTheme = currentTheme;
        _cachedColors = _themeController.getThemeColors();
      }
    } catch (e) {
      print('Error updating cached theme: $e');
      // Gunakan default colors jika ada error
    }
  }

  // Load data layanan dari database
  Future<void> _loadLayananData() async {
    try {
      final layananData = await ProdukService.getAllProduk();
      if (mounted) {
        setState(() {
          _layananList = layananData;
          _isLoadingLayanan = false;
        });
      }
    } catch (e) {
      print('Error loading layanan data: $e');
      if (mounted) {
        setState(() {
          _isLoadingLayanan = false;
          // Fallback ke data default jika ada error
          _layananList = [
            {
              'id': '1',
              'nama_produk': 'Potong Rambut',
              'harga': 25000,
              'icon_name': 'cut',
              'image_path': '',
              'deskripsi': 'Layanan potong rambut profesional'
            },
            {
              'id': '2',
              'nama_produk': 'Perawatan Wajah',
              'harga': 40000,
              'icon_name': 'spa',
              'image_path': '',
              'deskripsi': 'Perawatan wajah untuk kulit sehat'
            },
          ];
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final supabaseService = SupabaseService.to;
      final user = supabaseService.currentUser;

      if (user != null) {
        final profile = await supabaseService.getUserProfile();

        if (profile != null && profile['username'] != null) {
          if (mounted) {
            setState(() {
              _userName = profile['username'];
            });
          }
        } else {
          final fullName = user.userMetadata?['full_name'];
          if (fullName != null && fullName.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userName = fullName;
              });
            }
          } else {
            final email = user.email;
            if (email != null && mounted) {
              setState(() {
                _userName = email.split('@')[0];
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Gunakan Obx untuk konsistensi dengan theme widgets lainnya
    return Obx(() {
      // Pastikan controller masih ada
      if (!Get.isRegistered<ThemeController>()) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      _updateCachedTheme();

      return Scaffold(
        backgroundColor: _cachedColors.background,
        appBar: _buildOptimizedAppBar(),
        body: _buildOptimizedBody(),
      );
    });
  }

  PreferredSizeWidget _buildOptimizedAppBar() {
    return AppBar(
      title: const Text('Salon Cantik'),
      automaticallyImplyLeading: false,
      backgroundColor: _cachedColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_cachedColors.primary, _cachedColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cachedColors.background,
            _cachedColors.primary.withOpacity(0.1),
            _cachedColors.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOptimizedGreetingSection(),
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
                  _buildFeaturedServicesHeader(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // Loading indicator atau GridView layanan
            _isLoadingLayanan 
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final layanan = _layananList[index];
                          return OptimizedLayananCard(
                            idProduk: layanan['id'].toString(),
                            icon: ProdukService.getIconFromString(layanan['icon_name']),
                            title: layanan['nama_produk'],
                            harga: ProdukService.formatHarga(layanan['harga']),
                            colors: _cachedColors,
                          );
                        },
                        childCount: _layananList.length,
                      ),
                    ),
                  ),

            // Tambah spacing di bawah
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedGreetingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cachedColors.primary, _cachedColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _cachedColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _cachedColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.person, size: 35, color: _cachedColors.primary),
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
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Layanan Unggulan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _cachedColors.primary,
          ),
        ),
      ],
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
      print('Error checking bookings: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// OptimizedLayananCard yang sudah diperbaiki
class OptimizedLayananCard extends StatelessWidget {
  final String idProduk; // Ubah ke idProduk
  final IconData icon;
  final String title;
  final String harga;
  final ThemeColors colors;

  const OptimizedLayananCard({
    super.key,
    required this.idProduk, // Parameter idProduk
    required this.icon,
    required this.title,
    required this.harga,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailLayanan(
                  idProduk: idProduk, // Kirim idProduk ke DetailLayanan
                ),
              ),
            );
          } catch (e) {
            print('Error navigating to detail: $e');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                  'Pesan',
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
        ),
      ),
    );
  }
}