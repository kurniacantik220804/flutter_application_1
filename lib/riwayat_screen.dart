import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'theme_controller.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final box = GetStorage();
    if (box.hasData('bookings')) {
      List<dynamic> savedBookings = box.read('bookings');
      setState(() {
        bookings = List<Map<String, dynamic>>.from(savedBookings);
        // Urutkan booking berdasarkan timestamp booking (terbaru dulu)
        bookings.sort((a, b) {
          try {
            int timestampA = a['booking_timestamp'] ?? 0;
            int timestampB = b['booking_timestamp'] ?? 0;
            return timestampB.compareTo(timestampA);
          } catch (e) {
            return 0;
          }
        });
      });
    }
  }

  void _deleteBooking(int index) {
    // Menggunakan Obx untuk mendapatkan tema terbaru
    Get.dialog(
      Obx(() {
        final themeController = ThemeController.to;
        final colors = themeController.getThemeColors();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(color: colors.primary),
          ),
          content: const Text('Apakah Anda yakin ingin menghapus booking ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  bookings.removeAt(index);
                });
                // Update storage
                final box = GetStorage();
                box.write('bookings', bookings);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Booking berhasil dihapus'),
                    backgroundColor: colors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Obx untuk reaktivitas tema otomatis
    return Obx(() {
      final themeController = ThemeController.to;
      final colors = themeController.getThemeColors();

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Riwayat Booking'),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: bookings.isEmpty
                ? _buildEmptyState(colors)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bookings.length} Booking Ditemukan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            _loadBookings();
                          },
                          color: colors.primary,
                          child: ListView.builder(
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return _buildHistoryCard(booking, index, colors);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat booking',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai booking layanan untuk melihat riwayat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking, int index, ThemeColors colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan info layanan
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconData(booking['icon'], fontFamily: 'MaterialIcons'),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tampilkan harga akhir (setelah promo jika ada)
                        Text(
                          booking['final_price'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            fontSize: 15,
                          ),
                        ),
                        // Tampilkan info promo jika ada
                        if (booking['promo_used'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 12,
                                color: colors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking['promo_used'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Tombol hapus
                  IconButton(
                    onPressed: () => _deleteBooking(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Hapus booking',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),

              // Detail booking
              Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Tanggal',
                    booking['formatted_date'] ?? booking['date'],
                    colors.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.access_time,
                    'Waktu',
                    booking['time'],
                    colors.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.payment,
                    'Pembayaran',
                    booking['payment'],
                    Colors.grey[700]!,
                  ),
                ],
              ),

              // Info detail harga jika ada promo atau harga berbeda
              if (booking['original_price'] != booking['final_price'] || 
                  booking['promo_used'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Harga Asli:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            booking['original_price'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: booking['promo_used'] != null 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (booking['discount_amount'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDiscountLabel(booking),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.secondary,
                              ),
                            ),
                            Text(
                              _getDiscountText(booking),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Divider(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            booking['final_price'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getDiscountLabel(Map<String, dynamic> booking) {
    String? promoType = booking['promo_type'];
    if (promoType == 'free_service') {
      return 'Bonus Layanan:';
    }
    return 'Diskon:';
  }

  String _getDiscountText(Map<String, dynamic> booking) {
    String? promoType = booking['promo_type'];
    String discountAmount = booking['discount_amount'] ?? '';
    
    if (promoType == 'free_service') {
      return 'Catok Gratis ($discountAmount)';
    }
    return '- $discountAmount';
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    Get.dialog(
      Obx(() {
        final themeController = ThemeController.to;
        final colors = themeController.getThemeColors();

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(booking['icon'], fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  booking['title'],
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Tanggal', booking['formatted_date'] ?? booking['date']),
                _buildDetailItem('Waktu', booking['time']),
                _buildDetailItem('Metode Pembayaran', booking['payment']),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Rincian Harga:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailItem('Harga Layanan', booking['original_price']),
                if (booking['promo_used'] != null) ...[
                  _buildDetailItem('Promo', booking['promo_used']),
                  if (booking['discount_amount'] != null)
                    _buildDetailItem(_getDiscountLabel(booking), _getDiscountText(booking)),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: _buildDetailItem(
                    'Total Bayar',
                    booking['final_price'],
                    isTotal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: TextStyle(color: colors.primary),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.black87 : Colors.grey[700],
                fontSize: isTotal ? 14 : 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isTotal ? Colors.black87 : Colors.black,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}