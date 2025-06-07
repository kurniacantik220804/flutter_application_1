import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/database/booking_service.dart';

class PromoController extends GetxController {
  static PromoController get to => Get.find();

  final RxList<Map<String, dynamic>> _availablePromos =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _claimedPromos =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _selectedPromoId = ''.obs;
  final RxMap<String, dynamic> _selectedPromo = <String, dynamic>{}.obs;

  List<Map<String, dynamic>> get availablePromos => _availablePromos.toList();
  List<Map<String, dynamic>> get claimedPromos => _claimedPromos.toList();
  bool get isLoading => _isLoading.value;
  String get selectedPromoId => _selectedPromoId.value;
  Map<String, dynamic> get selectedPromo => _selectedPromo;

  @override
  void onInit() {
    super.onInit();
    loadAvailablePromos();
    loadClaimedPromos();
  }

  Future<void> loadAvailablePromos() async {
    try {
      _isLoading.value = true;
      final promos = await BookingService.getAvailablePromos();
      _availablePromos.value = promos;
    } catch (e) {
      print('Error loading available promos: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadClaimedPromos() async {
    try {
      final promos = await BookingService.getUserClaimedPromos();
      _claimedPromos.value = promos;
    } catch (e) {
      print('Error loading claimed promos: $e');
    }
  }

  Future<void> loadAvailablePromosForBooking() async {
    try {
      _isLoading.value = true;
      final promos = await BookingService.getAvailablePromosForBooking();
      _claimedPromos.value = promos;
    } catch (e) {
      print('Error loading available promos for booking: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> claimPromo(String promoTitle) async {
    try {
      _isLoading.value = true;
      final result = await BookingService.claimPromo(promoTitle);

      if (result['success'] == true) {
        // Refresh data setelah berhasil claim promo
        await Future.wait([
          loadClaimedPromos(),
          loadAvailablePromos(), // Penting: reload available promos untuk menghapus yang sudah diklaim
        ]);

        Get.snackbar(
          'Berhasil!',
          result['message'] ?? 'Promo berhasil diklaim',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal!',
          result['error'] ?? 'Gagal mengklaim promo',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error!',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Method untuk menghapus promo dari available list setelah diklaim
  void removeClaimedPromoFromAvailable(String promoTitle) {
    _availablePromos.removeWhere(
        (promo) => (promo['nama_promo'] ?? promo['promo_title']) == promoTitle);
  }

  void selectPromo(Map<String, dynamic> promo) {
    _selectedPromoId.value = promo['id'].toString();
    _selectedPromo.value = promo;
  }

  void clearSelectedPromo() {
    _selectedPromoId.value = '';
    _selectedPromo.clear();
  }

  double calculateDiscount(double originalPrice) {
    if (_selectedPromo.isEmpty) return 0;

    final discountPercent = _selectedPromo['promo']?['diskon_persen'] ??
        _selectedPromo['discount_percent'] ??
        0;
    return originalPrice * (discountPercent / 100.0);
  }

  double calculateFinalPrice(double originalPrice) {
    return originalPrice - calculateDiscount(originalPrice);
  }
}

class PromoMenu extends StatefulWidget {
  final bool isForBooking;
  final Function(Map<String, dynamic>)? onPromoSelected;

  const PromoMenu({
    super.key,
    this.isForBooking = false,
    this.onPromoSelected,
  });

  @override
  State<PromoMenu> createState() => _PromoMenuState();
}

class _PromoMenuState extends State<PromoMenu> with TickerProviderStateMixin {
  late PromoController _promoController;
  TabController? _tabController; // Ubah menjadi nullable

  @override
  void initState() {
    super.initState();
    _promoController = Get.put(PromoController());

    // Hanya inisialisasi TabController jika bukan untuk booking
    if (!widget.isForBooking) {
      _tabController = TabController(length: 2, vsync: this);
    }

    // Load data saat widget pertama kali dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Safe dispose dengan null check
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (widget.isForBooking) {
      await _promoController.loadAvailablePromosForBooking();
    } else {
      await Future.wait([
        _promoController.loadAvailablePromos(),
        _promoController.loadClaimedPromos(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isForBooking ? 'Pilih Promo' : 'Promo Tersedia'),
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: GetX<PromoController>(
            builder: (controller) {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Jika untuk booking, tampilkan langsung daftar promo yang bisa dipilih
              if (widget.isForBooking) {
                return _buildPromoSelectionList(controller, colors);
              }

              // Jika bukan untuk booking, tampilkan dengan TabBar
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: colors.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: colors.primary,
                      tabs: const [
                        Tab(text: 'Promo Saya'),
                        Tab(text: 'Promo Tersedia'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClaimedPromosList(controller, colors),
                          _buildAvailablePromosList(controller, colors),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Widget khusus untuk memilih promo saat booking
  Widget _buildPromoSelectionList(PromoController controller, dynamic colors) {
    if (controller.claimedPromos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada promo yang tersedia untuk booking',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadAvailablePromosForBooking();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.claimedPromos.length,
        itemBuilder: (context, index) {
          final promo = controller.claimedPromos[index];
          final promoData = promo['promo'] ?? promo;

          return _buildPromoCard(
            promo: promo,
            promoData: promoData,
            colors: colors,
            isClaimed: true,
            isForBooking: true,
            onTap: () {
              // Langsung pilih promo dan kembali
              if (widget.onPromoSelected != null) {
                widget.onPromoSelected!(promo);
              }

              // Tampilkan snackbar sukses
              Get.snackbar(
                'Sukses!',
                'Promo berhasil dipilih',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );

              // Kembali ke halaman sebelumnya
              Get.back();
            },
          );
        },
      ),
    );
  }

  Widget _buildClaimedPromosList(PromoController controller, dynamic colors) {
    if (controller.claimedPromos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada promo yang diklaim',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadClaimedPromos();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.claimedPromos.length,
        itemBuilder: (context, index) {
          final promo = controller.claimedPromos[index];
          final promoData = promo['promo'] ?? promo;

          return _buildPromoCard(
            promo: promo,
            promoData: promoData,
            colors: colors,
            isClaimed: true,
            isForBooking: false,
          );
        },
      ),
    );
  }

  Widget _buildAvailablePromosList(PromoController controller, dynamic colors) {
    if (controller.availablePromos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada promo tersedia saat ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadAvailablePromos();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.availablePromos.length,
        itemBuilder: (context, index) {
          final promo = controller.availablePromos[index];

          return _buildPromoCard(
            promo: promo,
            promoData: promo,
            colors: colors,
            isClaimed: false,
            onTap: () => _showClaimPromoDialog(promo, controller, colors),
          );
        },
      ),
    );
  }

  Widget _buildPromoCard({
    required Map<String, dynamic> promo,
    required Map<String, dynamic> promoData,
    required dynamic colors,
    required bool isClaimed,
    bool isForBooking = false,
    VoidCallback? onTap,
  }) {
    final discountPercent =
        promoData['diskon_persen'] ?? promoData['discount_percent'] ?? 0;
    final promoTitle =
        promoData['nama_promo'] ?? promoData['promo_title'] ?? 'Promo';
    final description =
        promoData['deskripsi'] ?? promoData['description'] ?? '';
    final endDate = promoData['tanggal_berakhir'] ?? promoData['end_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Promo Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Promo Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promoTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${discountPercent.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (endDate != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Berlaku s/d ${_formatDate(endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (isClaimed && !isForBooking)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sudah Diklaim',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isForBooking)
                          Row(
                            children: [
                              Text(
                                'Pilih',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: colors.primary,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimPromoDialog(
    Map<String, dynamic> promo,
    PromoController controller,
    dynamic colors,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Klaim Promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin mengklaim promo ini?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo['nama_promo'] ?? 'Promo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diskon ${promo['diskon_persen']}%',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.claimPromo(promo['nama_promo']);

              if (success) {
                // Update UI setelah berhasil claim
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Klaim'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
