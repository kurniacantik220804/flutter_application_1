import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_supabase.dart';

class PromoService extends GetxController {
  static PromoService get to => Get.find();

  final SupabaseService _supabaseService = SupabaseService.to;

  // List untuk menyimpan promo yang tersedia
  final RxList<Map<String, dynamic>> availablePromos =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> claimedPromos =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allPromos = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromos();
  }

  // Load promo yang tersedia untuk user
  Future<void> loadPromos() async {
    try {
      isLoading.value = true;

      final user = _supabaseService.currentUser;
      if (user == null) {
        print('User not authenticated');
        _loadDefaultPromos(); // Fallback ke default promo jika user tidak login
        return;
      }

      // Load semua promo aktif dari database
      await _loadAllPromosFromDatabase();

      // Jika tidak ada promo di database, gunakan default promos
      if (allPromos.isEmpty) {
        print('No promos in database, using default promos');
        _loadDefaultPromos();
        return;
      }

      // Get claimed promos untuk user ini dari tabel claimed_promos
      final claimedResponse = await _supabaseService.client
          .from('claimed_promos')
          .select('promo_title')
          .eq('user_id', user.id);

      final claimedTitles = claimedResponse
          .map((item) => item['promo_title'].toString())
          .toList();

      // Filter promo yang belum diklaim
      final available = allPromos
          .where((promo) =>
              !claimedTitles.contains(promo['nama_promo'] ?? promo['title']))
          .toList();

      // Filter promo yang sudah diklaim
      final claimed = allPromos
          .where((promo) =>
              claimedTitles.contains(promo['nama_promo'] ?? promo['title']))
          .toList();

      availablePromos.value = available;
      claimedPromos.value = claimed;

      print('Available promos: ${available.length}');
      print('Claimed promos: ${claimed.length}');
    } catch (e) {
      print('Error loading promos: $e');

      // Fallback ke default promos jika ada error
      _loadDefaultPromos();

      Get.snackbar(
        'Info',
        'Menggunakan promo default karena: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load semua promo aktif dari database
  Future<void> _loadAllPromosFromDatabase() async {
    try {
      final response = await _supabaseService.client
          .from('promo')
          .select('*')
          .eq('status', 'aktif')
          .or('tanggal_berakhir.is.null,tanggal_berakhir.gte.${DateTime.now().toIso8601String().split('T')[0]}')
          .order('created_at', ascending: false);

      // Convert database format ke format yang digunakan aplikasi
      final convertedPromos = response.map((promo) {
        // Format tanggal berakhir
        String validity = 'Berlaku selamanya';
        if (promo['tanggal_berakhir'] != null) {
          final endDate = DateTime.parse(promo['tanggal_berakhir']);
          validity = 'Berlaku hingga ${_formatDate(endDate)}';
        }

        // Format harga
        String originalPrice =
            'Rp ${_formatCurrency(promo['harga_asli'] ?? 0)}';
        String promoPrice = 'GRATIS';

        if (promo['harga_promo'] != null && promo['harga_promo'] > 0) {
          promoPrice = 'Rp ${_formatCurrency(promo['harga_promo'])}';
        } else if (promo['diskon_persen'] == 100) {
          promoPrice = 'GRATIS';
        }

        // Tentukan warna dan icon berdasarkan id_produk
        Map<String, String> styleInfo = _getPromoStyle(promo['id_produk']);

        return {
          'title': promo['nama_promo'] ?? 'Promo Spesial',
          'validity': validity,
          'description': promo['deskripsi'] ?? 'Promo spesial dari salon kami',
          'color': styleInfo['color'],
          'icon': styleInfo['icon'],
          'original_price': originalPrice,
          'promo_price': promoPrice,
          'discount_percent': promo['diskon_persen'] ?? 0,
          'nama_promo': promo['nama_promo'], // Keep original name for reference
          'id_produk': promo['id_produk'],
          'id': promo['id'],
          'harga_asli': promo['harga_asli'],
          'harga_promo': promo['harga_promo'],
          'tanggal_berakhir': promo['tanggal_berakhir'],
        };
      }).toList();

      allPromos.value = List<Map<String, dynamic>>.from(convertedPromos);
      print('Loaded ${allPromos.length} promos from database');
    } catch (e) {
      print('Error loading promos from database: $e');
      allPromos.value = [];
    }
  }

  // Helper function untuk styling berdasarkan jenis produk
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
      default:
        return {'color': 'primary', 'icon': 'local_offer'};
    }
  }

  // Helper function untuk format tanggal
  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper function untuk format currency
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Fallback ke default promos (tetap ada untuk backup)
  void _loadDefaultPromos() {
    final defaultPromos = [
      {
        'title': 'Diskon 30% Potong Rambut',
        'validity': 'Berlaku hingga 31 Desember 2025',
        'description':
            'Nikmati potongan rambut dengan harga spesial! Dapatkan diskon 30% untuk layanan potong rambut kami.',
        'color': 'primary',
        'icon': 'cut',
        'original_price': 'Rp 25.000',
        'promo_price': 'Rp 17.500',
        'discount_percent': 30,
        'nama_promo': 'Diskon 30% Potong Rambut',
        'id_produk': 'Potong Rambut',
      },
      {
        'title': 'Diskon 15% Perawatan Wajah',
        'validity': 'Berlaku hingga 31 Desember 2025',
        'description':
            'Dapatkan perawatan wajah terbaik dengan diskon spesial 15% untuk semua layanan perawatan wajah.',
        'color': 'secondary',
        'icon': 'spa',
        'original_price': 'Rp 40.000',
        'promo_price': 'Rp 34.000',
        'discount_percent': 15,
        'nama_promo': 'Diskon 15% Perawatan Wajah',
        'id_produk': 'Perawatan Wajah',
      },
      {
        'title': 'Paket Hemat Makeup',
        'validity': 'Stok terbatas!',
        'description':
            'Paket spesial makeup untuk acara formal dengan harga spesial dan bonus produk kecantikan dari sponsor kami.',
        'color': 'orange',
        'icon': 'brush',
        'original_price': 'Rp 70.000',
        'promo_price': 'Rp 55.000',
        'discount_percent': 21,
        'nama_promo': 'Paket Hemat Makeup',
        'id_produk': 'Tata_Rias',
      },
      {
        'title': 'Free Layanan Catok Rambut',
        'validity': 'Berlaku hingga 31 Desember 2025',
        'description':
            'Dapatkan layanan catok rambut gratis untuk setiap pembelian layanan perawatan rambut lainnya.',
        'color': 'purple',
        'icon': 'straighten',
        'original_price': 'Rp 20.000',
        'promo_price': 'GRATIS',
        'discount_percent': 100,
        'nama_promo': 'Free Layanan Catok Rambut',
        'id_produk': 'Perawatan_Rambut',
      },
    ];

    allPromos.value = defaultPromos;

    // Jika user login, filter berdasarkan claimed promos
    if (_supabaseService.currentUser != null) {
      _filterDefaultPromos();
    } else {
      // Jika user tidak login, tampilkan semua sebagai available
      availablePromos.value = defaultPromos;
      claimedPromos.value = [];
    }
  }

  // Filter default promos berdasarkan claimed status
  Future<void> _filterDefaultPromos() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final claimedResponse = await _supabaseService.client
          .from('claimed_promos')
          .select('promo_title')
          .eq('user_id', user.id);

      final claimedTitles = claimedResponse
          .map((item) => item['promo_title'].toString())
          .toList();

      availablePromos.value = allPromos
          .where((promo) => !claimedTitles.contains(promo['title']))
          .toList();

      claimedPromos.value = allPromos
          .where((promo) => claimedTitles.contains(promo['title']))
          .toList();
    } catch (e) {
      print('Error filtering default promos: $e');
      // Jika error, tampilkan semua sebagai available
      availablePromos.value = allPromos.toList();
      claimedPromos.value = [];
    }
  }

  // Claim promo - menggunakan tabel claimed_promos dengan validasi ketat
  Future<bool> claimPromo(String promoTitle) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'Anda harus login terlebih dahulu',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Cari promo yang akan diklaim
      final promoToClaim = allPromos.firstWhereOrNull((promo) =>
          promo['nama_promo'] == promoTitle || promo['title'] == promoTitle);

      if (promoToClaim == null) {
        Get.snackbar(
          'Error',
          'Promo tidak ditemukan',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Check apakah promo masih aktif (jika ada tanggal berakhir)
      if (promoToClaim['tanggal_berakhir'] != null) {
        final endDate = DateTime.parse(promoToClaim['tanggal_berakhir']);
        if (endDate.isBefore(DateTime.now())) {
          Get.snackbar(
            'Error',
            'Promo sudah berakhir',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }

      // Double check apakah promo sudah diklaim sebelumnya
      final existingClaim = await _supabaseService.client
          .from('claimed_promos')
          .select('id')
          .eq('user_id', user.id)
          .eq('promo_title', promoTitle)
          .maybeSingle();

      if (existingClaim != null) {
        Get.snackbar(
          'Info',
          'Promo sudah diklaim sebelumnya',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Insert claim promo ke database dengan informasi lengkap
      await _supabaseService.client.from('claimed_promos').insert({
        'user_id': user.id,
        'promo_title': promoTitle,
        'claimed_at': DateTime.now().toIso8601String(),
      });

      // Refresh data promo
      await loadPromos();

      Get.snackbar(
        'Berhasil',
        'Promo "$promoTitle" berhasil diklaim!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      print('Error claiming promo: $e');
      Get.snackbar(
        'Error',
        'Gagal mengklaim promo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Get claimed promos for current user dengan detail lengkap
  Future<List<Map<String, dynamic>>> getClaimedPromos() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return [];

      final response = await _supabaseService.client
          .from('claimed_promos')
          .select()
          .eq('user_id', user.id)
          .order('claimed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting claimed promos: $e');
      return [];
    }
  }

  // Check if specific promo is claimed
  Future<bool> isPromoClaimed(String promoTitle) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return false;

      final response = await _supabaseService.client
          .from('claimed_promos')
          .select('id')
          .eq('user_id', user.id)
          .eq('promo_title', promoTitle)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking promo claim: $e');
      return false;
    }
  }

  // Get promo statistics berdasarkan data yang sudah diload
  Map<String, int> getPromoStatistics() {
    return {
      'total': allPromos.length,
      'claimed': claimedPromos.length,
      'available': availablePromos.length,
    };
  }

  // Reset user promos (untuk testing atau admin)
  Future<void> resetUserPromos() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'Anda harus login terlebih dahulu',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _supabaseService.client
          .from('claimed_promos')
          .delete()
          .eq('user_id', user.id);

      await loadPromos();

      Get.snackbar(
        'Berhasil',
        'Semua promo telah direset',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error resetting promos: $e');
      Get.snackbar(
        'Error',
        'Gagal mereset promo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Method untuk admin menambah promo ke database
  Future<bool> addPromoToDatabase({
    required String namaPromo,
    required String idProduk,
    String? deskripsi,
    int diskonPersen = 0,
    int hargaAsli = 0,
    int hargaPromo = 0,
    DateTime? tanggalBerakhir,
    String status = 'aktif',
  }) async {
    try {
      await _supabaseService.client.from('promo').insert({
        'nama_promo': namaPromo,
        'id_produk': idProduk,
        'deskripsi': deskripsi,
        'diskon_persen': diskonPersen,
        'harga_asli': hargaAsli,
        'harga_promo': hargaPromo,
        'tanggal_berakhir': tanggalBerakhir?.toIso8601String(),
        'status': status,
      });

      await loadPromos(); // Refresh data
      return true;
    } catch (e) {
      print('Error adding promo to database: $e');
      return false;
    }
  }

  // Method untuk mengupdate status promo
  Future<bool> updatePromoStatus(int promoId, String newStatus) async {
    try {
      await _supabaseService.client
          .from('promo')
          .update({'status': newStatus}).eq('id', promoId);

      await loadPromos(); // Refresh data
      return true;
    } catch (e) {
      print('Error updating promo status: $e');
      return false;
    }
  }

  // Method untuk mendapatkan riwayat penggunaan promo
  Future<List<Map<String, dynamic>>> getPromoUsageHistory() async {
    try {
      final response = await _supabaseService.client
          .from('claimed_promos')
          .select('promo_title, claimed_at, user_id')
          .order('claimed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting promo usage history: $e');
      return [];
    }
  }

  // Getter untuk default promos (untuk referensi)
  List<Map<String, dynamic>> get defaultPromos => [
        {
          'title': 'Diskon 30% Potong Rambut',
          'validity': 'Berlaku hingga 31 Desember 2025',
          'description':
              'Nikmati potongan rambut dengan harga spesial! Dapatkan diskon 30% untuk layanan potong rambut kami.',
          'color': 'primary',
          'icon': 'cut',
          'original_price': 'Rp 25.000',
          'promo_price': 'Rp 17.500',
          'discount_percent': 30,
        },
        {
          'title': 'Diskon 15% Perawatan Wajah',
          'validity': 'Berlaku hingga 31 Desember 2025',
          'description':
              'Dapatkan perawatan wajah terbaik dengan diskon spesial 15% untuk semua layanan perawatan wajah.',
          'color': 'secondary',
          'icon': 'spa',
          'original_price': 'Rp 40.000',
          'promo_price': 'Rp 34.000',
          'discount_percent': 15,
        },
        {
          'title': 'Paket Hemat Makeup',
          'validity': 'Stok terbatas!',
          'description':
              'Paket spesial makeup untuk acara formal dengan harga spesial dan bonus produk kecantikan dari sponsor kami.',
          'color': 'orange',
          'icon': 'brush',
          'original_price': 'Rp 70.000',
          'promo_price': 'Rp 55.000',
          'discount_percent': 21,
        },
        {
          'title': 'Free Layanan Catok Rambut',
          'validity': 'Berlaku hingga 31 Desember 2025',
          'description':
              'Dapatkan layanan catok rambut gratis untuk setiap pembelian layanan perawatan rambut lainnya.',
          'color': 'purple',
          'icon': 'straighten',
          'original_price': 'Rp 20.000',
          'promo_price': 'GRATIS',
          'discount_percent': 100,
        },
      ];
}
