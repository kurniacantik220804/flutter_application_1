import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/database/admin_promo_service.dart';

class AdminPromoManagementScreen extends StatefulWidget {
  const AdminPromoManagementScreen({super.key});

  @override
  State<AdminPromoManagementScreen> createState() => _AdminPromoManagementScreenState();
}

class _AdminPromoManagementScreenState extends State<AdminPromoManagementScreen> {
  final ThemeController themeController = ThemeController.to;
  late AdminPromoService adminPromoService;

  @override
  void initState() {
    super.initState();
    // Initialize service dengan lazy put jika belum ada
    if (!Get.isRegistered<AdminPromoService>()) {
      Get.lazyPut(() => AdminPromoService());
    }
    adminPromoService = Get.find<AdminPromoService>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adminPromoService.loadAllPromos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = themeController.getThemeColors();

      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Tambah Promo Baru'),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AddPromoForm(colors: colors),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class AddPromoForm extends StatefulWidget {
  final dynamic colors;

  const AddPromoForm({super.key, required this.colors});

  @override
  State<AddPromoForm> createState() => _AddPromoFormState();
}

class _AddPromoFormState extends State<AddPromoForm> {
  late AdminPromoService adminPromoService;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _namaPromoController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaAsliController = TextEditingController();
  final _hargaPromoController = TextEditingController();
  final _diskonPersenController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _maxUsageController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _termsConditionsController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _priorityController = TextEditingController();

  // Form state
  String _selectedCategory = '';
  String _selectedPromoType = 'discount';
  DateTime? _tanggalMulai;
  DateTime? _tanggalBerakhir;

  @override
  void initState() {
    super.initState();
    // Get service yang sudah di-register
    try {
      adminPromoService = Get.find<AdminPromoService>();
    } catch (e) {
      // Fallback jika service belum di-register
      Get.lazyPut(() => AdminPromoService());
      adminPromoService = Get.find<AdminPromoService>();
    }
  }

  @override
  void dispose() {
    _namaPromoController.dispose();
    _deskripsiController.dispose();
    _hargaAsliController.dispose();
    _hargaPromoController.dispose();
    _diskonPersenController.dispose();
    _promoCodeController.dispose();
    _maxUsageController.dispose();
    _minPurchaseController.dispose();
    _termsConditionsController.dispose();
    _bannerUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminPromoService>(
      builder: (service) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Promo Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.colors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Nama Promo
              _buildTextField(
                controller: _namaPromoController,
                label: 'Nama Promo *',
                icon: Icons.local_offer,
                validator: (value) => value?.isEmpty ?? true ? 'Nama promo harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Deskripsi
              _buildTextField(
                controller: _deskripsiController,
                label: 'Deskripsi *',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Deskripsi harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kategori Produk
              _buildDropdownField(
                label: 'Kategori Produk *',
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                items: service.productCategories,
                onChanged: (value) => setState(() => _selectedCategory = value!),
                validator: (value) => value == null ? 'Pilih kategori produk' : null,
              ),
              const SizedBox(height: 16),

              // Tipe Promo
              _buildDropdownField(
                label: 'Tipe Promo *',
                value: _selectedPromoType,
                items: service.promoTypes,
                onChanged: (value) => setState(() => _selectedPromoType = value!),
              ),
              const SizedBox(height: 16),

              // Harga
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _hargaAsliController,
                      label: 'Harga Asli',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      onChanged: _calculateDiscount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _hargaPromoController,
                      label: 'Harga Promo',
                      icon: Icons.local_offer,
                      keyboardType: TextInputType.number,
                      onChanged: _calculateDiscount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Diskon Persen (auto-calculated or manual)
              _buildTextField(
                controller: _diskonPersenController,
                label: 'Diskon Persen (%)',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                readOnly: _hargaAsliController.text.isNotEmpty && _hargaPromoController.text.isNotEmpty,
              ),
              const SizedBox(height: 16),
              // Tanggal
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Tanggal Mulai',
                      selectedDate: _tanggalMulai,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Tanggal Berakhir',
                      selectedDate: _tanggalBerakhir,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: service.isSubmitting.value ? null : _submitPromo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: service.isSubmitting.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Tambah Promo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          selectedDate != null
              ? _formatDate(selectedDate)
              : 'Pilih tanggal',
          style: TextStyle(
            color: selectedDate != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _calculateDiscount(String value) {
    final hargaAsli = int.tryParse(_hargaAsliController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final hargaPromo = int.tryParse(_hargaPromoController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (hargaAsli != null && hargaPromo != null && hargaAsli > 0 && hargaPromo < hargaAsli) {
      final diskon = (((hargaAsli - hargaPromo) / hargaAsli) * 100).round();
      _diskonPersenController.text = diskon.toString();
    } else {
      _diskonPersenController.text = '0';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _tanggalMulai = picked;
        } else {
          _tanggalBerakhir = picked;
        }
      });
    }
  }

  Future<void> _submitPromo() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tambahan
    final validationError = adminPromoService.validatePromoData(
      namaPromo: _namaPromoController.text,
      deskripsi: _deskripsiController.text,
      idProduk: _selectedCategory,
      tanggalBerakhir: _tanggalBerakhir,
      promoCode: _promoCodeController.text.isEmpty ? null : _promoCodeController.text,
    );

    if (validationError != null) {
      Get.snackbar(
        'Validasi Error',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Submit promo
    final success = await adminPromoService.addPromo(
      namaPromo: _namaPromoController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      idProduk: _selectedCategory,
      hargaAsli: int.tryParse(_hargaAsliController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      hargaPromo: int.tryParse(_hargaPromoController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      diskonPersen: int.tryParse(_diskonPersenController.text) ?? 0,
      tanggalMulai: _tanggalMulai,
      tanggalBerakhir: _tanggalBerakhir,
      promoCode: _promoCodeController.text.isEmpty ? null : _promoCodeController.text.trim().toUpperCase(),
      promoType: _selectedPromoType,
      maxUsage: _maxUsageController.text.isEmpty ? null : int.tryParse(_maxUsageController.text),
      minPurchase: int.tryParse(_minPurchaseController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      termsConditions: _termsConditionsController.text.isEmpty ? null : _termsConditionsController.text.trim(),
      bannerUrl: _bannerUrlController.text.isEmpty ? null : _bannerUrlController.text.trim(),
      priority: int.tryParse(_priorityController.text) ?? 0,
    );

    if (success) {
      _clearForm();
    }
  }

  void _clearForm() {
    _namaPromoController.clear();
    _deskripsiController.clear();
    _hargaAsliController.clear();
    _hargaPromoController.clear();
    _diskonPersenController.clear();
    _promoCodeController.clear();
    _maxUsageController.clear();
    _minPurchaseController.clear();
    _termsConditionsController.clear();
    _bannerUrlController.clear();
    _priorityController.clear();

    setState(() {
      _selectedCategory = '';
      _selectedPromoType = 'discount';
      _tanggalMulai = null;
      _tanggalBerakhir = null;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}