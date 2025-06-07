import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class BookingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _storage = GetStorage();

  // Test koneksi database
  static Future<bool> testDatabaseConnection() async {
    try {
      final response = await _supabase.from('booking').select('id').limit(1);
      print('Database connection successful');
      return true;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }

  // Membuat booking baru dengan promo
  static Future<Map<String, dynamic>?> createBooking({
    required String idProduk,
    required String namaProduk,
    required String tanggal,
    required String waktu,
    required double hargaAsli,
    String metodePembayaran = 'Cash',
    int? promoId,
    int? claimedPromoId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      // Parse tanggal dari format dd/mm/yyyy ke yyyy-mm-dd
      String formattedDate = _parseDate(tanggal);
      int hargaAsliInt = hargaAsli.toInt();

      print('Creating booking with params:');
      print('User ID: ${user.id}');
      print('Product ID: $idProduk');
      print('Date: $formattedDate');
      print('Original Price: $hargaAsliInt');
      print('Promo ID: $promoId');
      print('Claimed Promo ID: $claimedPromoId');

      // Panggil function untuk membuat booking dengan promo
      final response =
          await _supabase.rpc('create_booking_with_promo', params: {
        'p_user_id': user.id,
        'p_id_produk': idProduk,
        'p_nama_produk': namaProduk,
        'p_tanggal': formattedDate,
        'p_waktu': waktu,
        'p_metode_pembayaran': metodePembayaran,
        'p_harga_asli': hargaAsliInt,
        'p_promo_id': promoId,
        'p_claimed_promo_id': claimedPromoId,
      });

      print('Database response: $response');

      if (response != null && response.isNotEmpty) {
        final result = response[0];

        // Simpan ke local storage untuk compatibility
        await _saveBookingToLocal({
          'id': result['booking_id'],
          'title': namaProduk,
          'date': tanggal,
          'time': waktu,
          'payment': metodePembayaran,
          'original_price': 'Rp ${_formatCurrency(hargaAsli)}',
          'final_price':
              'Rp ${_formatCurrency(result['final_price'].toDouble())}',
          'price': 'Rp ${_formatCurrency(result['final_price'].toDouble())}',
          'discount_amount': result['discount_applied'] > 0
              ? 'Rp ${_formatCurrency(result['discount_applied'].toDouble())}'
              : null,
          'promo_used': result['promo_used'],
          'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
          'icon': _getIconForService(namaProduk),
          'status': 'confirmed',
        });

        // Jika menggunakan claimed promo, mark sebagai used
        if (claimedPromoId != null) {
          await _markClaimedPromoAsUsed(claimedPromoId);
        }

        return {
          'success': true,
          'booking_id': result['booking_id'],
          'final_price': result['final_price'],
          'discount_applied': result['discount_applied'],
          'promo_used': result['promo_used'],
        };
      }

      throw Exception('Gagal membuat booking - response kosong');
    } catch (e) {
      print('Error creating booking: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Mendapatkan riwayat booking user
  static Future<List<Map<String, dynamic>>> getUserBookingHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      print('Getting booking history for user: ${user.id}');

      final response = await _supabase.rpc('get_user_booking_history', params: {
        'p_user_id': user.id,
      });

      print('Booking history response: $response');

      List<Map<String, dynamic>> bookings = [];

      if (response != null) {
        for (var booking in response) {
          // Convert format tanggal dari yyyy-mm-dd ke dd/mm/yyyy
          String formattedDate =
              _formatDateForDisplay(booking['tanggal'].toString());

          bookings.add({
            'id': booking['id'],
            'title': booking['nama_produk'],
            'date': formattedDate,
            'time': booking['waktu'],
            'original_price':
                'Rp ${_formatCurrency(booking['harga_asli'].toDouble())}',
            'final_price':
                'Rp ${_formatCurrency(booking['harga_final'].toDouble())}',
            'price': 'Rp ${_formatCurrency(booking['harga_final'].toDouble())}',
            'promo_used': booking['promo_used'],
            'status': booking['status'] ?? 'confirmed',
            'booking_timestamp': booking['booking_timestamp'] ??
                DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(booking['nama_produk']),
            'discount_amount': booking['harga_asli'] > booking['harga_final']
                ? 'Rp ${_formatCurrency((booking['harga_asli'] - booking['harga_final']).toDouble())}'
                : null,
          });
        }
      }

      // Update local storage
      await _updateLocalStorage(bookings);

      return bookings;
    } catch (e) {
      print('Error getting booking history: $e');
      // Fallback ke local storage jika error
      return _getLocalBookings();
    }
  }

  // Mendapatkan promo yang tersedia
  static Future<List<Map<String, dynamic>>> getAvailablePromos() async {
    try {
      print('Getting available promos...');

      final response = await _supabase
          .from('promo')
          .select('*')
          .eq('aktif', true)
          .order('created_at', ascending: false);

      print('Available promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting promos: $e');
      return [];
    }
  }

  // Mendapatkan promo untuk produk tertentu
  static Future<List<Map<String, dynamic>>> getPromosForProduct(
      String productId) async {
    try {
      print('Getting promos for product: $productId');

      final response = await _supabase
          .from('promo')
          .select('*')
          .eq('aktif', true)
          .or('id_produk.eq.$productId,id_produk.is.null')
          .order('created_at', ascending: false);

      print('Product promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting product promos: $e');
      return [];
    }
  }

  // Mendapatkan claimed promos user
  static Future<List<Map<String, dynamic>>> getUserClaimedPromos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      print('Getting claimed promos for user: ${user.id}');

      final response = await _supabase
          .from('claimed_promos')
          .select('*')
          .eq('user_id', user.id)
          .order('claimed_at', ascending: false);

      print('Claimed promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting claimed promos: $e');
      return [];
    }
  }

  // Mendapatkan claimed promos yang bisa digunakan untuk produk
  static Future<List<Map<String, dynamic>>> getUsableClaimedPromos(
      String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      print('Getting usable claimed promos for product: $productId');

      // Get claimed promos dengan join ke tabel promo
      final response =
          await _supabase.rpc('get_usable_claimed_promos', params: {
        'p_user_id': user.id,
        'p_product_id': productId,
      });

      print('Usable claimed promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting usable claimed promos: $e');
      // Fallback method
      return await _getUsableClaimedPromosFallback(productId);
    }
  }

  static Future<List<Map<String, dynamic>>> _getUsableClaimedPromosFallback(
      String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get claimed promos
      final claimedPromos = await _supabase
          .from('claimed_promos')
          .select('*')
          .eq('user_id', user.id);

      List<Map<String, dynamic>> usablePromos = [];

      for (var claimed in claimedPromos) {
        // Check if promo is still active and applicable for product
        final promoResponse = await _supabase
            .from('promo')
            .select('*')
            .eq('nama_promo', claimed['promo_title'])
            .eq('aktif', true)
            .or('id_produk.eq.$productId,id_produk.is.null')
            .maybeSingle();

        if (promoResponse != null) {
          usablePromos.add({
            'claimed_promo_id': claimed['id'],
            'promo_title': claimed['promo_title'],
            'claimed_at': claimed['claimed_at'],
            'promo_details': promoResponse,
          });
        }
      }

      return usablePromos;
    } catch (e) {
      print('Error in fallback method: $e');
      return [];
    }
  }

  // Menggunakan promo (claim promo)
  static Future<Map<String, dynamic>> claimPromo(int promoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      print('Claiming promo: $promoId for user: ${user.id}');

      // Cek apakah promo masih aktif
      final promoResponse = await _supabase
          .from('promo')
          .select('*')
          .eq('id', promoId)
          .eq('aktif', true)
          .single();

      print('Promo details: $promoResponse');

      // Cek apakah user sudah claim promo ini
      final existingClaim = await _supabase
          .from('claimed_promos')
          .select('id')
          .eq('user_id', user.id)
          .eq('promo_title', promoResponse['nama_promo']);

      if (existingClaim.isNotEmpty) {
        throw Exception('Anda sudah mengklaim promo ini');
      }

      // Cek usage limit
      if (promoResponse['max_usage'] != null &&
          promoResponse['current_usage'] != null &&
          promoResponse['current_usage'] >= promoResponse['max_usage']) {
        throw Exception('Promo sudah mencapai batas penggunaan');
      }

      // Claim promo
      final claimResponse = await _supabase
          .from('claimed_promos')
          .insert({
            'user_id': user.id,
            'promo_title': promoResponse['nama_promo'],
          })
          .select()
          .single();

      print('Claim response: $claimResponse');

      return {
        'success': true,
        'claimed_promo': claimResponse,
        'message': 'Promo berhasil diklaim!'
      };
    } catch (e) {
      print('Error claiming promo: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update status booking
  static Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      print('Updating booking $bookingId status to $status');

      await _supabase.from('booking').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Hapus booking
  static Future<bool> deleteBooking(int bookingId) async {
    try {
      print('Deleting booking: $bookingId');

      await _supabase.from('booking').delete().eq('id', bookingId);

      // Update local storage
      List<Map<String, dynamic>> localBookings = _getLocalBookings();
      localBookings.removeWhere((booking) => booking['id'] == bookingId);
      await _updateLocalStorage(localBookings);

      return true;
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }

  // Validasi promo untuk produk dan harga
  static Future<Map<String, dynamic>?> validatePromoForBooking({
    required int promoId,
    required String productId,
    required double price,
  }) async {
    try {
      print(
          'Validating promo $promoId for product $productId with price $price');

      final response = await _supabase
          .from('promo')
          .select('*')
          .eq('id', promoId)
          .eq('aktif', true)
          .or('id_produk.eq.$productId,id_produk.is.null')
          .single();

      // Check minimum purchase amount
      if (response['min_purchase_amount'] != null &&
          price < response['min_purchase_amount']) {
        return {
          'valid': false,
          'error':
              'Minimum pembelian Rp ${_formatCurrency(response['min_purchase_amount'].toDouble())}'
        };
      }

      // Check usage limit
      if (response['max_usage'] != null &&
          response['current_usage'] != null &&
          response['current_usage'] >= response['max_usage']) {
        return {
          'valid': false,
          'error': 'Promo sudah mencapai batas penggunaan'
        };
      }

      // Check expiry date
      if (response['tanggal_berakhir'] != null) {
        DateTime expiryDate = DateTime.parse(response['tanggal_berakhir']);
        if (DateTime.now().isAfter(expiryDate)) {
          return {'valid': false, 'error': 'Promo sudah kedaluwarsa'};
        }
      }

      // Calculate discount
      double discount = 0;
      if (response['diskon_persen'] != null && response['diskon_persen'] > 0) {
        discount = price * response['diskon_persen'] / 100;
      } else if (response['harga_promo'] != null) {
        discount = response['harga_promo'].toDouble();
      }

      // Ensure discount doesn't exceed original price
      if (discount > price) {
        discount = price;
      }

      return {
        'valid': true,
        'promo': response,
        'discount': discount,
        'final_price': price - discount,
      };
    } catch (e) {
      print('Error validating promo: $e');
      return {'valid': false, 'error': 'Promo tidak valid atau tidak tersedia'};
    }
  }

  // Helper functions
  static Future<void> _saveBookingToLocal(Map<String, dynamic> booking) async {
    try {
      List<Map<String, dynamic>> existingBookings = _getLocalBookings();

      // Remove existing booking with same ID if exists
      existingBookings.removeWhere((b) => b['id'] == booking['id']);

      // Add new booking
      existingBookings.insert(0, booking);

      await _storage.write('bookings', existingBookings);
    } catch (e) {
      print('Error saving booking to local: $e');
    }
  }

  static List<Map<String, dynamic>> _getLocalBookings() {
    try {
      if (_storage.hasData('bookings')) {
        List<dynamic> savedBookings = _storage.read('bookings');
        return List<Map<String, dynamic>>.from(savedBookings);
      }
    } catch (e) {
      print('Error reading local bookings: $e');
    }
    return [];
  }

  static Future<void> _updateLocalStorage(
      List<Map<String, dynamic>> bookings) async {
    try {
      await _storage.write('bookings', bookings);
    } catch (e) {
      print('Error updating local storage: $e');
    }
  }

  static Future<void> _markClaimedPromoAsUsed(int claimedPromoId) async {
    try {
      print('Marking claimed promo $claimedPromoId as used');
      await _supabase.from('claimed_promos').delete().eq('id', claimedPromoId);
    } catch (e) {
      print('Error marking claimed promo as used: $e');
    }
  }

  static String _parseDate(String dateString) {
    try {
      // Handle dd/mm/yyyy format
      if (dateString.contains('/')) {
        List<String> dateParts = dateString.split('/');
        if (dateParts.length == 3) {
          return '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
        }
      }

      // Handle yyyy-mm-dd format (already correct)
      if (dateString.contains('-')) {
        return dateString;
      }

      // Default case
      return dateString;
    } catch (e) {
      print('Error parsing date: $e');
      return dateString;
    }
  }

  static String _formatDateForDisplay(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return dateString;
    }
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  static int _getIconForService(String serviceName) {
    String lowerName = serviceName.toLowerCase();
    if (lowerName.contains('potong') || lowerName.contains('rambut')) {
      return Icons.content_cut.codePoint;
    } else if (lowerName.contains('wajah') || lowerName.contains('face')) {
      return Icons.face.codePoint;
    } else if (lowerName.contains('rias') || lowerName.contains('makeup')) {
      return Icons.brush.codePoint;
    } else if (lowerName.contains('perawatan') || lowerName.contains('spa')) {
      return Icons.spa.codePoint;
    }
    return Icons.local_offer.codePoint;
  }

  // Cari promo berdasarkan kode
  static Future<Map<String, dynamic>?> findPromoByCode(String promoCode) async {
    try {
      print('Searching promo by code: $promoCode');

      final response = await _supabase
          .from('promo')
          .select('*')
          .ilike('nama_promo', '%$promoCode%')
          .eq('aktif', true)
          .maybeSingle();

      print('Found promo: $response');

      return response;
    } catch (e) {
      print('Error finding promo by code: $e');
      return null;
    }
  }

  // Clear all local data (untuk testing)
  static Future<void> clearLocalData() async {
    try {
      await _storage.erase();
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  // Sync data from server (refresh local cache)
  static Future<void> syncFromServer() async {
    try {
      print('Syncing data from server...');
      await getUserBookingHistory();
      print('Data sync completed');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }
}
