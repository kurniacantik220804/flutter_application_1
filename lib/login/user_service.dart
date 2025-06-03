import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class UserService {
  static final _supabase = Supabase.instance.client;

  // Enhanced get current user role with better error handling and logging
  static Future<String> getCurrentUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('🔍 UserService: No current user found');
        return 'guest';
      }

      print('🔍 UserService: Getting role for user ${user.id}');

      // Try profiles table first
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle(); // Use maybeSingle to avoid exception

      if (response != null && response['role'] != null) {
        final role = response['role'] as String;
        print('✅ UserService: Role found in profiles table: $role');
        return role;
      } else {
        print('⚠️  UserService: No role in profiles, checking metadata');

        // Fallback to user metadata
        final metadata = user.userMetadata;
        final metadataRole = metadata?['role'] as String?;

        if (metadataRole != null) {
          print('✅ UserService: Role found in metadata: $metadataRole');

          // Try to create/update profile with the metadata role
          await _ensureProfileExists(user, metadataRole);

          return metadataRole;
        } else {
          print('⚠️  UserService: No role found anywhere, defaulting to user');
          return 'user';
        }
      }
    } catch (e) {
      print('❌ UserService: Error getting user role: $e');
      return 'user'; // Default fallback
    }
  }

  // Ensure profile exists in database
  static Future<void> _ensureProfileExists(User user, String role) async {
    try {
      print('🔧 UserService: Ensuring profile exists for ${user.id}');

      final profileData = {
        'id': user.id,
        'email': user.email,
        'role': role,
        'username': user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            'User',
        'full_name': user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            'User',
        'phone_number': user.userMetadata?['phone_number'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try insert first
      try {
        await _supabase.from('profiles').insert(profileData);
        print('✅ UserService: Profile created successfully');
      } catch (insertError) {
        // If insert fails, try update
        print('🔄 UserService: Insert failed, trying update: $insertError');
        await _supabase.from('profiles').update({
          'role': role,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        print('✅ UserService: Profile updated successfully');
      }
    } catch (e) {
      print('❌ UserService: Error ensuring profile exists: $e');
    }
  }

  // Enhanced get user profile with role
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('🔍 UserService: No current user for profile');
        return null;
      }

      print('🔍 UserService: Getting profile for user ${user.id}');

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        print('✅ UserService: Profile found with role: ${response['role']}');
        return response;
      } else {
        print('⚠️  UserService: No profile found, creating from metadata');

        // Create profile from metadata
        final metadata = user.userMetadata ?? {};
        final role = metadata['role'] ?? 'user';

        await _ensureProfileExists(user, role);

        // Return basic profile
        return {
          'id': user.id,
          'email': user.email,
          'role': role,
          'full_name': metadata['full_name'] ?? user.email?.split('@')[0],
          'username': metadata['full_name'] ?? user.email?.split('@')[0],
          'phone_number': metadata['phone_number'],
        };
      }
    } catch (e) {
      print('❌ UserService: Error getting user profile: $e');
      return null;
    }
  }

  // Check if current user is admin with logging
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    final isAdminUser = role == 'admin';
    print('🔍 UserService: isAdmin check - role: $role, isAdmin: $isAdminUser');
    return isAdminUser;
  }

  // Check if current user is regular user
  static Future<bool> isUser() async {
    final role = await getCurrentUserRole();
    final isRegularUser = role == 'user';
    print('🔍 UserService: isUser check - role: $role, isUser: $isRegularUser');
    return isRegularUser;
  }

  // Update user role (admin only) with better validation
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      print(
          '🔧 UserService: Attempting to update role for $userId to $newRole');

      // Check if current user is admin
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        print('❌ UserService: Only admin can update user roles');
        throw Exception('Only admin can update user roles');
      }

      // Validate role
      if (!['admin', 'user'].contains(newRole)) {
        print('❌ UserService: Invalid role: $newRole');
        throw Exception('Invalid role. Must be admin or user');
      }

      await _supabase.from('profiles').update({
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ UserService: Role updated successfully');
      return true;
    } catch (e) {
      print('❌ UserService: Error updating user role: $e');
      return false;
    }
  }

  // Get all users (admin only) with role information
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('🔍 UserService: Getting all users');

      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        print('❌ UserService: Only admin can view all users');
        throw Exception('Only admin can view all users');
      }

      final response = await _supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      final users = List<Map<String, dynamic>>.from(response);
      print('✅ UserService: Found ${users.length} users');

      return users;
    } catch (e) {
      print('❌ UserService: Error getting all users: $e');
      return [];
    }
  }

  // Create or update user profile
  static Future<bool> createOrUpdateProfile({
    required String userId,
    required String email,
    required String role,
    String? fullName,
    String? username,
    String? phoneNumber,
  }) async {
    try {
      print(
          '🔧 UserService: Creating/updating profile for $userId with role $role');

      final profileData = {
        'id': userId,
        'email': email,
        'role': role,
        'username': username ?? fullName ?? email.split('@')[0],
        'full_name': fullName ?? username ?? email.split('@')[0],
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try upsert
      await _supabase.from('profiles').upsert(profileData, onConflict: 'id');

      print('✅ UserService: Profile created/updated successfully');
      return true;
    } catch (e) {
      print('❌ UserService: Error creating/updating profile: $e');
      return false;
    }
  }

  // Verify user role in database (for debugging)
  static Future<void> verifyUserRole(String userId) async {
    try {
      print('🔍 UserService: Verifying role for user $userId');

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        print('✅ UserService: User found in database:');
        print('   ID: ${response['id']}');
        print('   Email: ${response['email']}');
        print('   Role: ${response['role']}');
        print('   Full Name: ${response['full_name']}');
        print('   Username: ${response['username']}');
        print('   Created: ${response['created_at']}');
      } else {
        print('❌ UserService: User not found in profiles table');

        // Check auth user
        final authUser = _supabase.auth.currentUser;
        if (authUser?.id == userId) {
          print('🔍 UserService: Auth user metadata:');
          print('   Email: ${authUser?.email}');
          print('   Metadata: ${authUser?.userMetadata}');
        }
      }
    } catch (e) {
      print('❌ UserService: Error verifying user role: $e');
    }
  }

  // Show role badge widget with enhanced styling
  static Widget getRoleBadge(String role, {double? fontSize}) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String displayText;

    switch (role.toLowerCase()) {
      case 'admin':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.admin_panel_settings;
        displayText = 'ADMIN';
        break;
      case 'user':
      default:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.person;
        displayText = 'USER';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 12,
            ),
          ),
        ],
      ),
    );
  }

  // Get role color for UI consistency
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'user':
      default:
        return Colors.blue;
    }
  }

  // Get role icon for UI consistency
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'user':
      default:
        return Icons.person;
    }
  }
}
