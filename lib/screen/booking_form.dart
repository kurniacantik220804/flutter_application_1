import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:flutter_application_1/database/produk_service.dart';
import 'package:flutter_application_1/screen/promo_menu_widget.dart';

class BookingForm extends StatefulWidget {
  final String idProduk;
  final Map<String, dynamic> produkData;

  const BookingForm({
    super.key,
    required this.idProduk,
    required this.produkData,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool isLoading = false;
  final ThemeController _themeController = Get.find<ThemeController>();
  final PromoController _promoController = Get.put(PromoController());

  double originalPrice = 0;
  Map<String, dynamic>? selectedPromo;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
    _promoController.loadAvailablePromosForBooking();
  }

  void _calculatePrice() {
    dynamic hargaRaw = widget.produkData['harga'];
    if (hargaRaw != null) {
      if (hargaRaw is int) {
        originalPrice = hargaRaw.toDouble();
      } else if (hargaRaw is double) {
        originalPrice = hargaRaw;
      } else {
        try {
          originalPrice = double.parse(hargaRaw.toString());
        } catch (e) {
          originalPrice = 0;
        }
      }
    } else {
      originalPrice = 0;
    }
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  double _calculateDiscountAmount() {
    if (selectedPromo == null) return 0;

    final discountPercent = selectedPromo!['promo']?['diskon_persen'] ??
        selectedPromo!['discount_percent'] ??
        0;
    return originalPrice * (discountPercent / 100.0);
  }

  double _calculateFinalPrice() {
    return originalPrice - _calculateDiscountAmount();
  }

  void _selectPromo() {
    Get.to(() => PromoMenu(
          isForBooking: true,
          onPromoSelected: (promo) {
            setState(() {
              selectedPromo = promo;
            });
            Get.snackbar(
              'Promo Diterapkan!',
              'Promo ${promo['promo']?['nama_promo'] ?? promo['promo_title']} berhasil diterapkan',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          },
        ));
  }

  void _removePromo() {
    setState(() {
      selectedPromo = null;
    });
    Get.snackbar(
      'Promo Dihapus',
      'Promo telah dihapus dari booking',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
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
        // Gunakan icon dari database jika tersedia, jika tidak gunakan logika fallback
        IconData iconData = Icons.local_offer;
        if (widget.produkData['icon_name'] != null) {
          iconData =
              ProdukService.getIconFromString(widget.produkData['icon_name']);
        } else {
          String namaProduk =
              (widget.produkData['nama_produk'] ?? '').toString().toLowerCase();
          if (namaProduk.contains('potong') || namaProduk.contains('rambut')) {
            iconData = Icons.content_cut;
          } else if (namaProduk.contains('wajah') ||
              namaProduk.contains('face')) {
            iconData = Icons.face;
          } else if (namaProduk.contains('rias') ||
              namaProduk.contains('makeup')) {
            iconData = Icons.brush;
          } else if (namaProduk.contains('perawatan') ||
              namaProduk.contains('spa')) {
            iconData = Icons.spa;
          }
        }

        final booking = {
          'id_produk': widget.idProduk,
          'title': widget.produkData['nama_produk'] ?? 'Layanan',
          'original_price': _formatPrice(originalPrice),
          'discount_amount': selectedPromo != null
              ? _formatPrice(_calculateDiscountAmount())
              : 'Rp 0',
          'final_price': _formatPrice(_calculateFinalPrice()),
          'price': _formatPrice(_calculateFinalPrice()), // Untuk kompatibilitas
          'promo_id': selectedPromo?['id']?.toString(),
          'promo_title': selectedPromo?['promo']?['nama_promo'] ??
              selectedPromo?['promo_title'],
          'promo_discount': selectedPromo != null
              ? (selectedPromo!['promo']?['diskon_persen'] ??
                  selectedPromo!['discount_percent'] ??
                  0)
              : 0,
          'date':
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
          'time':
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
          'payment': 'Cash',
          'icon': iconData.codePoint,
          'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        final box = GetStorage();
        List<dynamic> bookings = box.read('bookings') ?? [];
        bookings.add(booking);
        box.write('bookings', bookings);

        await Future.delayed(const Duration(seconds: 1));
        setState(() => isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(selectedPromo != null
                  ? 'Booking berhasil dengan promo ${selectedPromo!['promo']?['nama_promo'] ?? selectedPromo!['promo_title']}!'
                  : 'Booking berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );

          Get.forceAppUpdate();
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat booking: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

              // Promo Selection Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: colors.primary.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_offer,
                            color: colors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Promo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _selectPromo,
                          child: Text(
                            selectedPromo == null
                                ? 'Pilih Promo'
                                : 'Ganti Promo',
                            style: TextStyle(color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                    if (selectedPromo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedPromo!['promo']?['nama_promo'] ??
                                        selectedPromo!['promo_title'] ??
                                        'Promo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Diskon ${selectedPromo!['promo']?['diskon_persen'] ?? selectedPromo!['discount_percent'] ?? 0}%',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _removePromo,
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tidak ada promo yang dipilih',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Original Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga Asli:',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          _formatPrice(originalPrice),
                          style: TextStyle(
                            fontSize: 16,
                            decoration: selectedPromo != null
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: selectedPromo != null
                                ? Colors.grey.shade600
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // Discount (if applicable)
                    if (selectedPromo != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Diskon (${selectedPromo!['promo']?['diskon_persen'] ?? selectedPromo!['discount_percent'] ?? 0}%):',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.green),
                          ),
                          Text(
                            '- ${_formatPrice(_calculateDiscountAmount())}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                    ],

                    // Final Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedPromo != null
                              ? 'Total Bayar:'
                              : 'Total Harga:',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatPrice(_calculateFinalPrice()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),

                    // Savings indicator
                    if (selectedPromo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hemat ${_formatPrice(_calculateDiscountAmount())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
