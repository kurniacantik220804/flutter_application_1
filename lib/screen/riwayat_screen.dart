import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Dipanggil ketika app kembali ke foreground atau ada perubahan lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBookings();
    }
  }

  // Dipanggil setiap kali widget ini di-rebuild atau kembali dari screen lain
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookings();
  }

  void _loadBookings() {
    final box = GetStorage();
    if (box.hasData('bookings')) {
      List<dynamic> savedBookings = box.read('bookings');
      if (mounted) {
        setState(() {
          bookings = List<Map<String, dynamic>>.from(savedBookings);
          // Urutkan booking berdasarkan timestamp (terbaru dulu)
          bookings.sort((a, b) {
            int timestampA = a['booking_timestamp'] ?? 0;
            int timestampB = b['booking_timestamp'] ?? 0;
            return timestampB.compareTo(timestampA);
          });
        });
      }
    } else {
      if (mounted) {
        setState(() {
          bookings = [];
        });
      }
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

  bool _isUpcoming(String dateStr, String timeStr) {
    try {
      // Parse tanggal dalam format dd/mm/yyyy
      List<String> dateParts = dateStr.split('/');
      if (dateParts.length != 3) return false;

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      // Parse waktu
      List<String> timeParts = timeStr.split(':');
      if (timeParts.length != 2) return false;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime bookingDateTime = DateTime(year, month, day, hour, minute);
      return bookingDateTime.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _formatDateTime(String dateStr, String timeStr) {
    try {
      List<String> dateParts = dateStr.split('/');
      if (dateParts.length == 3) {
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);

        List<String> monthNames = [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des'
        ];

        return '$day ${monthNames[month]} $year - $timeStr';
      }
    } catch (e) {
      // Jika gagal parse, return format asli
    }
    return '$dateStr - $timeStr';
  }

  String _getPrice(Map<String, dynamic> booking) {
    // Coba ambil final_price dulu, kalau tidak ada ambil price
    if (booking['final_price'] != null &&
        booking['final_price'].toString().isNotEmpty) {
      return booking['final_price'].toString();
    } else if (booking['price'] != null &&
        booking['price'].toString().isNotEmpty) {
      return booking['price'].toString();
    } else {
      return 'Rp 0';
    }
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
          actions: [
            // Tombol refresh manual jika diperlukan
            IconButton(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            ),
          ],
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${bookings.length} Booking Ditemukan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Terakhir diperbarui: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            _loadBookings();
                          },
                          color: colors.primary,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
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
    return RefreshIndicator(
      onRefresh: () async {
        _loadBookings();
      },
      color: colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat booking',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai booking layanan untuk melihat riwayat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadBookings,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
      Map<String, dynamic> booking, int index, ThemeColors colors) {
    final isUpcoming =
        _isUpcoming(booking['date'] ?? '', booking['time'] ?? '');
    final price = _getPrice(booking);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan info layanan
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(booking['icon'] ?? Icons.star.codePoint,
                          fontFamily: 'MaterialIcons'),
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['title'] ?? 'Layanan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            fontSize: 14,
                          ),
                        ),
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
                    tooltip: 'Hapus Booking',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Divider
              Divider(
                height: 1,
                color: Colors.grey[300],
              ),

              const SizedBox(height: 12),

              // Detail booking
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(
                          booking['date'] ?? '', booking['time'] ?? ''),
                      style: TextStyle(
                        color: isUpcoming ? Colors.blue : Colors.grey[700],
                        fontSize: 14,
                        fontWeight:
                            isUpcoming ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['payment'] ?? 'Cash',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // Indikator booking mendatang
              if (isUpcoming)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Booking Mendatang',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tampilkan promo jika ada
              if (booking['promo_used'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer,
                          size: 12, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        booking['promo_used'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
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

  void _showBookingDetails(Map<String, dynamic> booking) {
    Get.dialog(
      Obx(() {
        final themeController = ThemeController.to;
        final colors = themeController.getThemeColors();
        final price = _getPrice(booking);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            booking['title'] ?? 'Detail Booking',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Layanan', booking['title'] ?? '-'),
              if (booking['original_price'] != null &&
                  booking['final_price'] != null &&
                  booking['original_price'] != booking['final_price']) ...[
                _buildDetailItem('Harga Asli', booking['original_price']),
                if (booking['discount_amount'] != null)
                  _buildDetailItem('Diskon', booking['discount_amount']),
                _buildDetailItem('Total Bayar', booking['final_price']),
              ] else
                _buildDetailItem('Harga', price),
              _buildDetailItem('Tanggal', booking['date'] ?? '-'),
              _buildDetailItem('Waktu', booking['time'] ?? '-'),
              _buildDetailItem('Pembayaran', booking['payment'] ?? 'Cash'),
              if (booking['promo_used'] != null)
                _buildDetailItem('Promo', booking['promo_used']),
            ],
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
