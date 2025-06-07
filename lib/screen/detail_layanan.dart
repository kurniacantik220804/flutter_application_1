import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/produk_service.dart';
import 'booking_form.dart';

class DetailLayanan extends StatefulWidget {
  final String idProduk;

  const DetailLayanan({
    super.key,
    required this.idProduk,
  });

  @override
  State<DetailLayanan> createState() => _DetailLayananState();
}

class _DetailLayananState extends State<DetailLayanan> {
  final ThemeController _themeController = Get.find<ThemeController>();
  Map<String, dynamic>? produkData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProdukData();
  }

  Future<void> _loadProdukData() async {
    try {
      bool dbConnected = await ProdukService.testDatabaseConnection();
      if (!dbConnected) {
        throw Exception('Tidak dapat terhubung ke database');
      }

      final data = await ProdukService.getProdukById(widget.idProduk);

      if (data != null) {
        setState(() {
          produkData = data;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        throw Exception('Data produk tidak ditemukan');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildIconFallback(dynamic colors) {
    IconData icon = Icons.local_offer;

    // Gunakan icon_name dari database jika tersedia
    if (produkData != null && produkData!['icon_name'] != null) {
      icon = ProdukService.getIconFromString(produkData!['icon_name']);
    } else if (produkData != null) {
      // Fallback ke logika lama jika icon_name tidak tersedia
      String namaProduk =
          (produkData!['nama_produk'] ?? '').toString().toLowerCase();
      if (namaProduk.contains('potong') || namaProduk.contains('rambut')) {
        icon = Icons.content_cut;
      } else if (namaProduk.contains('wajah') || namaProduk.contains('face')) {
        icon = Icons.face;
      } else if (namaProduk.contains('rias') || namaProduk.contains('makeup')) {
        icon = Icons.brush;
      } else if (namaProduk.contains('perawatan') ||
          namaProduk.contains('spa')) {
        icon = Icons.spa;
      }
    }

    return AnimatedThemedContainer(
      padding: const EdgeInsets.all(20),
      withGradient: true,
      child: Icon(
        icon,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRetryButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.refresh, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Gagal memuat data layanan',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadProdukData();
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Memuat Data...'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Sedang memuat data layanan...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (produkData == null || errorMessage != null) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Error'),
        body: Center(child: _buildRetryButton()),
      );
    }

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();
        String imagePath = produkData?['image_path'] ?? '';

        return ThemedScaffold(
          appBar: ThemedAppBar(
            title: produkData!['nama_produk'] ?? 'Detail Layanan',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section - Updated to match admin_detail_layanan.dart
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imagePath.isNotEmpty
                          ? Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildIconFallback(colors);
                              },
                            )
                          : _buildIconFallback(colors),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title and Description Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produkData!['nama_produk'] ??
                            'Nama Layanan Tidak Tersedia',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ProdukService.getDefaultDescription(
                          produkData!['nama_produk'] ?? '',
                          produkData!['deskripsi'],
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      // Harga
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ProdukService.formatHarga(produkData!['harga']),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Booking Form Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ThemedText(
                        text: 'Booking Layanan:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BookingForm(
                        idProduk: produkData!['id_produk']?.toString() ??
                            widget.idProduk,
                        produkData: produkData!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
