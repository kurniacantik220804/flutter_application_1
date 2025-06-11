import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class AdminBookingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _storage = GetStorage();

  // Test koneksi database untuk admin
  static Future<bool> testAdminConnection() async {
    try {
      final response = await _supabase.from('bookings').select('id').limit(1);
      print('Admin database connection successful: $response');
      return true;
    } catch (e) {
      print('Admin database connection error: $e');
      return false;
    }
  }

  // Mendapatkan semua booking untuk admin (tanpa filter user)
  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      print('Getting all bookings for admin...');

      // Tambahkan debug untuk melihat user yang sedang login
      final currentUser = _supabase.auth.currentUser;
      print('Current user: ${currentUser?.id}');

      // Coba query sederhana dulu
      final response = await _supabase
          .from('bookings')
          .select('*')
          .order('created_at', ascending: false);

      print('Raw response type: ${response.runtimeType}');
      print('All bookings response: $response');
      print('Response length: ${response?.length ?? 0}');

      // Jika response null atau kosong, coba troubleshooting
      if (response == null || response.isEmpty) {
        print('No bookings found. Checking table structure...');

        // Test query sederhana untuk debug
        final testResponse = await _supabase.from('bookings').select('count');
        print('Count query result: $testResponse');

        return [];
      }

      List<Map<String, dynamic>> bookings = [];

      for (var booking in response) {
        try {
          print('Processing booking: ${booking['id']}');

          // Safely handle null values
          final bookingDate = booking['booking_date'];
          String formattedDate = bookingDate != null
              ? _formatDateForDisplay(bookingDate.toString())
              : 'N/A';

          final originalPrice = booking['original_price'];
          final finalPrice = booking['final_price'];
          final discountAmount = booking['discount_amount'];

          bookings.add({
            'id': booking['id'],
            'user_id': booking['user_id'],
            'booking_code': booking['booking_code'] ?? 'N/A',
            'title': booking['service_name'] ?? 'N/A',
            'service_id': booking['service_id'] ?? 'N/A',
            'date': formattedDate,
            'time': booking['booking_time'] != null
                ? booking['booking_time'].toString()
                : 'N/A',
            'original_price': originalPrice != null
                ? 'Rp ${_formatCurrency(originalPrice.toDouble())}'
                : 'Rp 0',
            'final_price': finalPrice != null
                ? 'Rp ${_formatCurrency(finalPrice.toDouble())}'
                : 'Rp 0',
            'price': finalPrice != null
                ? 'Rp ${_formatCurrency(finalPrice.toDouble())}'
                : 'Rp 0',
            'discount_amount': discountAmount != null && discountAmount > 0
                ? 'Rp ${_formatCurrency(discountAmount.toDouble())}'
                : null,
            'promo_title': booking['promo_title'],
            'promo_discount': booking['promo_diskon_persen'],
            'customer_name': booking['customer_name'] ?? 'N/A',
            'customer_phone': booking['customer_phone'] ?? 'N/A',
            'status': booking['status'] ?? 'pending',
            'payment_status': booking['payment_status'] ?? 'unpaid',
            'booking_timestamp': booking['created_at'] != null
                ? DateTime.parse(booking['created_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(booking['service_name'] ?? ''),
            'notes': booking['notes'],
            'created_at': booking['created_at'],
            'updated_at': booking['updated_at'],
            'confirmed_at': booking['confirmed_at'],
            'completed_at': booking['completed_at'],
          });
        } catch (e) {
          print('Error processing booking ${booking['id']}: $e');
          // Continue with next booking instead of failing completely
          continue;
        }
      }

      print('Processed ${bookings.length} bookings successfully');
      return bookings;
    } catch (e) {
      print('Error getting all bookings: $e');
      print('Error details: ${e.toString()}');

      // Return empty list instead of throwing
      return [];
    }
  }

  // Debug method to check if bookings table exists and has data
  static Future<Map<String, dynamic>> debugBookingsTable() async {
    try {
      print('=== DEBUGGING BOOKINGS TABLE ===');

      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      print('Current user: ${user?.id}');
      print('User authenticated: ${user != null}');

      // Try to get table schema info
      try {
        final schemaResponse =
            await _supabase.from('bookings').select('id').limit(1);
        print('Schema test successful: $schemaResponse');
      } catch (e) {
        print('Schema test failed: $e');
      }

      // Try to count rows
      try {
        final countResponse =
            await _supabase.from('bookings').select('id').count();
        print('Count response: $countResponse');
      } catch (e) {
        print('Count failed: $e');
      }

      // Try without RLS (if user has admin privileges)
      try {
        final adminResponse =
            await _supabase.rpc('get_all_bookings_admin'); // Custom function
        print('Admin RPC response: $adminResponse');
      } catch (e) {
        print(
            'Admin RPC failed (this is expected if function doesn\'t exist): $e');
      }

      return {
        'user_authenticated': user != null,
        'user_id': user?.id,
        'debug_completed': true,
      };
    } catch (e) {
      print('Debug error: $e');
      return {
        'error': e.toString(),
        'debug_completed': false,
      };
    }
  }

  // Filter booking berdasarkan status
  static Future<List<Map<String, dynamic>>> getBookingsByStatus(
      String status) async {
    try {
      print('Getting bookings by status: $status');

      final response = await _supabase
          .from('bookings')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      print('Bookings by status response: $response');

      if (response == null || response.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> bookings = [];

      for (var booking in response) {
        try {
          String formattedDate = booking['booking_date'] != null
              ? _formatDateForDisplay(booking['booking_date'].toString())
              : 'N/A';

          bookings.add({
            'id': booking['id'],
            'user_id': booking['user_id'],
            'booking_code': booking['booking_code'] ?? 'N/A',
            'title': booking['service_name'] ?? 'N/A',
            'service_id': booking['service_id'] ?? 'N/A',
            'date': formattedDate,
            'time': booking['booking_time']?.toString() ?? 'N/A',
            'original_price': booking['original_price'] != null
                ? 'Rp ${_formatCurrency(booking['original_price'].toDouble())}'
                : 'Rp 0',
            'final_price': booking['final_price'] != null
                ? 'Rp ${_formatCurrency(booking['final_price'].toDouble())}'
                : 'Rp 0',
            'price': booking['final_price'] != null
                ? 'Rp ${_formatCurrency(booking['final_price'].toDouble())}'
                : 'Rp 0',
            'discount_amount': booking['discount_amount'] != null &&
                    booking['discount_amount'] > 0
                ? 'Rp ${_formatCurrency(booking['discount_amount'].toDouble())}'
                : null,
            'promo_title': booking['promo_title'],
            'promo_discount': booking['promo_diskon_persen'],
            'customer_name': booking['customer_name'] ?? 'N/A',
            'customer_phone': booking['customer_phone'] ?? 'N/A',
            'status': booking['status'] ?? 'pending',
            'payment_status': booking['payment_status'] ?? 'unpaid',
            'booking_timestamp': booking['created_at'] != null
                ? DateTime.parse(booking['created_at']).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
            'icon': _getIconForService(booking['service_name'] ?? ''),
            'notes': booking['notes'],
            'created_at': booking['created_at'],
            'updated_at': booking['updated_at'],
            'confirmed_at': booking['confirmed_at'],
            'completed_at': booking['completed_at'],
          });
        } catch (e) {
          print('Error processing booking in status filter: $e');
          continue;
        }
      }

      return bookings;
    } catch (e) {
      print('Error getting bookings by status: $e');
      return [];
    }
  }

  // Update status booking (Admin)
  static Future<Map<String, dynamic>> updateBookingStatus(
      int bookingId, String status) async {
    try {
      print('Admin updating booking $bookingId status to $status');

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

      final response = await _supabase
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select()
          .single();

      print('Booking status updated: $response');

      return {
        'success': true,
        'message': 'Status booking berhasil diupdate',
        'booking': response,
      };
    } catch (e) {
      print('Error updating booking status: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal mengupdate status booking: ${e.toString()}',
      };
    }
  }

  // Update payment status (Admin)
  static Future<Map<String, dynamic>> updatePaymentStatus(
      int bookingId, String paymentStatus) async {
    try {
      print(
          'Admin updating booking $bookingId payment status to $paymentStatus');

      final response = await _supabase
          .from('bookings')
          .update({
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select()
          .single();

      print('Payment status updated: $response');

      return {
        'success': true,
        'message': 'Status pembayaran berhasil diupdate',
        'booking': response,
      };
    } catch (e) {
      print('Error updating payment status: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal mengupdate status pembayaran: ${e.toString()}',
      };
    }
  }

  // Update booking details (Admin)
  static Future<Map<String, dynamic>> updateBookingDetails({
    required int bookingId,
    String? serviceName,
    String? serviceId,
    String? bookingDate,
    String? bookingTime,
    double? originalPrice,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? status,
    String? paymentStatus,
  }) async {
    try {
      print('Admin updating booking $bookingId details');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add fields to update if provided
      if (serviceName != null) updateData['service_name'] = serviceName;
      if (serviceId != null) updateData['service_id'] = serviceId;
      if (bookingDate != null) {
        updateData['booking_date'] = _parseDate(bookingDate);
      }
      if (bookingTime != null) updateData['booking_time'] = bookingTime;
      if (originalPrice != null) {
        updateData['original_price'] = originalPrice.toInt();
        // Recalculate final price if no discount
        if (updateData['discount_amount'] == null ||
            updateData['discount_amount'] == 0) {
          updateData['final_price'] = originalPrice.toInt();
        }
      }
      if (customerName != null) updateData['customer_name'] = customerName;
      if (customerPhone != null) updateData['customer_phone'] = customerPhone;
      if (notes != null) updateData['notes'] = notes;
      if (status != null) {
        updateData['status'] = status;
        if (status == 'confirmed') {
          updateData['confirmed_at'] = DateTime.now().toIso8601String();
        } else if (status == 'completed') {
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }
      if (paymentStatus != null) updateData['payment_status'] = paymentStatus;

      print('Update data: $updateData');

      final response = await _supabase
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select()
          .single();

      print('Booking details updated: $response');

      return {
        'success': true,
        'message': 'Detail booking berhasil diupdate',
        'booking': response,
      };
    } catch (e) {
      print('Error updating booking details: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal mengupdate detail booking: ${e.toString()}',
      };
    }
  }

  // Hapus booking (Admin)
  static Future<Map<String, dynamic>> deleteBooking(int bookingId) async {
    try {
      print('Admin deleting booking: $bookingId');

      // Get booking details before deletion for logging
      final bookingResponse = await _supabase
          .from('bookings')
          .select('*')
          .eq('id', bookingId)
          .maybeSingle();

      if (bookingResponse == null) {
        return {
          'success': false,
          'message': 'Booking tidak ditemukan',
        };
      }

      // Delete booking
      await _supabase.from('bookings').delete().eq('id', bookingId);

      print('Booking deleted successfully: $bookingId');

      return {
        'success': true,
        'message': 'Booking berhasil dihapus',
        'deleted_booking': bookingResponse,
      };
    } catch (e) {
      print('Error deleting booking: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal menghapus booking: ${e.toString()}',
      };
    }
  }

  // Get booking statistics untuk dashboard admin
  static Future<Map<String, dynamic>> getBookingStatistics() async {
    try {
      print('Getting booking statistics...');

      // Get all bookings
      final allBookings = await _supabase
          .from('bookings')
          .select('status, payment_status, final_price, created_at');

      Map<String, int> statusCount = {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      Map<String, int> paymentCount = {
        'unpaid': 0,
        'paid': 0,
        'refunded': 0,
      };

      double totalRevenue = 0;
      int totalBookings = 0;

      if (allBookings != null && allBookings.isNotEmpty) {
        totalBookings = allBookings.length;

        for (var booking in allBookings) {
          // Count status
          String status = booking['status'] ?? 'pending';
          if (statusCount.containsKey(status)) {
            statusCount[status] = statusCount[status]! + 1;
          }

          // Count payment status
          String paymentStatus = booking['payment_status'] ?? 'unpaid';
          if (paymentCount.containsKey(paymentStatus)) {
            paymentCount[paymentStatus] = paymentCount[paymentStatus]! + 1;
          }

          // Calculate revenue (only from paid bookings)
          if (paymentStatus == 'paid') {
            totalRevenue += (booking['final_price'] ?? 0).toDouble();
          }
        }
      }

      return {
        'success': true,
        'statistics': {
          'total_bookings': totalBookings,
          'status_count': statusCount,
          'payment_count': paymentCount,
          'total_revenue': totalRevenue,
          'formatted_revenue': 'Rp ${_formatCurrency(totalRevenue)}',
        },
      };
    } catch (e) {
      print('Error getting booking statistics: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal mendapatkan statistik booking',
      };
    }
  }

  // Search bookings by various criteria
  static Future<List<Map<String, dynamic>>> searchBookings({
    String? query,
    String? status,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print(
          'Searching bookings with query: $query, status: $status, payment: $paymentStatus');

      var queryBuilder = _supabase.from('bookings').select('*');

      // Add filters
      if (status != null && status.isNotEmpty) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        queryBuilder = queryBuilder.eq('payment_status', paymentStatus);
      }

      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryBuilder = queryBuilder.gte('booking_date', _parseDate(dateFrom));
      }

      if (dateTo != null && dateTo.isNotEmpty) {
        queryBuilder = queryBuilder.lte('booking_date', _parseDate(dateTo));
      }

      // Text search in multiple fields
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
            'booking_code.ilike.%$query%,customer_name.ilike.%$query%,customer_phone.ilike.%$query%,service_name.ilike.%$query%');
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      print('Search results: ${response?.length ?? 0} bookings found');

      List<Map<String, dynamic>> bookings = [];

      if (response != null && response.isNotEmpty) {
        for (var booking in response) {
          try {
            String formattedDate = booking['booking_date'] != null
                ? _formatDateForDisplay(booking['booking_date'].toString())
                : 'N/A';

            bookings.add({
              'id': booking['id'],
              'user_id': booking['user_id'],
              'booking_code': booking['booking_code'] ?? 'N/A',
              'title': booking['service_name'] ?? 'N/A',
              'service_id': booking['service_id'] ?? 'N/A',
              'date': formattedDate,
              'time': booking['booking_time']?.toString() ?? 'N/A',
              'original_price': booking['original_price'] != null
                  ? 'Rp ${_formatCurrency(booking['original_price'].toDouble())}'
                  : 'Rp 0',
              'final_price': booking['final_price'] != null
                  ? 'Rp ${_formatCurrency(booking['final_price'].toDouble())}'
                  : 'Rp 0',
              'price': booking['final_price'] != null
                  ? 'Rp ${_formatCurrency(booking['final_price'].toDouble())}'
                  : 'Rp 0',
              'discount_amount': booking['discount_amount'] != null &&
                      booking['discount_amount'] > 0
                  ? 'Rp ${_formatCurrency(booking['discount_amount'].toDouble())}'
                  : null,
              'promo_title': booking['promo_title'],
              'promo_discount': booking['promo_diskon_persen'],
              'customer_name': booking['customer_name'] ?? 'N/A',
              'customer_phone': booking['customer_phone'] ?? 'N/A',
              'status': booking['status'] ?? 'pending',
              'payment_status': booking['payment_status'] ?? 'unpaid',
              'booking_timestamp': booking['created_at'] != null
                  ? DateTime.parse(booking['created_at']).millisecondsSinceEpoch
                  : DateTime.now().millisecondsSinceEpoch,
              'icon': _getIconForService(booking['service_name'] ?? ''),
              'notes': booking['notes'],
              'created_at': booking['created_at'],
              'updated_at': booking['updated_at'],
              'confirmed_at': booking['confirmed_at'],
              'completed_at': booking['completed_at'],
            });
          } catch (e) {
            print('Error processing search result: $e');
            continue;
          }
        }
      }

      return bookings;
    } catch (e) {
      print('Error searching bookings: $e');
      return [];
    }
  }

  // Get booking by ID (Admin)
  static Future<Map<String, dynamic>?> getBookingById(int bookingId) async {
    try {
      print('Admin getting booking by ID: $bookingId');

      final response = await _supabase
          .from('bookings')
          .select('*')
          .eq('id', bookingId)
          .maybeSingle();

      if (response != null) {
        String formattedDate = response['booking_date'] != null
            ? _formatDateForDisplay(response['booking_date'].toString())
            : 'N/A';

        return {
          'id': response['id'],
          'user_id': response['user_id'],
          'booking_code': response['booking_code'] ?? 'N/A',
          'title': response['service_name'] ?? 'N/A',
          'service_id': response['service_id'] ?? 'N/A',
          'date': formattedDate,
          'time': response['booking_time']?.toString() ?? 'N/A',
          'original_price': response['original_price'] != null
              ? 'Rp ${_formatCurrency(response['original_price'].toDouble())}'
              : 'Rp 0',
          'final_price': response['final_price'] != null
              ? 'Rp ${_formatCurrency(response['final_price'].toDouble())}'
              : 'Rp 0',
          'discount_amount': response['discount_amount'] != null &&
                  response['discount_amount'] > 0
              ? 'Rp ${_formatCurrency(response['discount_amount'].toDouble())}'
              : null,
          'promo_title': response['promo_title'],
          'promo_discount': response['promo_diskon_persen'],
          'customer_name': response['customer_name'] ?? 'N/A',
          'customer_phone': response['customer_phone'] ?? 'N/A',
          'status': response['status'] ?? 'pending',
          'payment_status': response['payment_status'] ?? 'unpaid',
          'notes': response['notes'],
          'created_at': response['created_at'],
          'updated_at': response['updated_at'],
          'confirmed_at': response['confirmed_at'],
          'completed_at': response['completed_at'],
          // Raw data untuk editing
          'raw_booking_date': response['booking_date'],
          'raw_original_price': response['original_price'],
          'raw_final_price': response['final_price'],
          'raw_discount_amount': response['discount_amount'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }

  // Helper functions
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

  // Validate status values
  static bool isValidStatus(String status) {
    return ['pending', 'confirmed', 'completed', 'cancelled'].contains(status);
  }

  static bool isValidPaymentStatus(String paymentStatus) {
    return ['unpaid', 'paid', 'refunded'].contains(paymentStatus);
  }

  // Get status options
  static List<String> getStatusOptions() {
    return ['pending', 'confirmed', 'completed', 'cancelled'];
  }

  static List<String> getPaymentStatusOptions() {
    return ['unpaid', 'paid', 'refunded'];
  }
}
