import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String _getServiceImage() {
    String serviceName = widget.title.toLowerCase();

    if (serviceName.contains('tata rias') || serviceName.contains('makeup')) {
      return 'assets/makeup.jpg';
    } else if (serviceName.contains('potong') &&
        serviceName.contains('rambut')) {
      return 'assets/potong.jpg';
    } else if (serviceName.contains('perawatan') &&
        serviceName.contains('rambut')) {
      return 'assets/rambut.jpg';
    } else if (serviceName.contains('perawatan') &&
        serviceName.contains('wajah')) {
      return 'assets/wajah.jpg';
    } else if (serviceName.contains('wajah') ||
        serviceName.contains('facial')) {
      return 'assets/wajah.jpg';
    } else if (serviceName.contains('rambut')) {
      return 'assets/rambut.jpg';
    }
    return '';
  }

  Widget _buildIconFallback(dynamic colors) {
    return AnimatedThemedContainer(
      padding: const EdgeInsets.all(20),
      withGradient: true,
      child: Icon(
        widget.icon,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();
        String imagePath = _getServiceImage();

        return ThemedScaffold(
          appBar: ThemedAppBar(title: widget.title),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imagePath.isNotEmpty
                          ? Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildIconFallback(colors);
                              },
                            )
                          : _buildIconFallback(colors),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title and Description Section - Combined
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
                      const SizedBox(height: 12),
                      Text(
                        widget.deskripsi.isNotEmpty
                            ? widget.deskripsi
                            : 'Layanan ${widget.title} kami menawarkan pengalaman terbaik dengan staff profesional dan produk berkualitas tinggi.',
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
                        text: 'Booking Layanan:',
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
  String? selectedPromo;
  bool isLoading = false;
  bool isLoadingPromos = false;
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

  Future<void> _loadAvailablePromos() async {
    setState(() => isLoadingPromos = true);

    try {
      String serviceKey = _getServiceKey();
      final response = await Supabase.instance.client
          .from('promo')
          .select()
          .eq('id_produk', serviceKey)
          .eq('status', 'aktif')
          .gte('tanggal_berakhir',
              DateTime.now().toIso8601String().split('T')[0]);

      List<Map<String, dynamic>> promos = [];
      for (var promo in response) {
        bool alreadyClaimed = await _isPromoAlreadyClaimed(promo['nama_promo']);
        if (!alreadyClaimed) {
          promos.add({
            'id': promo['id'],
            'name': promo['nama_promo'],
            'description': promo['deskripsi'],
            'discount_percent': promo['diskon_persen'],
            'type':
                promo['diskon_persen'] == 100 ? 'free_service' : 'percentage',
            'value': promo['diskon_persen'] == 100
                ? promo['harga_asli']
                : promo['diskon_persen'],
          });
        }
      }

      setState(() {
        availablePromos = promos;
        isLoadingPromos = false;
      });
    } catch (e) {
      setState(() {
        availablePromos = [];
        isLoadingPromos = false;
      });
    }
  }

  String _getServiceKey() {
    String serviceName = widget.title.toLowerCase();
    if (serviceName.contains('potong') && serviceName.contains('rambut')) {
      return 'Potong Rambut';
    } else if (serviceName.contains('perawatan') &&
        serviceName.contains('rambut')) {
      return 'Perawatan_Rambut';
    } else if (serviceName.contains('wajah') ||
        serviceName.contains('facial')) {
      return 'Perawatan Wajah';
    } else if (serviceName.contains('makeup') ||
        serviceName.contains('tata rias')) {
      return 'Tata_Rias';
    }
    return widget.title;
  }

  Future<bool> _isPromoAlreadyClaimed(String promoTitle) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await Supabase.instance.client
          .from('claimed_promos')
          .select()
          .eq('user_id', user.id)
          .eq('promo_title', promoTitle);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _calculatePrice() {
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
        if (promo['type'] == 'percentage') {
          discountAmount = originalPrice * (promo['value'] / 100);
          finalPrice = originalPrice - discountAmount;
        } else if (promo['type'] == 'free_service') {
          discountAmount = promo['value'].toDouble();
          finalPrice = originalPrice;
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
      setState(() => selectedDate = picked);
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
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        if (selectedPromo != null) {
          await _claimPromo(selectedPromo!);
        }

        final booking = {
          'title': widget.title,
          'price': _formatPrice(finalPrice),
          'discount_amount':
              discountAmount > 0 ? _formatPrice(discountAmount) : null,
          'promo_used': selectedPromo,
          'date':
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
          'time':
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
          'payment': 'Cash',
          'icon': widget.icon,
          'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        final box = GetStorage();
        List<dynamic> bookings = box.read('bookings') ?? [];
        bookings.add(booking);
        box.write('bookings', bookings);

        await Future.delayed(const Duration(seconds: 1));
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selectedPromo != null
                ? 'Booking berhasil dengan promo $selectedPromo!'
                : 'Booking berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        Get.forceAppUpdate();
        Navigator.pop(context);
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimPromo(String promoTitle) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('claimed_promos').insert({
        'user_id': user.id,
        'promo_title': promoTitle,
      });
    } catch (e) {
      print('Error claiming promo: $e');
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
              // Date and Time Selection
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: colors.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: colors.primary.withOpacity(0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: colors.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: colors.primary.withOpacity(0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Promo Selection
              if (isLoadingPromos)
                const Center(child: CircularProgressIndicator())
              else if (availablePromos.isNotEmpty) ...[
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
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tidak menggunakan promo'),
                        ),
                        ...availablePromos.map((promo) {
                          return DropdownMenuItem<String?>(
                            value: promo['name'],
                            child: Text(promo['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: (newValue) {
                        setState(() => selectedPromo = newValue);
                        _calculatePrice();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga:', style: TextStyle(fontSize: 16)),
                        Text(_formatPrice(originalPrice),
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon:',
                              style: TextStyle(color: Colors.green)),
                          Text('- ${_formatPrice(discountAmount)}',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_formatPrice(finalPrice),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ThemedButton(
                  text: isLoading ? 'Memproses...' : 'Booking Sekarang',
                  height: 50,
                  onPressed: isLoading ? null : _submitBooking,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BookingController extends GetxController {
  static BookingController get to => Get.find();
  final RxList<Map<String, dynamic>> _bookings = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get bookings => _bookings.toList();

  @override
  void onInit() {
    super.onInit();
    loadBookings();
  }

  void loadBookings() {
    final box = GetStorage();
    if (box.hasData('bookings')) {
      List<dynamic> savedBookings = box.read('bookings');
      _bookings.value = List<Map<String, dynamic>>.from(savedBookings);
      _bookings.sort((a, b) {
        int timestampA = a['booking_timestamp'] ?? 0;
        int timestampB = b['booking_timestamp'] ?? 0;
        return timestampB.compareTo(timestampA);
      });
    }
  }

  void refreshBookings() {
    loadBookings();
    update();
  }
}
