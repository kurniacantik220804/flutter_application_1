import 'package:flutter/material.dart';
import 'jadwal_booking_screen.dart';
import 'package:get_storage/get_storage.dart';

class DetailLayanan extends StatelessWidget {
  final String title;
  final String harga;
  final IconData icon;
  final String deskripsi;

  const DetailLayanan({
    super.key,
    required this.title,
    required this.harga,
    required this.icon,
    required this.deskripsi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                icon,
                size: 80,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: $harga',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deskripsi Layanan:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Layanan $title kami menawarkan pengalaman terbaik dengan '
              'staff profesional dan produk berkualitas tinggi. '
              'Kami menjamin kepuasan Anda dengan hasil yang maksimal.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Tanggal & Waktu:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            BookingForm(
              title: title,
              price: harga,
              icon: icon.codePoint,
            ),
          ],
        ),
      ),
    );
  }
}

class BookingForm extends StatefulWidget {
  final String title;
  final String price;
  final int icon;

  const BookingForm({
    Key? key,
    required this.title,
    required this.price,
    required this.icon,
  }) : super(key: key);

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String selectedPayment = 'Cash';
  bool isLoading = false;

  final List<String> availablePayments = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'E-Wallet'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      // Create booking object
      final booking = {
        'title': widget.title,
        'price': widget.price,
        'date':
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        'time':
            '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
        'payment': selectedPayment,
        'icon': widget.icon,
      };

      // Save booking to GetStorage
      final box = GetStorage();
      List<dynamic> bookings = [];
      if (box.hasData('bookings')) {
        bookings = box.read('bookings');
      }
      bookings.add(booking);
      box.write('bookings', bookings);

      // Simulate network delay for better UX
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to the previous screen without popping to splash
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date picker
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time picker
          InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.access_time, color: Colors.pinkAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment method
          const Text(
            'Metode Pembayaran:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPayment,
                isExpanded: true,
                icon:
                    const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
                items: availablePayments.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedPayment = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.pink[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text(
                      'Booking Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
