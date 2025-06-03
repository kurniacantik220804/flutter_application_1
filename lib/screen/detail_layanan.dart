import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';

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
  String? selectedPromo;
  bool isLoading = false;
  final ThemeController _themeController = Get.find<ThemeController>();

  List<Map<String, dynamic>> availablePromos = [];
  double originalPrice = 0;
  double finalPrice = 0;
  double discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailablePromos();
    _calculatePrice();
  }

  void _loadAvailablePromos() {
    List<Map<String, dynamic>> promos = [];
    String serviceName = widget.title.toLowerCase();

    // Promo khusus untuk layanan potong rambut
    if (serviceName.contains('potong') || serviceName.contains('rambut')) {
      // Cek apakah ini layanan perawatan rambut untuk promo free catok
      if (serviceName.contains('perawatan') ||
          serviceName.contains('creambath') ||
          serviceName.contains('vitamin') ||
          serviceName.contains('masker')) {
        promos.add({
          'name': 'Free Layanan Catok Rambut',
          'type': 'free_service',
          'value': 20000, // nilai layanan catok yang gratis
          'applicable': true,
        });
      }
      // Untuk layanan potong rambut biasa
      else if (serviceName.contains('potong')) {
        promos.add({
          'name': 'Diskon 30% Potong Rambut',
          'type': 'percentage',
          'value': 30,
          'applicable': true,
        });
      }
    }

    // Promo khusus untuk layanan perawatan wajah/facial
    if (serviceName.contains('facial') ||
        serviceName.contains('wajah') ||
        serviceName.contains('perawatan wajah')) {
      promos.add({
        'name': 'Diskon 15% Perawatan Wajah',
        'type': 'percentage',
        'value': 15,
        'applicable': true,
      });
    }

    // Promo khusus untuk layanan tata rias/makeup
    if (serviceName.contains('makeup') ||
        serviceName.contains('tata rias') ||
        serviceName.contains('rias')) {
      promos.add({
        'name': 'Paket Hemat Makeup',
        'type': 'fixed_discount',
        'value': 15000, // Diskon Rp 15.000
        'applicable': true,
      });
    }

    setState(() {
      availablePromos = promos;
    });
  }

  void _calculatePrice() {
    // Extract numeric value from price string (assuming format like "Rp 25.000")
    String priceStr = widget.price.replaceAll(RegExp(r'[^\d]'), '');
    originalPrice = double.tryParse(priceStr) ?? 0;

    finalPrice = originalPrice;
    discountAmount = 0;

    if (selectedPromo != null) {
      Map<String, dynamic>? promo = availablePromos.firstWhere(
        (p) => p['name'] == selectedPromo,
        orElse: () => {},
      );

      if (promo.isNotEmpty) {
        switch (promo['type']) {
          case 'percentage':
            discountAmount = originalPrice * (promo['value'] / 100);
            finalPrice = originalPrice - discountAmount;
            break;
          case 'fixed_discount':
            discountAmount = promo['value'].toDouble();
            finalPrice = originalPrice - discountAmount;
            if (finalPrice < 0) finalPrice = 0;
            break;
          case 'free_service':
            // Untuk free service, kita berikan nilai diskon sebagai benefit tambahan
            discountAmount = promo['value'].toDouble();
            finalPrice =
                originalPrice; // Harga tetap sama, tapi dapat bonus layanan gratis
            break;
        }
      }
    }

    setState(() {});
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

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

      // Create booking object with complete data - FIXED: ensure price is not null
      final booking = {
        'title': widget.title ?? '',
        'original_price': _formatPrice(originalPrice),
        'final_price': _formatPrice(finalPrice),
        'price': _formatPrice(
            finalPrice), // FIXED: Added this field to prevent null error
        'discount_amount':
            discountAmount > 0 ? _formatPrice(discountAmount) : null,
        'promo_used': selectedPromo,
        'promo_type': selectedPromo != null
            ? availablePromos.firstWhere(
                (p) => p['name'] == selectedPromo,
                orElse: () => {},
              )['type']
            : null,
        'date':
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        'formatted_date':
            '${selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
        'time':
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        'payment': selectedPayment,
        'icon': widget.icon,
        'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
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
          SnackBar(
            content: Text(selectedPromo != null
                ? 'Booking berhasil dengan promo ${selectedPromo}!'
                : 'Booking berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month];
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                          Icon(Icons.calendar_today,
                              color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: colors.primary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time picker
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                          Icon(Icons.access_time,
                              color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: colors.primary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Promo section - only show if promos are available
              if (availablePromos.isNotEmpty) ...[
                const ThemedText(
                  text: 'Gunakan Promo:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: colors.primary.withOpacity(0.05),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedPromo,
                      isExpanded: true,
                      hint: const Text('Pilih Promo (Opsional)'),
                      icon: Icon(Icons.arrow_drop_down, color: colors.primary),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tidak menggunakan promo'),
                        ),
                        ...availablePromos.map((promo) {
                          return DropdownMenuItem<String?>(
                            value: promo['name'],
                            child: Row(
                              children: [
                                Icon(Icons.local_offer,
                                    color: colors.secondary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(promo['name'])),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          selectedPromo = newValue;
                        });
                        _calculatePrice();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Price calculation display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Harga:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga Layanan:'),
                        Text(_formatPrice(originalPrice)),
                      ],
                    ),
                    if (selectedPromo != null && discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getDiscountLabel()),
                          Text(
                            _getDiscountText(),
                            style: TextStyle(color: colors.secondary),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bayar:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatPrice(finalPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    // Show bonus info for free service promo
                    if (selectedPromo != null && _isFreeSevicePromo()) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.card_giftcard,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bonus: Layanan Catok Rambut Gratis (${_formatPrice(discountAmount)})',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment method - simplified to only Cash
              const ThemedText(
                text: 'Metode Pembayaran:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: colors.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Cash (Bayar di Tempat)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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

  String _getDiscountLabel() {
    if (selectedPromo == null) return '';

    Map<String, dynamic>? promo = availablePromos.firstWhere(
      (p) => p['name'] == selectedPromo,
      orElse: () => {},
    );

    if (promo.isEmpty) return '';

    switch (promo['type']) {
      case 'free_service':
        return 'Bonus Layanan:';
      default:
        return 'Diskon ($selectedPromo):';
    }
  }

  String _getDiscountText() {
    if (selectedPromo == null) return '';

    Map<String, dynamic>? promo = availablePromos.firstWhere(
      (p) => p['name'] == selectedPromo,
      orElse: () => {},
    );

    if (promo.isEmpty) return '';

    switch (promo['type']) {
      case 'free_service':
        return 'Catok Gratis (${_formatPrice(discountAmount)})';
      default:
        return '- ${_formatPrice(discountAmount)}';
    }
  }

  bool _isFreeSevicePromo() {
    if (selectedPromo == null) return false;

    Map<String, dynamic>? promo = availablePromos.firstWhere(
      (p) => p['name'] == selectedPromo,
      orElse: () => {},
    );

    return promo.isNotEmpty && promo['type'] == 'free_service';
  }
}
