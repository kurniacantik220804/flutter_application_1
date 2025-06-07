import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_supabase.dart';

class AdminPromoService extends GetxController {
  static AdminPromoService get to => Get.find<AdminPromoService>();

  final SupabaseService _supabaseService = SupabaseService.to;
  
  final RxList<Map<String, dynamic>> allPromos = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> activePromos = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> inactivePromos = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString error = ''.obs;

  // Static method untuk register service
  static void initialize() {
    if (!Get.isRegistered<AdminPromoService>()) {
      Get.put(AdminPromoService(), permanent: true);
    }
  }

  // Static method untuk get instance dengan safe check
  static AdminPromoService getInstance() {
    try {
      return Get.find<AdminPromoService>();
    } catch (e) {
      Get.put(AdminPromoService(), permanent: true);
      return Get.find<AdminPromoService>();
    }
  }

  // Dropdown options
  final List<Map<String, String>> productCategories = [
    {'value': 'Potong Rambut', 'label': 'Potong Rambut'},
    {'value': 'Perawatan Wajah', 'label': 'Perawatan Wajah'},
    {'value': 'Tata_Rias', 'label': 'Tata Rias'},
    {'value': 'Perawatan_Rambut', 'label': 'Perawatan Rambut'},
  ];

  final List<Map<String, String>> promoTypes = [
    {'value': 'discount', 'label': 'Diskon Persentase'},
  ];

  @override
  void onInit() {
    super.onInit();
    print('AdminPromoService onInit called');
    _initializeService();
  }

  @override
  void onReady() {
    super.onReady();
    print('AdminPromoService onReady called');
  }

  // Initialize service dengan error handling
  Future<void> _initializeService() async {
    try {
      print('Initializing AdminPromoService...');
      await _checkDatabaseConnection();
      await loadAllPromos();
      print('AdminPromoService initialized successfully');
    } catch (e) {
      print('Error initializing AdminPromoService: $e');
      error.value = 'Gagal menginisialisasi service promo: $e';
    }
  }

  // Check database connection
  Future<bool> _checkDatabaseConnection() async {
    try {
      print('Checking database connection...');
      // Test koneksi dengan query sederhana
      await _supabaseService.client.from('promo').select('count').limit(1);
      print('Database connection successful');
      return true;
    } catch (e) {
      print('Database connection error: $e');
      throw Exception('Koneksi database gagal: $e');
    }
  }

  // Load semua promo untuk admin
  Future<void> loadAllPromos() async {
    try {
      isLoading.value = true;
      error.value = '';

      print('Loading promos from database...');

      final response = await _supabaseService.client
          .from('promo')
          .select('*')
          .order('created_at', ascending: false);

      print('Database response received: ${response?.length ?? 0} items');

      if (response == null) {
        throw Exception('Response dari database kosong');
      }

      // Convert dan format data
      final formattedPromos = (response as List)
          .map((promo) => _formatPromoData(Map<String, dynamic>.from(promo)))
          .toList();
      
      allPromos.value = formattedPromos;
      
      // Filter promo aktif dan tidak aktif
      _filterPromos();

      print('Successfully loaded ${allPromos.length} promos');
      error.value = '';

    } catch (e) {
      print('Error loading admin promos: $e');
      error.value = 'Gagal memuat data promo: $e';
      
      Get.snackbar(
        'Error',
        'Gagal memuat data promo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Format data promo dari database dengan error handling
  Map<String, dynamic> _formatPromoData(Map<String, dynamic> promo) {
    try {
      // Format tanggal dengan null safety
      String validity = 'Berlaku selamanya';
      if (promo['tanggal_berakhir'] != null) {
        try {
          final endDate = DateTime.parse(promo['tanggal_berakhir'].toString());
          validity = 'Berlaku hingga ${_formatDate(endDate)}';
        } catch (e) {
          print('Error parsing end date: $e');
          validity = 'Tanggal tidak valid';
        }
      }

      // Format harga dengan null safety
      String originalPrice = 'Rp 0';
      if (promo['harga_asli'] != null) {
        try {
          originalPrice = 'Rp ${_formatCurrency(promo['harga_asli'])}';
        } catch (e) {
          print('Error formatting original price: $e');
        }
      }
      
      String promoPrice = 'GRATIS';
      if (promo['harga_promo'] != null && promo['harga_promo'] > 0) {
        try {
          promoPrice = 'Rp ${_formatCurrency(promo['harga_promo'])}';
        } catch (e) {
          print('Error formatting promo price: $e');
        }
      }

      // Status aktif/tidak aktif dengan null safety
      bool isActive = false;
      try {
        isActive = (promo['status'] ?? 'nonaktif') == 'aktif' && 
                   (promo['is_active'] ?? false) &&
                   (promo['tanggal_berakhir'] == null || 
                    DateTime.parse(promo['tanggal_berakhir'].toString()).isAfter(DateTime.now()));
      } catch (e) {
        print('Error determining active status: $e');
      }

      return {
        'id': promo['id'] ?? 0,
        'title': promo['nama_promo'] ?? 'Promo Tanpa Nama',
        'description': promo['deskripsi'] ?? '',
        'validity': validity,
        'original_price': originalPrice,
        'promo_price': promoPrice,
        'discount_percent': promo['diskon_persen'] ?? 0,
        'product_category': promo['id_produk'] ?? '',
        'promo_code': promo['promo_code'] ?? '',
        'promo_type': promo['promo_type'] ?? 'discount',
        'status': promo['status'] ?? 'aktif',
        'is_active': isActive,
        'max_usage': promo['max_usage'],
        'current_usage': promo['current_usage'] ?? 0,
        'min_purchase': promo['min_purchase_amount'] ?? 0,
        'created_at': promo['created_at'],
        'updated_at': promo['updated_at'],
        'tanggal_mulai': promo['tanggal_mulai'],
        'tanggal_berakhir': promo['tanggal_berakhir'],
        'terms_conditions': promo['terms_conditions'] ?? '',
        'banner_url': promo['banner_image_url'] ?? '',
        'priority': promo['priority_order'] ?? 0,
        // Style untuk UI
        'color': _getPromoStyle(promo['id_produk'])['color'],
        'icon': _getPromoStyle(promo['id_produk'])['icon'],
      };
    } catch (e) {
      print('Error formatting promo data: $e');
      // Return minimal data jika ada error
      return {
        'id': promo['id'] ?? 0,
        'title': 'Error: Data tidak valid',
        'description': 'Terjadi kesalahan saat memformat data',
        'validity': 'Tidak valid',
        'original_price': 'Rp 0',
        'promo_price': 'Rp 0',
        'discount_percent': 0,
        'product_category': '',
        'promo_code': '',
        'promo_type': 'discount',
        'status': 'nonaktif',
        'is_active': false,
        'max_usage': null,
        'current_usage': 0,
        'min_purchase': 0,
        'created_at': null,
        'updated_at': null,
        'tanggal_mulai': null,
        'tanggal_berakhir': null,
        'terms_conditions': '',
        'banner_url': '',
        'priority': 0,
        'color': 'primary',
        'icon': 'local_offer',
      };
    }
  }

  // Filter promo berdasarkan status
  void _filterPromos() {
    try {
      activePromos.value = allPromos.where((promo) => promo['is_active'] == true).toList();
      inactivePromos.value = allPromos.where((promo) => promo['is_active'] == false).toList();
      print('Filtered: ${activePromos.length} active, ${inactivePromos.length} inactive');
    } catch (e) {
      print('Error filtering promos: $e');
      activePromos.clear();
      inactivePromos.clear();
    }
  }

  // Tambah promo baru dengan validation yang lebih baik
  Future<bool> addPromo({
    required String namaPromo,
    required String deskripsi,
    required String idProduk,
    int hargaAsli = 0,
    int hargaPromo = 0,
    int diskonPersen = 0,
    DateTime? tanggalMulai,
    DateTime? tanggalBerakhir,
    String? promoCode,
    String promoType = 'discount',
    int? maxUsage,
    int minPurchase = 0,
    String? termsConditions,
    String? bannerUrl,
    int priority = 0,
  }) async {
    try {
      isSubmitting.value = true;
      error.value = '';

      print('Adding new promo: $namaPromo');

      // Validasi input
      final validationError = validatePromoData(
        namaPromo: namaPromo,
        deskripsi: deskripsi,
        idProduk: idProduk,
        tanggalBerakhir: tanggalBerakhir,
        promoCode: promoCode,
      );

      if (validationError != null) {
        error.value = validationError;
        Get.snackbar(
          'Validasi Error',
          validationError,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }

      // Validasi promo code unik jika ada
      if (promoCode != null && promoCode.isNotEmpty) {
        print('Checking promo code uniqueness: $promoCode');
        
        final existing = await _supabaseService.client
            .from('promo')
            .select('id')
            .eq('promo_code', promoCode.toUpperCase())
            .maybeSingle();
        
        if (existing != null) {
          error.value = 'Kode promo sudah digunakan';
          Get.snackbar(
            'Error',
            'Kode promo "$promoCode" sudah digunakan',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return false;
        }
      }

      // Prepare data untuk insert
      final promoData = {
        'nama_promo': namaPromo.trim(),
        'deskripsi': deskripsi.trim(),
        'id_produk': idProduk,
        'harga_asli': hargaAsli,
        'harga_promo': hargaPromo,
        'diskon_persen': diskonPersen,
        'tanggal_mulai': tanggalMulai?.toIso8601String(),
        'tanggal_berakhir': tanggalBerakhir?.toIso8601String(),
        'promo_code': promoCode?.toUpperCase(),
        'promo_type': promoType,
        'max_usage': maxUsage,
        'current_usage': 0,
        'min_purchase_amount': minPurchase,
        'terms_conditions': termsConditions?.trim(),
        'banner_image_url': bannerUrl?.trim(),
        'priority_order': priority,
        'status': 'aktif',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      promoData.removeWhere((key, value) => value == null);

      print('Inserting promo data: $promoData');

      // Insert ke database
      final response = await _supabaseService.client
          .from('promo')
          .insert(promoData)
          .select()
          .single();

      print('Insert response: $response');

      // Log audit
      await _logAuditAction('CREATE', null, promoData);

      // Reload data
      await loadAllPromos();
      
      Get.snackbar(
        'Berhasil',
        'Promo "$namaPromo" berhasil ditambahkan!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      print('Error adding promo: $e');
      error.value = 'Gagal menambahkan promo: $e';
      
      Get.snackbar(
        'Error',
        'Gagal menambahkan promo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update promo dengan error handling yang lebih baik
  Future<bool> updatePromo(int promoId, Map<String, dynamic> updates) async {
    try {
      isSubmitting.value = true;
      error.value = '';

      print('Updating promo ID: $promoId with data: $updates');

      // Get old data untuk audit log
      final oldData = await _supabaseService.client
          .from('promo')
          .select('*')
          .eq('id', promoId)
          .single();

      // Add timestamp to updates
      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update database
      final response = await _supabaseService.client
          .from('promo')
          .update(updateData)
          .eq('id', promoId)
          .select()
          .single();

      print('Update response: $response');

      // Log audit
      await _logAuditAction('UPDATE', oldData, updateData, promoId: promoId);

      await loadAllPromos();
      
      Get.snackbar(
        'Berhasil',
        'Promo berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      print('Error updating promo: $e');
      error.value = 'Gagal memperbarui promo: $e';
      
      Get.snackbar(
        'Error',
        'Gagal memperbarui promo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Delete promo
  Future<bool> deletePromo(int promoId, String promoName) async {
    try {
      print('Deleting promo ID: $promoId');

      // Get data untuk audit log
      final promoData = await _supabaseService.client
          .from('promo')
          .select('*')
          .eq('id', promoId)
          .single();

      // Delete dari database
      await _supabaseService.client
          .from('promo')
          .delete()
          .eq('id', promoId);

      // Log audit
      await _logAuditAction('DELETE', promoData, null, promoId: promoId);

      await loadAllPromos();
      
      Get.snackbar(
        'Berhasil',
        'Promo "$promoName" berhasil dihapus!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      print('Error deleting promo: $e');
      Get.snackbar(
        'Error',
        'Gagal menghapus promo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  // Toggle status promo (aktif/nonaktif)
  Future<bool> togglePromoStatus(int promoId, bool newStatus) async {
    try {
      await updatePromo(promoId, {
        'is_active': newStatus,
        'status': newStatus ? 'aktif' : 'nonaktif',
      });

      // Log audit
      await _logAuditAction(
        newStatus ? 'ACTIVATE' : 'DEACTIVATE', 
        null, 
        {'is_active': newStatus},
        promoId: promoId,
      );

      return true;
    } catch (e) {
      print('Error toggling promo status: $e');
      return false;
    }
  }

  // Get statistik promo untuk admin
  Map<String, dynamic> getAdminPromoStatistics() {
    try {
      final total = allPromos.length;
      final active = activePromos.length;
      final inactive = inactivePromos.length;
      final totalUsage = allPromos.fold(0, (sum, promo) => sum + (promo['current_usage'] as int));
      
      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'total_usage': totalUsage,
        'usage_rate': total > 0 ? ((totalUsage / total) * 100).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'total_usage': 0,
        'usage_rate': '0',
      };
    }
  }

  // Log audit action dengan error handling
  Future<void> _logAuditAction(
    String action, 
    Map<String, dynamic>? oldValues, 
    Map<String, dynamic>? newValues,
    {int? promoId, String? reason}
  ) async {
    try {
      final user = _supabaseService.currentUser;
      
      await _supabaseService.client.from('promo_audit_log').insert({
        'promo_id': promoId,
        'action': action,
        'old_values': oldValues,
        'new_values': newValues,
        'changed_by': user?.email ?? 'System',
        'change_reason': reason,
        'changed_at': DateTime.now().toIso8601String(),
      });
      
      print('Audit log created: $action for promo $promoId');
    } catch (e) {
      print('Error logging audit action: $e');
      // Tidak throw error karena audit log tidak critical
    }
  }

  // Helper functions
  Map<String, String> _getPromoStyle(String? idProduk) {
    switch (idProduk?.toLowerCase()) {
      case 'potong rambut':
        return {'color': 'primary', 'icon': 'cut'};
      case 'perawatan wajah':
        return {'color': 'secondary', 'icon': 'spa'};
      case 'tata_rias':
        return {'color': 'orange', 'icon': 'brush'};
      case 'perawatan_rambut':
        return {'color': 'purple', 'icon': 'straighten'};
      case 'manicure_pedicure':
        return {'color': 'pink', 'icon': 'pan_tool'};
      case 'spa_treatment':
        return {'color': 'green', 'icon': 'spa'};
      default:
        return {'color': 'primary', 'icon': 'local_offer'};
    }
  }

  String _formatDate(DateTime date) {
    try {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Format tanggal error';
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final intAmount = amount is int ? amount : int.parse(amount.toString());
      return intAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      print('Error formatting currency: $e');
      return '0';
    }
  }

  // Validate promo data dengan error handling yang lebih baik
  String? validatePromoData({
    required String namaPromo,
    required String deskripsi,
    required String idProduk,
    DateTime? tanggalBerakhir,
    String? promoCode,
  }) {
    try {
      if (namaPromo.trim().isEmpty) {
        return 'Nama promo tidak boleh kosong';
      }
      
      if (namaPromo.trim().length < 3) {
        return 'Nama promo minimal 3 karakter';
      }
      
      if (deskripsi.trim().isEmpty) {
        return 'Deskripsi promo tidak boleh kosong';
      }
      
      if (deskripsi.trim().length < 10) {
        return 'Deskripsi promo minimal 10 karakter';
      }
      
      if (idProduk.trim().isEmpty) {
        return 'Kategori produk harus dipilih';
      }
      
      // Validasi kategori produk harus ada dalam daftar yang valid
      final validCategories = productCategories.map((e) => e['value']).toList();
      if (!validCategories.contains(idProduk)) {
        return 'Kategori produk tidak valid';
      }
      
      if (tanggalBerakhir != null && tanggalBerakhir.isBefore(DateTime.now())) {
        return 'Tanggal berakhir tidak boleh kurang dari hari ini';
      }
      
      if (promoCode != null && promoCode.isNotEmpty) {
        if (promoCode.length < 3) {
          return 'Kode promo minimal 3 karakter';
        }
        if (promoCode.length > 20) {
          return 'Kode promo maksimal 20 karakter';
        }
        if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(promoCode.toUpperCase())) {
          return 'Kode promo hanya boleh mengandung huruf besar, angka, underscore, dan dash';
        }
      }
      
      return null;
    } catch (e) {
      print('Error in validation: $e');
      return 'Terjadi kesalahan saat validasi data';
    }
  }

  // Search promos dengan error handling
  List<Map<String, dynamic>> searchPromos(String query) {
    try {
      if (query.isEmpty) return allPromos;
      
      final lowercaseQuery = query.toLowerCase();
      return allPromos.where((promo) {
        return (promo['title'] ?? '').toLowerCase().contains(lowercaseQuery) ||
               (promo['description'] ?? '').toLowerCase().contains(lowercaseQuery) ||
               (promo['product_category'] ?? '').toLowerCase().contains(lowercaseQuery) ||
               (promo['promo_code'] ?? '').toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching promos: $e');
      return [];
    }
  }

  // Check if service is ready
  bool get isReady => !isLoading.value && error.value.isEmpty;

  // Refresh data
  Future<void> refresh() async {
    await loadAllPromos();
  }

  @override
  void onClose() {
    // Cleanup jika diperlukan
    print('AdminPromoService onClose called');
    super.onClose();
  }
}