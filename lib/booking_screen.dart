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
import 'booking_screen.dart'; // Import the booking screen

// jadwal_booking_screen.dart - Improved version
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class JadwalBookingScreen extends StatefulWidget {
  final IconData icon;
  final String title;
  final String harga;

  const JadwalBookingScreen({
    Key? key,
    required this.icon,
    required this.title,
    required this.harga,
  }) : super(key: key);

  @override
  State<JadwalBookingScreen> createState() => _JadwalBookingScreenState();
}

class _JadwalBookingScreenState extends State<JadwalBookingScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTime = '09:00';
  String _selectedPayment = 'Tunai';
  bool _usePromo = false;
  bool _isLoading = false;

  final List<String> availableTimes = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00'
  ];

  final List<String> paymentMethods = [
    'Tunai',
    'Transfer Bank',
    'E-Wallet',
    'Kartu Kredit'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  double _calculateFinalPrice() {
    // Extract price from string (remove "Rp " and ".")
    String priceString = widget.harga.replaceAll('Rp ', '').replaceAll('.', '');
    double originalPrice = double.tryParse(priceString) ?? 0;

    if (_usePromo) {
      return originalPrice * 0.8; // 20% discount
    }
    return originalPrice;
  }

  String _formatPrice(double price) {
    return 'Rp ${NumberFormat('#,##0', 'id_ID').format(price)}';
  }

  Future<void> _saveBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final box = GetStorage();
      List<Map<String, dynamic>> bookings = [];

      // Load existing bookings if any
      if (box.hasData('bookings')) {
        List<dynamic> savedBookings = box.read('bookings');
        bookings = List<Map<String, dynamic>>.from(savedBookings);
      }

      // Calculate final price
      double finalPrice = _calculateFinalPrice();
      String priceDisplay = _usePromo
          ? '${_formatPrice(finalPrice)} (Diskon 20%)'
          : _formatPrice(finalPrice);

      // Create new booking entry with additional fields
      Map<String, dynamic> newBooking = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
        'title': widget.title,
        'price': priceDisplay,
        'originalPrice': widget.harga,
        'finalPrice': finalPrice,
        'date': DateFormat('dd MMM yyyy').format(_selectedDay!),
        'time': _selectedTime,
        'payment': _selectedPayment,
        'icon': widget.icon.codePoint,
        'status': 'Terjadwal',
        'usePromo': _usePromo,
        'createdAt': DateTime.now().toIso8601String(),
        'bookingDateTime': DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
          int.parse(_selectedTime.split(':')[0]),
          int.parse(_selectedTime.split(':')[1]),
        ).toIso8601String(),
      };

      // Add new booking to list (add to beginning for latest first)
      bookings.insert(0, newBooking);

      // Save updated list
      await box.write('bookings', bookings);

      // Show success dialog instead of just snackbar
      _showSuccessDialog();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
              SizedBox(width: 10),
              Text('Booking Berhasil!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking Anda telah berhasil dijadwalkan.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Booking:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Layanan: ${widget.title}'),
                    Text(
                        'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'),
                    Text('Jam: $_selectedTime'),
                    Text('Pembayaran: $_selectedPayment'),
                    if (_usePromo)
                      Text(
                        'Promo: Diskon 20%',
                        style: TextStyle(
                          color: Colors.green,
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close booking screen
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(); // Close detail screen if exists
                }
              },
              child: Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close booking screen
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(); // Close detail screen if exists
                }
                // Navigate to history screen to show the booking
                _navigateToHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Lihat Riwayat'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHistory() {
    // This will need to be implemented based on your navigation structure
    // For now, we'll use a simple navigation
    Navigator.pushNamed(context, '/history');
  }

  bool _isDateTimeValid() {
    if (_selectedDay == null) return false;

    DateTime selectedDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      int.parse(_selectedTime.split(':')[0]),
      int.parse(_selectedTime.split(':')[1]),
    );

    // Check if selected date/time is in the future
    return selectedDateTime.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Booking'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 30,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.harga,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_usePromo) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Final: ${_formatPrice(_calculateFinalPrice())}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Calendar Section
            const Text(
              'Pilih Tanggal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 60)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.pink[200],
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Colors.pinkAccent,
                    ),
                  ),
                  enabledDayPredicate: (day) {
                    // Disable past dates
                    return day
                        .isAfter(DateTime.now().subtract(Duration(days: 1)));
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time Selection Section
            const Text(
              'Pilih Jam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableTimes.map((time) {
                    // Check if time slot is available (not in the past for today)
                    bool isAvailable = true;
                    if (_selectedDay != null &&
                        DateUtils.isSameDay(_selectedDay, DateTime.now())) {
                      int hour = int.parse(time.split(':')[0]);
                      int minute = int.parse(time.split(':')[1]);
                      DateTime timeSlot = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        hour,
                        minute,
                      );
                      isAvailable = timeSlot.isAfter(DateTime.now());
                    }

                    return ChoiceChip(
                      label: Text(time),
                      selected: _selectedTime == time,
                      onSelected: isAvailable
                          ? (selected) {
                              setState(() {
                                _selectedTime = time;
                              });
                            }
                          : null,
                      selectedColor: Colors.pinkAccent,
                      disabledColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: !isAvailable
                            ? Colors.grey
                            : _selectedTime == time
                                ? Colors.white
                                : Colors.black,
                        fontWeight: _selectedTime == time
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method Section
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: paymentMethods.map((method) {
                    return RadioListTile<String>(
                      title: Text(method),
                      value: method,
                      groupValue: _selectedPayment,
                      onChanged: (value) {
                        setState(() {
                          _selectedPayment = value!;
                        });
                      },
                      activeColor: Colors.pinkAccent,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Promo Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promo Tersedia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.discount,
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Diskon 20% untuk layanan ini',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Gunakan Promo'),
                      subtitle: _usePromo
                          ? Text(
                              'Hemat ${_formatPrice(_calculateFinalPrice() * 0.25)}',
                              style: TextStyle(color: Colors.green),
                            )
                          : null,
                      value: _usePromo,
                      onChanged: (value) {
                        setState(() {
                          _usePromo = value;
                        });
                      },
                      activeColor: Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Validation message
            if (!_isDateTimeValid())
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Silakan pilih tanggal dan waktu yang valid',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),

            // Book Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (_isDateTimeValid() && !_isLoading) ? _saveBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Memproses...'),
                        ],
                      )
                    : const Text(
                        'Konfirmasi Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
