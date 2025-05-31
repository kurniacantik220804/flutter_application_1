import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';
import 'theme_widgets.dart';

class DetailLayanan extends StatefulWidget {
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
  State<DetailLayanan> createState() => _DetailLayananState();
}

class _DetailLayananState extends State<DetailLayanan> {
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();

        return ThemedScaffold(
          appBar: ThemedAppBar(
            title: widget.title,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Section with themed styling
                Center(
                  child: AnimatedThemedContainer(
                    padding: const EdgeInsets.all(20),
                    withGradient: true,
                    child: Icon(
                      widget.icon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ThemedText(
                        text: 'Harga: ${widget.harga}',
                        isPrimary: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ThemedText(
                        text: 'Deskripsi Layanan:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.deskripsi.isNotEmpty 
                          ? widget.deskripsi 
                          : 'Layanan ${widget.title} kami menawarkan pengalaman terbaik dengan '
                            'staff profesional dan produk berkualitas tinggi. '
                            'Kami menjamin kepuasan Anda dengan hasil yang maksimal.',
                        style: const TextStyle(fontSize: 16, height: 1.5),
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
                        text: 'Pilih Tanggal & Waktu:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BookingForm(
                        title: widget.title,
                        price: widget.harga,
                        icon: widget.icon.codePoint,
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

class BookingForm extends StatefulWidget {
  final String title;
  final String price;
  final int icon;

  const BookingForm({
    super.key,
    required this.title,
    required this.price,
    required this.icon,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String selectedPayment = 'Cash';
  bool isLoading = false;
  final ThemeController _themeController = Get.find<ThemeController>();

  final List<String> availablePayments = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'E-Wallet'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final colors = _themeController.getThemeColors();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.primary,
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
    final colors = _themeController.getThemeColors();
    
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.primary,
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
        'date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        'time': '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
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

        // Navigate back to the previous screen
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();
        
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: colors.primary.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, color: colors.primary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time picker
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: colors.primary.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, color: colors.primary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment method
              const ThemedText(
                text: 'Metode Pembayaran:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: colors.primary.withOpacity(0.05),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPayment,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: colors.primary),
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
                child: ThemedButton(
                  text: 'Booking Sekarang',
                  height: 50,
                  onPressed: isLoading ? null : _submitBooking,
                ),
              ),
              
              // Loading indicator when booking
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}