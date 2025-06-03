import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/service_supabase.dart';

class AdminPromoService extends GetxController {
  static AdminPromoService get to => Get.find();

  final SupabaseService _supabaseService = SupabaseService.to;
  final RxList<Map<String, dynamic>> allPromos = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllPromos();
  }

  // Load semua promo untuk admin
  Future<void> loadAllPromos() async {
    try {
      isLoading.value = true;

      final response = await _supabaseService.client
          .from('promo')
          .select()
          .order('created_at', ascending: false);

      allPromos.value = List<Map<String, dynamic>>.from(response);
      print('Loaded ${allPromos.length} promos for admin');
    } catch (e) {
      print('Error loading all promos: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat data promo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Tambah promo baru
  Future<bool> addPromo({
    required String namaPromo,
    required String idProduk,
    required String deskripsi,
    required int diskonPersen,
    required int hargaAsli,
    required int hargaPromo,
    DateTime? tanggalBerakhir,
    String status = 'aktif',
  }) async {
    try {
      isLoading.value = true;

      final response = await _supabaseService.client.from('promo').insert({
        'nama_promo': namaPromo,
        'id_produk': idProduk,
        'deskripsi': deskripsi,
        'diskon_persen': diskonPersen,
        'harga_asli': hargaAsli,
        'harga_promo': hargaPromo,
        'tanggal_berakhir': tanggalBerakhir?.toIso8601String(),
        'status': status,
      }).select();

      await loadAllPromos(); // Refresh data

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
      Get.snackbar(
        'Error',
        'Gagal menambahkan promo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update promo
  Future<bool> updatePromo({
    required int promoId,
    required String namaPromo,
    required String idProduk,
    required String deskripsi,
    required int diskonPersen,
    required int hargaAsli,
    required int hargaPromo,
    DateTime? tanggalBerakhir,
    String status = 'aktif',
  }) async {
    try {
      isLoading.value = true;

      await _supabaseService.client.from('promo').update({
        'nama_promo': namaPromo,
        'id_produk': idProduk,
        'deskripsi': deskripsi,
        'diskon_persen': diskonPersen,
        'harga_asli': hargaAsli,
        'harga_promo': hargaPromo,
        'tanggal_berakhir': tanggalBerakhir?.toIso8601String(),
        'status': status,
      }).eq('id', promoId);

      await loadAllPromos(); // Refresh data

      Get.snackbar(
        'Berhasil',
        'Promo "$namaPromo" berhasil diupdate!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      print('Error updating promo: $e');
      Get.snackbar(
        'Error',
        'Gagal mengupdate promo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Hapus promo
  Future<bool> deletePromo(int promoId, String namaPromo) async {
    try {
      isLoading.value = true;

      // Hapus dari claimed_promos dulu untuk menghindari foreign key constraint
      await _supabaseService.client
          .from('claimed_promos')
          .delete()
          .eq('promo_title', namaPromo);

      // Kemudian hapus promo
      await _supabaseService.client.from('promo').delete().eq('id', promoId);

      await loadAllPromos(); // Refresh data

      Get.snackbar(
        'Berhasil',
        'Promo "$namaPromo" berhasil dihapus!',
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
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle status promo (aktif/nonaktif)
  Future<bool> togglePromoStatus(int promoId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'aktif' ? 'nonaktif' : 'aktif';

      await _supabaseService.client
          .from('promo')
          .update({'status': newStatus}).eq('id', promoId);

      await loadAllPromos(); // Refresh data

      Get.snackbar(
        'Berhasil',
        'Status promo berhasil diubah menjadi $newStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      print('Error toggling promo status: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah status promo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Get statistik promo
  Future<Map<String, int>> getPromoStatistics() async {
    try {
      final response = await _supabaseService.client.from('promo').select();

      final totalPromos = response.length;
      final activePromos = response
          .where((promo) =>
              promo['status'] == 'aktif' &&
              (promo['tanggal_berakhir'] == null ||
                  DateTime.parse(promo['tanggal_berakhir'])
                      .isAfter(DateTime.now())))
          .length;
      final expiredPromos = response
          .where((promo) =>
              promo['tanggal_berakhir'] != null &&
              DateTime.parse(promo['tanggal_berakhir'])
                  .isBefore(DateTime.now()))
          .length;

      return {
        'total': totalPromos,
        'active': activePromos,
        'expired': expiredPromos,
        'inactive': totalPromos - activePromos - expiredPromos,
      };
    } catch (e) {
      print('Error getting promo statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'expired': 0,
        'inactive': 0,
      };
    }
  }

  // Get promo berdasarkan ID produk
  List<Map<String, dynamic>> getPromosByProduct(String idProduk) {
    return allPromos.where((promo) => promo['id_produk'] == idProduk).toList();
  }

  // Get promo aktif saja
  List<Map<String, dynamic>> getActivePromos() {
    return allPromos
        .where((promo) =>
            promo['status'] == 'aktif' &&
            (promo['tanggal_berakhir'] == null ||
                DateTime.parse(promo['tanggal_berakhir'])
                    .isAfter(DateTime.now())))
        .toList();
  }

  // Validasi input promo
  String? validatePromoInput({
    required String namaPromo,
    required String idProduk,
    required int diskonPersen,
    required int hargaAsli,
    required int hargaPromo,
  }) {
    if (namaPromo.trim().isEmpty) {
      return 'Nama promo tidak boleh kosong';
    }
    if (idProduk.trim().isEmpty) {
      return 'ID produk tidak boleh kosong';
    }
    if (diskonPersen < 0 || diskonPersen > 100) {
      return 'Diskon harus antara 0-100%';
    }
    if (hargaAsli <= 0) {
      return 'Harga asli harus lebih dari 0';
    }
    if (hargaPromo < 0) {
      return 'Harga promo tidak boleh negatif';
    }
    if (hargaPromo >= hargaAsli && diskonPersen > 0) {
      return 'Harga promo harus lebih kecil dari harga asli';
    }

    return null; // Valid
  }

  // Calculate harga promo otomatis berdasarkan persentase diskon
  int calculatePromoPrice(int hargaAsli, int diskonPersen) {
    if (diskonPersen >= 100) return 0;
    return hargaAsli - ((hargaAsli * diskonPersen) / 100).round();
  }

  // Calculate persentase diskon otomatis berdasarkan harga
  int calculateDiscountPercent(int hargaAsli, int hargaPromo) {
    if (hargaAsli <= 0) return 0;
    if (hargaPromo <= 0) return 100;
    return (((hargaAsli - hargaPromo) / hargaAsli) * 100).round();
  }
}
