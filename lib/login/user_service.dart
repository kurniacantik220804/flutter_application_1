import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class UserService {
  static final _supabase = Supabase.instance.client;

  // Get current user role
  static Future<String> getCurrentUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'guest';

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] ?? 'user';
    } catch (e) {
      print('Error getting user role: $e');
      return 'user'; // Default fallback
    }
  }

  // Get user profile with role
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Check if current user is regular user
  static Future<bool> isUser() async {
    final role = await getCurrentUserRole();
    return role == 'user';
  }

  // Update user role (admin only)
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      // Check if current user is admin
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        throw Exception('Only admin can update user roles');
      }

      await _supabase
          .from('profiles')
          .update({'role': newRole}).eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        throw Exception('Only admin can view all users');
      }

      final response = await _supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Show role badge widget
  static Widget getRoleBadge(String role) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.admin_panel_settings;
        break;
      case 'user':
      default:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
