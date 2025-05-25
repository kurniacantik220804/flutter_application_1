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

  void _saveBooking() {
    final box = GetStorage();
    List<Map<String, dynamic>> bookings = [];

    // Load existing bookings if any
    if (box.hasData('bookings')) {
      List<dynamic> savedBookings = box.read('bookings');
      bookings = List<Map<String, dynamic>>.from(savedBookings);
    }

    // Create new booking entry
    Map<String, dynamic> newBooking = {
      'title': widget.title,
      'price': _usePromo ? '${widget.harga} (Promo -20%)' : widget.harga,
      'date': DateFormat('dd MMM yyyy').format(_selectedDay!),
      'time': _selectedTime,
      'payment': _selectedPayment,
      'icon': widget.icon.codePoint,
      'status': 'Terjadwal',
    };

    // Add new booking to list
    bookings.add(newBooking);

    // Save updated list
    box.write('bookings', bookings);

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking berhasil dijadwalkan!')),
    );

    // Go back to previous screens (close both this screen and potentially the detail screen)
    Navigator.pop(context);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
                    return ChoiceChip(
                      label: Text(time),
                      selected: _selectedTime == time,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                      selectedColor: Colors.pinkAccent,
                      labelStyle: TextStyle(
                        color:
                            _selectedTime == time ? Colors.white : Colors.black,
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

            // Book Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedDay != null ? _saveBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
