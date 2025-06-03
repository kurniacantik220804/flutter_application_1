import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Map<String, dynamic>> bookings = [];
  String selectedFilter = 'Semua';
  final List<String> filterOptions = [
    'Semua',
    'Terjadwal',
    'Selesai',
    'Dibatalkan'
  ];

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
        // Urutkan booking berdasarkan tanggal (terbaru dulu)
        bookings.sort((a, b) {
          try {
            DateTime dateA = DateFormat('dd MMM yyyy').parse(a['date']);
            DateTime dateB = DateFormat('dd MMM yyyy').parse(b['date']);
            return dateB.compareTo(dateA);
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

  void _updateBookingStatus(int index, String newStatus) {
    setState(() {
      bookings[index]['status'] = newStatus;
    });

    // Update storage
    final box = GetStorage();
    box.write('bookings', bookings);

    // Menggunakan reaktif tema untuk snackbar
    final themeController = ThemeController.to;
    final colors = themeController.getThemeColors();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status booking diubah ke $newStatus'),
        backgroundColor: colors.primary,
      ),
    );
  }

  List<Map<String, dynamic>> get filteredBookings {
    if (selectedFilter == 'Semua') {
      return bookings;
    }
    return bookings
        .where((booking) => booking['status'] == selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terjadwal':
        return Colors.blue;
      case 'Selesai':
        return Colors.green;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Terjadwal':
        return Icons.schedule;
      case 'Selesai':
        return Icons.check_circle;
      case 'Dibatalkan':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  bool _isUpcoming(String dateStr, String timeStr) {
    try {
      DateTime bookingDate = DateFormat('dd MMM yyyy').parse(dateStr);
      List<String> timeParts = timeStr.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        hour,
        minute,
      );

      return bookingDateTime.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = filteredBookings;

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
          child: Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Status:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((filter) {
                          final isSelected = selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = filter;
                                });
                              },
                              selectedColor: colors.primary.withOpacity(0.3),
                              backgroundColor: Colors.grey[100],
                              checkmarkColor: colors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colors.primary
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Booking List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: filteredList.isEmpty
                      ? _buildEmptyState(colors)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredList.length} Booking Ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final booking = filteredList[index];
                                    final originalIndex =
                                        bookings.indexOf(booking);
                                    return _buildHistoryCard(
                                        booking, originalIndex, colors);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
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
            selectedFilter == 'Semua' ? Icons.history : Icons.filter_list_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedFilter == 'Semua'
                ? 'Belum ada riwayat booking'
                : 'Tidak ada booking dengan status $selectedFilter',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'Semua'
                ? 'Mulai booking layanan untuk melihat riwayat'
                : 'Coba filter status lain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      Map<String, dynamic> booking, int originalIndex, ThemeColors colors) {
    final status = booking['status'] ?? 'Terjadwal';
    final isUpcoming = _isUpcoming(booking['date'], booking['time']);

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
              // Header dengan info layanan dan status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(booking['icon'], fontFamily: 'MaterialIcons'),
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
                          booking['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking['price'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 14,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          Icons.calendar_today,
                          '${booking['date']} - ${booking['time']}',
                          isUpcoming && status == 'Terjadwal'
                              ? Colors.blue
                              : Colors.grey[700]!,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.payment,
                          booking['payment'],
                          Colors.grey[700]!,
                        ),
                      ],
                    ),
                  ),
                  // Tombol aksi
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit_status':
                          _showStatusDialog(originalIndex, status);
                          break;
                        case 'delete':
                          _deleteBooking(originalIndex);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'edit_status',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            const Text('Ubah Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Indikator booking mendatang
              if (isUpcoming && status == 'Terjadwal')
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(int index, String currentStatus) {
    Get.dialog(
      Obx(() {
        final themeController = ThemeController.to;
        final colors = themeController.getThemeColors();

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Ubah Status Booking',
            style: TextStyle(color: colors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Terjadwal', 'Selesai', 'Dibatalkan'].map((status) {
              return RadioListTile<String>(
                title: Text(
                  status,
                  style: const TextStyle(color: Colors.black),
                ),
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null && value != currentStatus) {
                    _updateBookingStatus(index, value);
                  }
                },
                activeColor: colors.primary,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      }),
    );
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
          title: Text(
            booking['title'],
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Harga', booking['price']),
              _buildDetailItem(
                  'Tanggal & Waktu', '${booking['date']} - ${booking['time']}'),
              _buildDetailItem('Metode Pembayaran', booking['payment']),
              _buildDetailItem('Status', booking['status'] ?? 'Terjadwal'),
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
