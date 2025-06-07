import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/produk_service.dart';

class DetailLayanan extends StatefulWidget {
  final String idProduk;

  const DetailLayanan({
    super.key,
    required this.idProduk,
  });

  @override
  State<DetailLayanan> createState() => _DetailLayananState();
}

class _DetailLayananState extends State<DetailLayanan> {
  final ThemeController _themeController = Get.find<ThemeController>();
  Map<String, dynamic>? produkData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProdukData();
  }

  Future<void> _loadProdukData() async {
    try {
      bool dbConnected = await ProdukService.testDatabaseConnection();
      if (!dbConnected) {
        throw Exception('Tidak dapat terhubung ke database');
      }

      final data = await ProdukService.getProdukById(widget.idProduk);

      if (data != null) {
        setState(() {
          produkData = data;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        throw Exception('Data produk tidak ditemukan');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildIconFallback(dynamic colors) {
    IconData icon = Icons.local_offer;

    // Gunakan icon_name dari database jika tersedia
    if (produkData != null && produkData!['icon_name'] != null) {
      icon = ProdukService.getIconFromString(produkData!['icon_name']);
    } else if (produkData != null) {
      // Fallback ke logika lama jika icon_name tidak tersedia
      String namaProduk =
          (produkData!['nama_produk'] ?? '').toString().toLowerCase();
      if (namaProduk.contains('potong') || namaProduk.contains('rambut')) {
        icon = Icons.content_cut;
      } else if (namaProduk.contains('wajah') || namaProduk.contains('face')) {
        icon = Icons.face;
      } else if (namaProduk.contains('rias') || namaProduk.contains('makeup')) {
        icon = Icons.brush;
      } else if (namaProduk.contains('perawatan') ||
          namaProduk.contains('spa')) {
        icon = Icons.spa;
      }
    }

    return AnimatedThemedContainer(
      padding: const EdgeInsets.all(20),
      withGradient: true,
      child: Icon(
        icon,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRetryButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.refresh, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Gagal memuat data layanan',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadProdukData();
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Memuat Data...'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Sedang memuat data layanan...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (produkData == null || errorMessage != null) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Error'),
        body: Center(child: _buildRetryButton()),
      );
    }

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();
        String imagePath = produkData?['image_path'] ?? '';

        return ThemedScaffold(
          appBar: ThemedAppBar(
            title: produkData!['nama_produk'] ?? 'Detail Layanan',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section - Updated to match admin_detail_layanan.dart
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

                // Title and Description Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produkData!['nama_produk'] ??
                            'Nama Layanan Tidak Tersedia',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ProdukService.getDefaultDescription(
                          produkData!['nama_produk'] ?? '',
                          produkData!['deskripsi'],
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      // Harga
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ProdukService.formatHarga(produkData!['harga']),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
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
                        idProduk: produkData!['id_produk']?.toString() ??
                            widget.idProduk,
                        produkData: produkData!,
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
      final response = await Supabase.instance.client
          .from('promo')
          .select()
          .eq('id_produk', widget.idProduk)
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

    finalPrice = originalPrice;
    discountAmount = 0;

    if (selectedPromo != null && availablePromos.isNotEmpty) {
      try {
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
      } catch (e) {
        // Handle error silently
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
          'price': _formatPrice(finalPrice),
          'discount_amount':
              discountAmount > 0 ? _formatPrice(discountAmount) : null,
          'promo_used': selectedPromo,
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
                  ? 'Booking berhasil dengan promo $selectedPromo!'
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

  Future<void> _claimPromo(String promoTitle) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('claimed_promos').insert({
        'user_id': user.id,
        'promo_title': promoTitle,
      });
    } catch (e) {
      // Handle error silently
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
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Mencari promo tersedia...'),
                    ],
                  ),
                )
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
