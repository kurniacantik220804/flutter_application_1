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
      print('Database connection successful: $response');
      return true;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }

  // Membuat booking baru - Simplified version
  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String serviceName,
    required String bookingDate,
    required String bookingTime,
    required double originalPrice,
    required String customerName,
    required String customerPhone,
    int? promoId,
    String? promoTitle,
    int? promoDiscountPercent,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      print('Creating booking with data:');
      print('User ID: ${user.id}');
      print('Service ID: $serviceId');
      print('Service Name: $serviceName');
      print('Date: $bookingDate');
      print('Time: $bookingTime');
      print('Original Price: $originalPrice');
      print('Customer Name: $customerName');
      print('Customer Phone: $customerPhone');
      print('Promo ID: $promoId');

      // Parse tanggal dari format dd/mm/yyyy ke yyyy-mm-dd
      String formattedDate = _parseDate(bookingDate);

      // Calculate discount and final price
      double discountAmount = 0;
      double finalPrice = originalPrice;

      if (promoId != null && promoDiscountPercent != null) {
        discountAmount = originalPrice * (promoDiscountPercent / 100.0);
        finalPrice = originalPrice - discountAmount;
      }

      // Generate booking code
      String bookingCode =
          'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Prepare booking data
      final bookingData = {
        'user_id': user.id,
        'booking_code': bookingCode,
        'service_name': serviceName,
        'service_id': serviceId,
        'booking_date': formattedDate,
        'booking_time': bookingTime,
        'original_price': originalPrice.toInt(),
        'discount_amount': discountAmount.toInt(),
        'final_price': finalPrice.toInt(),
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'status': 'pending',
        'payment_status': 'unpaid',
        'notes': notes,
        'promo_id': promoId,
        'promo_title': promoTitle,
        'promo_diskon_persen': promoDiscountPercent,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Booking data to insert: $bookingData');

      // Insert booking to database
      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      print('Booking inserted successfully: $response');

      // Mark promo as used if applicable
      if (promoId != null) {
        await _markPromoAsUsed(user.id, promoId);
      }

      // Save to local storage for offline access
      await _saveBookingToLocal({
        'id': response['id'],
        'booking_code': bookingCode,
        'title': serviceName,
        'date': bookingDate,
        'time': bookingTime,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'original_price': 'Rp ${_formatCurrency(originalPrice)}',
        'final_price': 'Rp ${_formatCurrency(finalPrice)}',
        'price': 'Rp ${_formatCurrency(finalPrice)}',
        'discount_amount':
            discountAmount > 0 ? 'Rp ${_formatCurrency(discountAmount)}' : null,
        'promo_title': promoTitle,
        'promo_discount': promoDiscountPercent,
        'booking_timestamp': DateTime.now().millisecondsSinceEpoch,
        'icon': _getIconForService(serviceName),
        'status': 'pending',
        'payment_status': 'unpaid',
        'notes': notes,
      });

      return {
        'success': true,
        'booking_id': response['id'],
        'booking_code': bookingCode,
        'final_price': finalPrice,
        'discount_amount': discountAmount,
        'message': 'Booking berhasil dibuat',
      };
    } catch (e) {
      print('Error creating booking: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal membuat booking: ${e.toString()}',
      };
    }
  }

  // Mark promo as used
  static Future<void> _markPromoAsUsed(String userId, int promoId) async {
    try {
      // Update claimed_promos table
      await _supabase
          .from('claimed_promos')
          .update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('id', promoId);

      print('Promo marked as used: $promoId');
    } catch (e) {
      print('Error marking promo as used: $e');
    }
  }

  // Mendapatkan riwayat booking user
  static Future<List<Map<String, dynamic>>> getUserBookingHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('User not logged in, returning local bookings');
        return _getLocalBookings();
      }

      print('Getting booking history for user: ${user.id}');

      final response = await _supabase
          .from('bookings')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      print('Booking history response: $response');

      List<Map<String, dynamic>> bookings = [];

      if (response != null && response.isNotEmpty) {
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
            'time': booking['booking_time'].toString(),
            'original_price':
                'Rp ${_formatCurrency(booking['original_price'].toDouble())}',
            'final_price':
                'Rp ${_formatCurrency(booking['final_price'].toDouble())}',
            'price': 'Rp ${_formatCurrency(booking['final_price'].toDouble())}',
            'discount_amount': booking['discount_amount'] != null &&
                    booking['discount_amount'] > 0
                ? 'Rp ${_formatCurrency(booking['discount_amount'].toDouble())}'
                : null,
            'promo_title': booking['promo_title'],
            'promo_discount': booking['promo_diskon_persen'],
            'customer_name': booking['customer_name'],
            'customer_phone': booking['customer_phone'],
            'status': booking['status'] ?? 'pending',
            'payment_status': booking['payment_status'] ?? 'unpaid',
            'booking_timestamp': booking['created_at'] != null
                ? DateTime.parse(booking['created_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(booking['service_name']),
            'notes': booking['notes'],
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

  // Mendapatkan promo yang tersedia untuk user (dari claimed_promos)
  static Future<List<Map<String, dynamic>>>
      getAvailablePromosForBooking() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('User not logged in');
        return [];
      }

      print('Getting available promos for booking for user: ${user.id}');

      // Get unused claimed promos
      final response = await _supabase
          .from('claimed_promos')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_used', false)
          .eq('status', 'active')
          .order('claimed_at', ascending: false);

      print('Available promos for booking: $response');

      if (response != null && response.isNotEmpty) {
        List<Map<String, dynamic>> promos = [];

        for (var claimed in response) {
          // Get promo details
          final promoResponse = await _supabase
              .from('promo')
              .select('*')
              .eq('nama_promo', claimed['promo_title'])
              .eq('status', 'aktif')
              .maybeSingle();

          if (promoResponse != null) {
            promos.add({
              'id': claimed['id'],
              'promo_title': claimed['promo_title'],
              'promo': promoResponse,
              'discount_percent': promoResponse['diskon_persen'],
              'claimed_at': claimed['claimed_at'],
              'expires_at': claimed['expires_at'],
            });
          }
        }

        return promos;
      }

      return [];
    } catch (e) {
      print('Error getting available promos for booking: $e');
      return [];
    }
  }

  // Mendapatkan semua promo yang aktif
  static Future<List<Map<String, dynamic>>> getAvailablePromos() async {
    try {
      print('Getting all available promos...');

      final response = await _supabase
          .from('promo')
          .select('*')
          .eq('status', 'aktif')
          .order('created_at', ascending: false);

      print('Available promos: $response');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting promos: $e');
      return [];
    }
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

      // Calculate expiry date (30 days from claim)
      DateTime expiryDate = DateTime.now().add(const Duration(days: 30));

      // Claim promo
      final claimResponse = await _supabase
          .from('claimed_promos')
          .insert({
            'user_id': user.id,
            'promo_title': promoTitle,
            'status': 'active',
            'is_used': false,
            'claimed_at': DateTime.now().toIso8601String(),
            'expires_at': expiryDate.toIso8601String(),
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
          .select('*')
          .eq('user_id', user.id)
          .eq('is_used', false)
          .eq('status', 'active')
          .order('claimed_at', ascending: false);

      print('Claimed promos: $response');

      if (response != null && response.isNotEmpty) {
        List<Map<String, dynamic>> promos = [];

        for (var claimed in response) {
          // Get promo details
          final promoResponse = await _supabase
              .from('promo')
              .select('*')
              .eq('nama_promo', claimed['promo_title'])
              .eq('status', 'aktif')
              .maybeSingle();

          if (promoResponse != null) {
            promos.add({
              'id': claimed['id'],
              'promo_title': claimed['promo_title'],
              'promo': promoResponse,
              'claimed_at': claimed['claimed_at'],
              'expires_at': claimed['expires_at'],
              'status': claimed['status'],
            });
          }
        }

        return promos;
      }

      return [];
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
          .from('bookings')
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
          'time': response['booking_time'].toString(),
          'original_price':
              'Rp ${_formatCurrency(response['original_price'].toDouble())}',
          'final_price':
              'Rp ${_formatCurrency(response['final_price'].toDouble())}',
          'discount_amount': response['discount_amount'] != null &&
                  response['discount_amount'] > 0
              ? 'Rp ${_formatCurrency(response['discount_amount'].toDouble())}'
              : null,
          'promo_title': response['promo_title'],
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

  // Helper functions
  static Future<void> _saveBookingToLocal(Map<String, dynamic> booking) async {
    try {
      List<Map<String, dynamic>> existingBookings = _getLocalBookings();

      // Remove existing booking with same ID if exists
      if (booking['id'] != null) {
        existingBookings.removeWhere((b) => b['id'] == booking['id']);
      }

      // Add new booking
      existingBookings.insert(0, booking);

      await _storage.write('bookings', existingBookings);
      print('Booking saved to local storage');
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
      print('Local storage updated with ${bookings.length} bookings');
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
