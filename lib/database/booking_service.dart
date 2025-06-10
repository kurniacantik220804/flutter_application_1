import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class BookingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _storage = GetStorage();

  // Test koneksi database
  static Future<bool> testDatabaseConnection() async {
    try {
      final response = await _supabase.from('bookings').select('id').limit(1);
      print('Database connection successful');
      return true;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }

  // Updated createBooking method dengan promo handling yang lebih baik
  static Future<Map<String, dynamic>?> createBooking({
    required String serviceId,
    required String serviceName,
    required String bookingDate,
    required String bookingTime,
    required double originalPrice,
    required String customerName,
    required String customerPhone,
    int? claimedPromoId,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      // Parse tanggal dari format dd/mm/yyyy ke yyyy-mm-dd
      String formattedDate = _parseDate(bookingDate);
      int originalPriceInt = originalPrice.toInt();

      print('Creating booking with params:');
      print('User ID: ${user.id}');
      print('Service ID: $serviceId');
      print('Service Name: $serviceName');
      print('Date: $formattedDate');
      print('Time: $bookingTime');
      print('Original Price: $originalPriceInt');
      print('Customer Name: $customerName');
      print('Customer Phone: $customerPhone');
      print('Claimed Promo ID: $claimedPromoId');

      // Panggil function untuk membuat booking dengan promo
      final response =
          await _supabase.rpc('create_booking_with_promo', params: {
        'p_user_id': user.id,
        'p_service_name': serviceName,
        'p_service_id': serviceId,
        'p_booking_date': formattedDate,
        'p_booking_time': bookingTime,
        'p_original_price': originalPriceInt,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_claimed_promo_id': claimedPromoId,
        'p_notes': notes,
      });

      print('Database response: $response');

      if (response != null && response.isNotEmpty) {
        final result = response[0];

        if (result['success'] == true) {
          // PENTING: Tandai promo sebagai used jika ada
          if (claimedPromoId != null) {
            await _markPromoAsUsed(claimedPromoId);
          }

          // Simpan ke local storage untuk compatibility
          await _saveBookingToLocal({
            'id': result['booking_id'],
            'booking_code': result['booking_code'],
            'title': serviceName,
            'date': bookingDate,
            'time': bookingTime,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'original_price': 'Rp ${_formatCurrency(originalPrice)}',
            'final_price':
                'Rp ${_formatCurrency(result['final_price'].toDouble())}',
            'price': 'Rp ${_formatCurrency(result['final_price'].toDouble())}',
            'discount_amount': result['discount_amount'] > 0
                ? 'Rp ${_formatCurrency(result['discount_amount'].toDouble())}'
                : null,
            'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(serviceName),
            'status': 'pending',
            'notes': notes,
          });

          return {
            'success': true,
            'booking_id': result['booking_id'],
            'booking_code': result['booking_code'],
            'final_price': result['final_price'],
            'discount_amount': result['discount_amount'],
            'message': result['message'],
          };
        } else {
          throw Exception(result['message'] ?? 'Gagal membuat booking');
        }
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

  // Method baru untuk menandai promo sebagai used
  static Future<void> _markPromoAsUsed(int claimedPromoId) async {
    try {
      print('Marking promo as used: $claimedPromoId');

      await _supabase.from('claimed_promos').update({
        'is_used': true,
        'used_at': DateTime.now().toIso8601String(),
      }).eq('id', claimedPromoId);

      print('Promo marked as used successfully');
    } catch (e) {
      print('Error marking promo as used: $e');
      // Tidak throw error karena booking sudah berhasil
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

      final response = await _supabase
          .from('booking_with_promo_details')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      print('Booking history response: $response');

      List<Map<String, dynamic>> bookings = [];

      if (response != null) {
        for (var booking in response) {
          // Convert format tanggal dari yyyy-mm-dd ke dd/mm/yyyy
          String formattedDate =
              _formatDateForDisplay(booking['booking_date'].toString());

          bookings.add({
            'id': booking['id'],
            'booking_code': booking['booking_code'],
            'title': booking['service_name'],
            'service_id': booking['service_id'],
            'date': formattedDate,
            'time': booking['booking_time']
                .toString()
                .substring(0, 5), // Remove seconds
            'original_price':
                'Rp ${_formatCurrency(booking['original_price'].toDouble())}',
            'final_price':
                'Rp ${_formatCurrency(booking['final_price'].toDouble())}',
            'price': 'Rp ${_formatCurrency(booking['final_price'].toDouble())}',
            'discount_amount': booking['discount_amount'] > 0
                ? 'Rp ${_formatCurrency(booking['discount_amount'].toDouble())}'
                : null,
            'promo_used': booking['claimed_promo_title'],
            'promo_discount_percent': booking['promo_discount_percent'],
            'customer_name': booking['customer_name'],
            'customer_phone': booking['customer_phone'],
            'status': booking['status'] ?? 'pending',
            'payment_status': booking['payment_status'] ?? 'unpaid',
            'booking_timestamp': booking['created_at'] != null
                ? DateTime.parse(booking['created_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(booking['service_name']),
            'notes': booking['notes'],
            'booking_type': booking['booking_type'],
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

  // Updated method getAvailablePromosForBooking dengan filter kategori
  static Future<List<Map<String, dynamic>>> getAvailablePromosForBooking({
    String? serviceCategory,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      print('Getting available promos for booking for user: ${user.id}');
      print('Service category: $serviceCategory');

      final response =
          await _supabase.rpc('get_available_promos_for_booking', params: {
        'p_user_id': user.id,
      });

      print('Available promos response: $response');

      List<Map<String, dynamic>> availablePromos =
          List<Map<String, dynamic>>.from(response ?? []);

      // Filter berdasarkan kategori jika ada
      if (serviceCategory != null && serviceCategory != 'general') {
        availablePromos = availablePromos.where((promo) {
          // Ambil kategori dari promo
          List<dynamic> promoCategories = [];

          // Cek struktur data promo
          if (promo['promo'] != null &&
              promo['promo']['kategori_layanan'] != null) {
            promoCategories = promo['promo']['kategori_layanan'];
          } else if (promo['kategori_layanan'] != null) {
            promoCategories = promo['kategori_layanan'];
          } else {
            promoCategories = ['general']; // Default
          }

          print(
              'Promo: ${promo['promo_title']} - Categories: $promoCategories');
          print('Service category: $serviceCategory');

          // Cek apakah promo berlaku untuk kategori ini
          bool isValid = promoCategories.contains('all') ||
              promoCategories.contains('general') ||
              promoCategories.contains(serviceCategory);

          print('Is valid: $isValid');
          return isValid;
        }).toList();
      }

      print('Filtered promos count: ${availablePromos.length}');
      return availablePromos;
    } catch (e) {
      print('Error getting available promos for booking: $e');
      return [];
    }
  }

  // Method untuk validasi promo dengan kategori
  static Future<bool> validatePromoForService(
      int claimedPromoId, String serviceCategory) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Ambil detail promo yang diklaim
      final claimedPromo = await _supabase
          .from('claimed_promos')
          .select('*, promo!inner(*)')
          .eq('id', claimedPromoId)
          .eq('user_id', user.id)
          .eq('is_used', false)
          .maybeSingle();

      if (claimedPromo == null) {
        print('Claimed promo not found or already used');
        return false;
      }

      // Cek kategori promo
      List<dynamic> promoCategories =
          claimedPromo['promo']['kategori_layanan'] ?? ['general'];

      bool isValid = promoCategories.contains('all') ||
          promoCategories.contains('general') ||
          promoCategories.contains(serviceCategory);

      print(
          'Promo validation - Categories: $promoCategories, Service: $serviceCategory, Valid: $isValid');

      return isValid;
    } catch (e) {
      print('Error validating promo: $e');
      return false;
    }
  }

  // Method untuk mendapatkan struktur kategori yang konsisten
  static Map<String, String> getServiceCategoryMap() {
    return {
      'hair_cut': 'Potong Rambut',
      'facial': 'Perawatan Wajah',
      'makeup': 'Makeup & Rias',
      'spa': 'Spa & Perawatan',
      'nail_care': 'Perawatan Kuku',
      'general': 'Umum',
      'all': 'Semua Kategori'
    };
  }

  // Method untuk mendapatkan kategori layanan berdasarkan nama service
  static String getServiceCategory(String serviceName) {
    String lowerName = serviceName.toLowerCase();

    if (lowerName.contains('potong') || lowerName.contains('rambut')) {
      return 'hair_cut';
    } else if (lowerName.contains('wajah') || lowerName.contains('facial')) {
      return 'facial';
    } else if (lowerName.contains('rias') || lowerName.contains('makeup')) {
      return 'makeup';
    } else if (lowerName.contains('spa') || lowerName.contains('perawatan')) {
      return 'spa';
    } else if (lowerName.contains('kuku') || lowerName.contains('nail')) {
      return 'nail_care';
    }

    return 'general';
  }

  // Mengklaim promo
  static Future<Map<String, dynamic>> claimPromo(String promoTitle) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      print('Claiming promo: $promoTitle for user: ${user.id}');

      // Cek apakah promo masih aktif
      final promoResponse = await _supabase
          .from('promo')
          .select('*')
          .eq('nama_promo', promoTitle)
          .eq('status', 'aktif')
          .maybeSingle();

      if (promoResponse == null) {
        throw Exception('Promo tidak ditemukan atau tidak aktif');
      }

      // Cek apakah user sudah claim promo ini
      final existingClaim = await _supabase
          .from('claimed_promos')
          .select('id')
          .eq('user_id', user.id)
          .eq('promo_title', promoTitle);

      if (existingClaim.isNotEmpty) {
        throw Exception('Anda sudah mengklaim promo ini');
      }

      // Cek apakah promo sudah expired
      if (promoResponse['tanggal_berakhir'] != null) {
        DateTime expiryDate = DateTime.parse(promoResponse['tanggal_berakhir']);
        if (DateTime.now().isAfter(expiryDate)) {
          throw Exception('Promo sudah kedaluwarsa');
        }
      }

      // Claim promo
      final claimResponse = await _supabase
          .from('claimed_promos')
          .insert({
            'user_id': user.id,
            'promo_title': promoTitle,
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

  // Mendapatkan claimed promos user yang belum digunakan
  static Future<List<Map<String, dynamic>>> getUserClaimedPromos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      print('Getting claimed promos for user: ${user.id}');

      final response = await _supabase
          .from('claimed_promos')
          .select('*, promo!inner(*)')
          .eq('user_id', user.id)
          .eq('is_used', false)
          .order('claimed_at', ascending: false);

      print('Claimed promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting claimed promos: $e');
      return [];
    }
  }

  // Update status booking
  static Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      print('Updating booking $bookingId status to $status');

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add specific timestamps based on status
      if (status == 'confirmed') {
        updateData['confirmed_at'] = DateTime.now().toIso8601String();
      } else if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('bookings').update(updateData).eq('id', bookingId);

      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Update payment status
  static Future<bool> updatePaymentStatus(
      int bookingId, String paymentStatus) async {
    try {
      print('Updating booking $bookingId payment status to $paymentStatus');

      await _supabase.from('bookings').update({
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Hapus booking
  static Future<bool> deleteBooking(int bookingId) async {
    try {
      print('Deleting booking: $bookingId');

      await _supabase.from('bookings').delete().eq('id', bookingId);

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

  // Get booking by ID
  static Future<Map<String, dynamic>?> getBookingById(int bookingId) async {
    try {
      print('Getting booking by ID: $bookingId');

      final response = await _supabase
          .from('booking_with_promo_details')
          .select('*')
          .eq('id', bookingId)
          .maybeSingle();

      if (response != null) {
        String formattedDate =
            _formatDateForDisplay(response['booking_date'].toString());

        return {
          'id': response['id'],
          'booking_code': response['booking_code'],
          'title': response['service_name'],
          'service_id': response['service_id'],
          'date': formattedDate,
          'time': response['booking_time'].toString().substring(0, 5),
          'original_price':
              'Rp ${_formatCurrency(response['original_price'].toDouble())}',
          'final_price':
              'Rp ${_formatCurrency(response['final_price'].toDouble())}',
          'discount_amount': response['discount_amount'] > 0
              ? 'Rp ${_formatCurrency(response['discount_amount'].toDouble())}'
              : null,
          'promo_used': response['claimed_promo_title'],
          'customer_name': response['customer_name'],
          'customer_phone': response['customer_phone'],
          'status': response['status'],
          'payment_status': response['payment_status'],
          'notes': response['notes'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }

  // Get promo usage statistics
  static Future<Map<String, dynamic>> getPromoStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final response = await _supabase
          .from('promo_usage_log')
          .select('*')
          .eq('user_id', user.id);

      int totalPromoUsed = response?.length ?? 0;
      double totalSavings = 0;

      if (response != null) {
        for (var usage in response) {
          totalSavings += (usage['discount_amount'] ?? 0).toDouble();
        }
      }

      return {
        'total_promo_used': totalPromoUsed,
        'total_savings': totalSavings,
        'formatted_savings': 'Rp ${_formatCurrency(totalSavings)}',
      };
    } catch (e) {
      print('Error getting promo stats: $e');
      return {};
    }
  }

  // Method untuk mendapatkan promo berdasarkan ID claimed promo
  static Future<Map<String, dynamic>?> getClaimedPromoDetails(
      int claimedPromoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('claimed_promos')
          .select('*, promo!inner(*)')
          .eq('id', claimedPromoId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting claimed promo details: $e');
      return null;
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

  // Cari promo berdasarkan nama
  static Future<Map<String, dynamic>?> findPromoByName(String promoName) async {
    try {
      print('Searching promo by name: $promoName');

      final response = await _supabase
          .from('promo')
          .select('*')
          .ilike('nama_promo', '%$promoName%')
          .eq('status', 'aktif')
          .maybeSingle();

      print('Found promo: $response');

      return response;
    } catch (e) {
      print('Error finding promo by name: $e');
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

  // Validate booking data before submission
  static Map<String, dynamic> validateBookingData({
    required String serviceId,
    required String serviceName,
    required String bookingDate,
    required String bookingTime,
    required double originalPrice,
    required String customerName,
    required String customerPhone,
  }) {
    List<String> errors = [];

    if (serviceId.isEmpty) errors.add('Service ID tidak boleh kosong');
    if (serviceName.isEmpty) errors.add('Nama layanan tidak boleh kosong');
    if (bookingDate.isEmpty) errors.add('Tanggal booking tidak boleh kosong');
    if (bookingTime.isEmpty) errors.add('Waktu booking tidak boleh kosong');
    if (originalPrice <= 0) errors.add('Harga harus lebih dari 0');
    if (customerName.isEmpty) errors.add('Nama pelanggan tidak boleh kosong');
    if (customerPhone.isEmpty) errors.add('Nomor telepon tidak boleh kosong');

    // Validate phone number format
    if (customerPhone.isNotEmpty &&
        !RegExp(r'^[0-9+\-\s()]+$').hasMatch(customerPhone)) {
      errors.add('Format nomor telepon tidak valid');
    }

    // Validate date format
    try {
      _parseDate(bookingDate);
    } catch (e) {
      errors.add('Format tanggal tidak valid');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
