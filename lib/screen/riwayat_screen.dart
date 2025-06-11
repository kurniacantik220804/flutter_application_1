import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/database/booking_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

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

  // Load bookings dari database dengan fallback ke local storage
  Future<void> _loadBookings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Coba ambil dari database dulu
      List<Map<String, dynamic>> databaseBookings =
          await BookingService.getUserBookingHistory();

      if (mounted) {
        setState(() {
          bookings = databaseBookings;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');

      // Fallback ke local storage jika database error
      _loadLocalBookings();

      if (mounted) {
        setState(() {
          errorMessage =
              'Gagal memuat data dari server. Menampilkan data lokal.';
          isLoading = false;
        });
      }
    }
  }

  // Load bookings dari local storage (fallback)
  void _loadLocalBookings() {
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

  // Refresh data dari server
  Future<void> _refreshBookings() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
      errorMessage = null;
    });

    try {
      // Sync dari server
      await BookingService.syncFromServer();

      // Load bookings terbaru
      List<Map<String, dynamic>> refreshedBookings =
          await BookingService.getUserBookingHistory();

      if (mounted) {
        setState(() {
          bookings = refreshedBookings;
          isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing bookings: $e');

      if (mounted) {
        setState(() {
          isRefreshing = false;
          errorMessage = 'Gagal memperbarui data: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Delete booking dari database dan local storage
  Future<void> _deleteBooking(int index) async {
    final booking = bookings[index];

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
              onPressed: () async {
                Navigator.of(context).pop();

                // Tampilkan loading
                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  barrierDismissible: false,
                );

                try {
                  bool success = false;

                  // Hapus dari database jika ada ID
                  if (booking['id'] != null) {
                    success = await BookingService.deleteBooking(booking['id']);
                  }

                  if (success || booking['id'] == null) {
                    // Hapus dari local storage
                    setState(() {
                      bookings.removeAt(index);
                    });

                    // Update local storage
                    final box = GetStorage();
                    box.write('bookings', bookings);

                    Get.back(); // Tutup loading dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Booking berhasil dihapus'),
                        backgroundColor: colors.primary,
                      ),
                    );
                  } else {
                    Get.back(); // Tutup loading dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus booking dari server'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Get.back(); // Tutup loading dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
            // Tombol refresh manual
            IconButton(
              onPressed: isRefreshing ? null : _refreshBookings,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message banner
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              errorMessage = null;
                            });
                          },
                          icon: Icon(Icons.close, color: Colors.orange[700]),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),

                // Loading state
                if (isLoading)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat data booking...'),
                        ],
                      ),
                    ),
                  )
                // Empty state
                else if (bookings.isEmpty)
                  Expanded(child: _buildEmptyState(colors))
                // Content
                else
                  Expanded(
                    child: Column(
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
                            onRefresh: _refreshBookings,
                            color: colors.primary,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final booking = bookings[index];
                                return _buildHistoryCard(
                                    booking, index, colors);
                              },
                            ),
                          ),
                        ),
                      ],
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
      onRefresh: _refreshBookings,
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
                  onPressed: _refreshBookings,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
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
    final status = booking['status'] ?? 'pending';
    final paymentStatus = booking['payment_status'] ?? 'unpaid';

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
                        // Booking code jika ada
                        if (booking['booking_code'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Kode: ${booking['booking_code']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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

              // Customer info jika ada
              if (booking['customer_name'] != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking['customer_name'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Status badges
              Row(
                children: [
                  // Status booking
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'paid'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange),
                    ),
                    child: Text(
                      paymentStatus == 'paid' ? 'Dibayar' : 'Belum Dibayar',
                      style: TextStyle(
                        fontSize: 11,
                        color: paymentStatus == 'paid'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Indikator booking mendatang
              if (isUpcoming) ...[
                const SizedBox(height: 8),
                Container(
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
              ],

              // Tampilkan promo jika ada
              if (booking['promo_title'] != null) ...[
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
                        booking['promo_title'],
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking['booking_code'] != null)
                  _buildDetailItem('Kode Booking', booking['booking_code']),
                _buildDetailItem('Layanan', booking['title'] ?? '-'),
                _buildDetailItem(
                    'Nama Pelanggan', booking['customer_name'] ?? '-'),
                _buildDetailItem(
                    'No. Telepon', booking['customer_phone'] ?? '-'),
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
                _buildDetailItem(
                    'Status', _getStatusText(booking['status'] ?? 'pending')),
                _buildDetailItem(
                    'Status Pembayaran',
                    (booking['payment_status'] ?? 'unpaid') == 'paid'
                        ? 'Dibayar'
                        : 'Belum Dibayar'),
                if (booking['promo_title'] != null)
                  _buildDetailItem('Promo', booking['promo_title']),
                if (booking['notes'] != null && booking['notes'].isNotEmpty)
                  _buildDetailItem('Catatan', booking['notes']),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
