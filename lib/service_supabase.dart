import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxController {
  static SupabaseService get to => Get.find();
  
  final SupabaseClient _client = Supabase.instance.client;
  
  // Getters untuk akses mudah
  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  void onInit() {
    super.onInit();
    print('SupabaseService initialized');
  }

  // Sign Up dengan profile creation
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      // Step 1: Sign up user
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      // Step 2: Create profile if user creation successful
      if (response.user != null) {
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'username': fullName,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('Profile created successfully for user: ${response.user!.id}');
        } catch (profileError) {
          print('Error creating profile: $profileError');
          // Don't throw error here, user is already created in auth
        }
      }

      return response;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful for: $email');
      return response;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      print('Reset password email sent to: $email');
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile({
    String? username,
    String? avatarUrl,
    String? website,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (website != null) updates['website'] = website;

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      print('Profile updated successfully');
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Create Profile (untuk handle kasus dimana profile belum ada)
  Future<void> createProfile({
    required String userId,
    required String username,
    String? avatarUrl,
    String? website,
  }) async {
    try {
      await _client.from('profiles').insert({
        'id': userId,
        'username': username,
        'avatar_url': avatarUrl,
        'website': website,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('Profile created successfully for user: $userId');
    } catch (e) {
      print('Create profile error: $e');
      rethrow;
    }
  }

  // Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Check profile exists error: $e');
      return false;
    }
  }

  // Ensure profile exists (create if not exists)
  Future<void> ensureProfileExists() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final exists = await profileExists(user.id);
      if (!exists) {
        // Get user metadata
        final fullName = user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User';
        
        await createProfile(
          userId: user.id,
          username: fullName,
        );
      }
    } catch (e) {
      print('Ensure profile exists error: $e');
    }
  }

  // ==================== BOOKING FUNCTIONS ====================

  // Create new booking
  Future<Map<String, dynamic>?> createBooking({
    required String title,
    required String price,
    required DateTime bookingDate,
    required String bookingTime,
    required String paymentMethod,
    required int icon,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final booking = {
        'user_id': user.id,
        'title': title,
        'price': price,
        'booking_date': bookingDate.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
        'booking_time': bookingTime,
        'payment_method': paymentMethod,
        'icon': icon,
        'status': 'Terjadwal',
      };

      final response = await _client
          .from('bookings')
          .insert(booking)
          .select()
          .single();

      print('Booking created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('Create booking error: $e');
      rethrow;
    }
  }

  // Get all bookings for current user
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);

      print('Retrieved ${response.length} bookings');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get user bookings error: $e');
      rethrow;
    }
  // ==================== PRODUK FUNCTIONS ====================

// Tambah Produk
Future<Map<String, dynamic>?> tambahProduk({
  required String namaProduk,
  required double hargaProduk,
}) async {
  try {
    final response = await _client
        .from('produk')
        .insert({
          'nama_produk': namaProduk,
          'harga_produk': hargaProduk,
        })
        .select()
        .single();

    print('Produk berhasil ditambahkan: ${response['id']}');
    return response;
  } catch (e) {
    print('Tambah produk error: $e');
    rethrow;
  }
}

// Ambil Semua Produk
Future<List<Map<String, dynamic>>> getSemuaProduk() async {
  try {
    final response = await _client
        .from('produk')
        .select()
        .order('nama_produk', ascending: true);

    print('Total produk diambil: ${response.length}');
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Get semua produk error: $e');
    rethrow;
  }
}

// Update Produk
Future<void> updateProduk({
  required String id,
  required String namaProduk,
  required double hargaProduk,
}) async {
  try {
    await _client
        .from('produk')
        .update({
          'nama_produk': namaProduk,
          'harga_produk': hargaProduk,
        })
        .eq('id', id);

    print('Produk berhasil diupdate: $id');
  } catch (e) {
    print('Update produk error: $e');
    rethrow;
  }
}

// Hapus Produk
Future<void> hapusProduk(String id) async {
  try {
    await _client
        .from('produk')
        .delete()
        .eq('id', id);

    print('Produk berhasil dihapus: $id');
  } catch (e) {
    print('Hapus produk error: $e');
    rethrow;
  }
}

  }

  // Get bookings by status
  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .eq('status', status)
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);

      print('Retrieved ${response.length} bookings with status: $status');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get bookings by status error: $e');
      rethrow;
    }
  }

  // Update booking status
  Future<Map<String, dynamic>?> updateBookingStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId)
          .eq('user_id', user.id) // Ensure user can only update their own bookings
          .select()
          .single();

      print('Booking status updated successfully: $bookingId -> $newStatus');
      return response;
    } catch (e) {
      print('Update booking status error: $e');
      rethrow;
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client
          .from('bookings')
          .delete()
          .eq('id', bookingId)
          .eq('user_id', user.id); // Ensure user can only delete their own bookings

      print('Booking deleted successfully: $bookingId');
    } catch (e) {
      print('Delete booking error: $e');
      rethrow;
    }
  }

  // Get upcoming bookings (today and future)
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Terjadwal')
          .gte('booking_date', today)
          .order('booking_date', ascending: true)
          .order('booking_time', ascending: true);

      print('Retrieved ${response.length} upcoming bookings');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get upcoming bookings error: $e');
      rethrow;
    }
  }

  // Get booking statistics
  Future<Map<String, int>> getBookingStatistics() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final allBookings = await _client
          .from('bookings')
          .select('status')
          .eq('user_id', user.id);

      final stats = <String, int>{
        'total': allBookings.length,
        'terjadwal': 0,
        'selesai': 0,
        'dibatalkan': 0,
      };

      for (final booking in allBookings) {
        final status = booking['status'].toString().toLowerCase();
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      print('Booking statistics: $stats');
      return stats;
    } catch (e) {
      print('Get booking statistics error: $e');
      return {'total': 0, 'terjadwal': 0, 'selesai': 0, 'dibatalkan': 0};
    }
  }
}