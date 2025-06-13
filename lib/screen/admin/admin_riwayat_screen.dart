import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/admin_booking_service.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

class AdminRiwayatScreen extends StatefulWidget {
  const AdminRiwayatScreen({Key? key}) : super(key: key);

  @override
  State<AdminRiwayatScreen> createState() => _AdminRiwayatScreenState();
}

class _AdminRiwayatScreenState extends State<AdminRiwayatScreen> {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String selectedStatusFilter = 'all';
  String errorMessage = '';
  late ThemeController themeController;

  @override
  void initState() {
    super.initState();
    // Initialize theme controller
    themeController = ThemeController.to;
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Test database connection first
    await _testDatabaseConnection();
    // Then load bookings
    await _loadBookings();
  }

  Future<void> _testDatabaseConnection() async {
    try {
      final isConnected = await AdminBookingService.testAdminConnection();
      if (!isConnected) {
        setState(() {
          errorMessage = 'Gagal terhubung ke database';
        });
        _showErrorSnackBar('Koneksi database gagal');
      } else {
        print('Database connection successful');
      }
    } catch (e) {
      print('Connection test error: $e');
      setState(() {
        errorMessage = 'Error koneksi: ${e.toString()}';
      });
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Debug database first if needed
      await AdminBookingService.debugBookingsTable();

      List<Map<String, dynamic>> data;
      if (selectedStatusFilter == 'all') {
        data = await AdminBookingService.getAllBookings();
      } else {
        data =
            await AdminBookingService.getBookingsByStatus(selectedStatusFilter);
      }

      print('Loaded ${data.length} bookings');

      setState(() {
        bookings = data;
        isLoading = false;
      });

      if (data.isEmpty) {
        _showInfoSnackBar('Tidak ada data booking ditemukan');
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
      _showErrorSnackBar('Gagal memuat data booking');
    }
  }

  Future<void> _updateBookingStatus(int bookingId, String newStatus) async {
    if (!AdminBookingService.isValidStatus(newStatus)) {
      _showErrorSnackBar('Status tidak valid');
      return;
    }

    _showLoadingDialog();

    try {
      final result =
          await AdminBookingService.updateBookingStatus(bookingId, newStatus);

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showSuccessSnackBar('Status booking berhasil diupdate');
        await _loadBookings(); // Refresh data
      } else {
        _showErrorSnackBar(result['message'] ?? 'Gagal update status');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _updatePaymentStatus(
      int bookingId, String newPaymentStatus) async {
    if (!AdminBookingService.isValidPaymentStatus(newPaymentStatus)) {
      _showErrorSnackBar('Status pembayaran tidak valid');
      return;
    }

    _showLoadingDialog();

    try {
      final result = await AdminBookingService.updatePaymentStatus(
          bookingId, newPaymentStatus);

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showSuccessSnackBar('Status pembayaran berhasil diupdate');
        await _loadBookings(); // Refresh data
      } else {
        _showErrorSnackBar(
            result['message'] ?? 'Gagal update status pembayaran');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteBooking(Map<String, dynamic> booking) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Booking',
      'Apakah Anda yakin ingin menghapus booking ${booking['booking_code']}?',
    );

    if (!confirmed) return;

    _showLoadingDialog();

    try {
      final result = await AdminBookingService.deleteBooking(booking['id']);

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showSuccessSnackBar('Booking berhasil dihapus');
        await _loadBookings(); // Refresh data
      } else {
        _showErrorSnackBar(result['message'] ?? 'Gagal menghapus booking');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    final themeColors = themeController.getThemeColors();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail Booking',
          style: TextStyle(color: themeColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kode Booking', booking['booking_code'] ?? 'N/A'),
              _buildDetailRow('Layanan', booking['title'] ?? 'N/A'),
              _buildDetailRow('Customer', booking['customer_name'] ?? 'N/A'),
              _buildDetailRow('Telepon', booking['customer_phone'] ?? 'N/A'),
              _buildDetailRow('Tanggal', booking['date'] ?? 'N/A'),
              _buildDetailRow('Waktu', booking['time'] ?? 'N/A'),
              _buildDetailRow('Harga Asli', booking['original_price'] ?? 'N/A'),
              if (booking['discount_amount'] != null)
                _buildDetailRow('Diskon', booking['discount_amount']),
              _buildDetailRow('Harga Final', booking['final_price'] ?? 'N/A'),
              _buildDetailRow(
                  'Status', _getStatusDisplayName(booking['status'])),
              _buildDetailRow('Pembayaran',
                  _getPaymentStatusDisplayName(booking['payment_status'])),
              if (booking['notes'] != null &&
                  booking['notes'].toString().isNotEmpty)
                _buildDetailRow('Catatan', booking['notes']),
              if (booking['created_at'] != null)
                _buildDetailRow(
                    'Dibuat', _formatDateTime(booking['created_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(color: themeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void _showBookingStatusDialog(Map<String, dynamic> booking) {
    final themeColors = themeController.getThemeColors();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Status Booking',
          style: TextStyle(color: themeColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Booking: ${booking['booking_code']}'),
            Text('Customer: ${booking['customer_name']}'),
            SizedBox(height: 16),
            ...AdminBookingService.getStatusOptions().map((status) {
              return ListTile(
                title: Text(_getStatusDisplayName(status)),
                leading: Radio<String>(
                  value: status,
                  groupValue: booking['status'],
                  activeColor: themeColors.primary,
                  onChanged: (value) {
                    Navigator.pop(context);
                    if (value != null && value != booking['status']) {
                      _updateBookingStatus(booking['id'], value);
                    }
                  },
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: themeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentStatusDialog(Map<String, dynamic> booking) {
    final themeColors = themeController.getThemeColors();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Status Pembayaran',
          style: TextStyle(color: themeColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Booking: ${booking['booking_code']}'),
            Text('Customer: ${booking['customer_name']}'),
            Text('Total: ${booking['price']}'),
            SizedBox(height: 16),
            ...AdminBookingService.getPaymentStatusOptions()
                .map((paymentStatus) {
              return ListTile(
                title: Text(_getPaymentStatusDisplayName(paymentStatus)),
                leading: Radio<String>(
                  value: paymentStatus,
                  groupValue: booking['payment_status'],
                  activeColor: themeColors.primary,
                  onChanged: (value) {
                    Navigator.pop(context);
                    if (value != null && value != booking['payment_status']) {
                      _updatePaymentStatus(booking['id'], value);
                    }
                  },
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: themeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    final themeColors = themeController.getThemeColors();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeColors.primary),
            ),
            SizedBox(width: 16),
            Text('Memproses...'),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final themeColors = themeController.getThemeColors();

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(color: themeColors.primary),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Ya',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _getPaymentStatusDisplayName(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Belum Bayar';
      case 'paid':
        return 'Sudah Bayar';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return paymentStatus;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return Colors.red;
      case 'paid':
        return Colors.green;
      case 'refunded':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      id: 'dashboard',
      builder: (controller) {
        final themeColors = controller.getThemeColors();

        return Scaffold(
          backgroundColor: themeColors.background,
          appBar: AppBar(
            title: Text('Management Booking'),
            backgroundColor: themeColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadBookings,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: controller.getBackgroundGradient(),
            ),
            child: Column(
              children: [
                // Filter Status
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: controller.getThemedDecoration(),
                  child: Row(
                    children: [
                      Text(
                        'Filter Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeColors.primary,
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedStatusFilter,
                          isExpanded: true,
                          dropdownColor: themeColors.surface,
                          onChanged: (value) {
                            setState(() {
                              selectedStatusFilter = value!;
                            });
                            _loadBookings();
                          },
                          items: [
                            DropdownMenuItem(
                                value: 'all', child: Text('Semua Status')),
                            DropdownMenuItem(
                                value: 'pending', child: Text('Menunggu')),
                            DropdownMenuItem(
                                value: 'confirmed',
                                child: Text('Dikonfirmasi')),
                            DropdownMenuItem(
                                value: 'completed', child: Text('Selesai')),
                            DropdownMenuItem(
                                value: 'cancelled', child: Text('Dibatalkan')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),

                // Booking List
                Expanded(
                  child: isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    themeColors.primary),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Memuat data booking...',
                                style: TextStyle(color: themeColors.primary),
                              ),
                            ],
                          ),
                        )
                      : bookings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: themeColors.primary.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    selectedStatusFilter == 'all'
                                        ? 'Tidak ada booking'
                                        : 'Tidak ada booking dengan status ${_getStatusDisplayName(selectedStatusFilter)}',
                                    style: TextStyle(
                                      color:
                                          themeColors.primary.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadBookings,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Muat Ulang'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadBookings,
                              color: themeColors.primary,
                              child: ListView.builder(
                                itemCount: bookings.length,
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final booking = bookings[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showBookingDetails(booking),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    booking['booking_code'] ??
                                                        'N/A',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          themeColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                        booking['status']),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    _getStatusDisplayName(
                                                        booking['status']),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 4),

                                            // Payment Status
                                            Row(
                                              children: [
                                                Spacer(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getPaymentStatusColor(
                                                        booking[
                                                            'payment_status']),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    _getPaymentStatusDisplayName(
                                                        booking[
                                                            'payment_status']),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 12),

                                            // Service Info
                                            Text(
                                              booking['title'] ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                            SizedBox(height: 8),

                                            // Customer Info
                                            Row(
                                              children: [
                                                Icon(Icons.person,
                                                    size: 16,
                                                    color: Colors.grey),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    booking['customer_name'] ??
                                                        'N/A',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 4),

                                            // Phone
                                            Row(
                                              children: [
                                                Icon(Icons.phone,
                                                    size: 16,
                                                    color: Colors.grey),
                                                SizedBox(width: 4),
                                                Text(
                                                    booking['customer_phone'] ??
                                                        'N/A'),
                                              ],
                                            ),

                                            SizedBox(height: 4),

                                            // Date and Price
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.grey),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${booking['date']} - ${booking['time']}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  booking['price'] ?? 'N/A',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 12),

                                            // Action Buttons - Wrap for overflow prevention
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showBookingStatusDialog(
                                                          booking),
                                                  icon: Icon(Icons.edit,
                                                      size: 16),
                                                  label: Text('Status'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        themeColors.primary,
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showPaymentStatusDialog(
                                                          booking),
                                                  icon: Icon(Icons.payment,
                                                      size: 16),
                                                  label: Text('Pembayaran'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.green,
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _deleteBooking(booking),
                                                  icon: Icon(Icons.delete,
                                                      size: 16),
                                                  label: Text('Hapus'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
