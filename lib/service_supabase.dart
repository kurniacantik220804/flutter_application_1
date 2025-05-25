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
}