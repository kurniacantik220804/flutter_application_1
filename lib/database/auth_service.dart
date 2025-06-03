import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/login/user_service.dart';

class AuthService extends GetxController {
  static AuthService get to => Get.find();

  final storage = GetStorage();
  final _isLoading = false.obs;
  final _currentUserRole = 'guest'.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get currentUserRole => _currentUserRole.value;
  bool get isAdmin => _currentUserRole.value == 'admin';
  bool get isUser => _currentUserRole.value == 'user';
  bool get isGuest => _currentUserRole.value == 'guest';

  @override
  void onInit() {
    super.onInit();
    _loadStoredUserRole();
    _listenToAuthChanges();
  }

  // Load stored user role from local storage
  void _loadStoredUserRole() {
    final storedRole = storage.read('user_role') ?? 'guest';
    _currentUserRole.value = storedRole;
    print('Loaded stored user role: $storedRole');
  }

  // Listen to auth state changes
  void _listenToAuthChanges() {
    SupabaseService.to.authStateChanges.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _refreshUserRole();
      } else {
        _clearUserData();
      }
    });
  }

  // Refresh user role from database
  Future<void> _refreshUserRole() async {
    try {
      final role = await UserService.getCurrentUserRole();
      _currentUserRole.value = role;
      await storage.write('user_role', role);
      print('Refreshed user role: $role');
    } catch (e) {
      print('Error refreshing user role: $e');
      _currentUserRole.value = 'user'; // Default fallback
      await storage.write('user_role', 'user');
    }
  }

  // Clear user data on logout
  void _clearUserData() {
    _currentUserRole.value = 'guest';
    storage.remove('user_role');
    storage.remove('user_id');
    storage.remove('user_name');
    storage.remove('user_email');
    storage.remove('user_phone');
    print('User data cleared');
  }

  // Enhanced login with role detection
  Future<LoginResult> loginWithRole({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;

      // Step 1: Authenticate user
      final AuthResponse response = await SupabaseService.to.signIn(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        return LoginResult(
          success: false,
          message: 'Login gagal: Tidak ada session yang dibuat',
          userRole: 'guest',
        );
      }

      // Step 2: Get user profile and role
      final userProfile = await UserService.getUserProfile();
      final userRole = await UserService.getCurrentUserRole();

      // Step 3: Store user data
      await _storeUserData(response.user!, userProfile, userRole);

      // Step 4: Update reactive role
      _currentUserRole.value = userRole;

      return LoginResult(
        success: true,
        message: _getLoginSuccessMessage(userRole),
        userRole: userRole,
        userProfile: userProfile,
      );
    } on AuthException catch (e) {
      return LoginResult(
        success: false,
        message: _getAuthErrorMessage(e),
        userRole: 'guest',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        userRole: 'guest',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Store user data to local storage
  Future<void> _storeUserData(
    User user,
    Map<String, dynamic>? userProfile,
    String userRole,
  ) async {
    await storage.write('user_role', userRole);
    await storage.write('user_id', user.id);

    if (userProfile != null) {
      await storage.write('user_name',
          userProfile['full_name'] ?? userProfile['username'] ?? 'User');
      await storage.write('user_email', userProfile['email'] ?? user.email);
      await storage.write('user_phone', userProfile['phone_number']);
    } else {
      await storage.write('user_name', user.email?.split('@')[0] ?? 'User');
      await storage.write('user_email', user.email);
    }

    print('User data stored - Role: $userRole, ID: ${user.id}');
  }

  // Get login success message based on role
  String _getLoginSuccessMessage(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '🔑 Login berhasil sebagai ADMINISTRATOR!';
      case 'user':
        return '👤 Login berhasil sebagai USER!';
      default:
        return '✅ Login berhasil!';
    }
  }

  // Get auth error message
  String _getAuthErrorMessage(AuthException e) {
    String errorMessage = 'Login gagal: ';

    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        errorMessage += 'Email atau password salah';
        break;
      case 'email not confirmed':
        errorMessage += 'Email belum diverifikasi. Silakan cek email Anda';
        break;
      case 'invalid email':
        errorMessage += 'Format email tidak valid';
        break;
      case 'too many requests':
        errorMessage += 'Terlalu banyak percobaan. Coba lagi nanti';
        break;
      default:
        errorMessage += e.message;
    }

    return errorMessage;
  }

  // Enhanced logout
  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await SupabaseService.to.signOut();
      _clearUserData();
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      await SupabaseService.to.resetPassword(email);
      return true;
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get user display info
  Map<String, dynamic> getUserDisplayInfo() {
    return {
      'role': _currentUserRole.value,
      'name': storage.read('user_name') ?? 'User',
      'email': storage.read('user_email') ?? '',
      'phone': storage.read('user_phone') ?? '',
      'isAdmin': isAdmin,
      'isUser': isUser,
      'isGuest': isGuest,
    };
  }

  // Check permissions
  bool hasPermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'admin':
        return isAdmin;
      case 'user':
        return isUser || isAdmin; // Admin juga punya akses user
      case 'guest':
        return true; // Semua bisa akses guest
      default:
        return false;
    }
  }

  // Get role-specific welcome message
  String getWelcomeMessage() {
    final userInfo = getUserDisplayInfo();
    final name = userInfo['name'];

    switch (_currentUserRole.value.toLowerCase()) {
      case 'admin':
        return '🔑 Selamat datang, Administrator $name!';
      case 'user':
        return '👤 Selamat datang, $name!';
      default:
        return '👋 Selamat datang!';
    }
  }

  // Get role badge info
  Map<String, dynamic> getRoleBadgeInfo() {
    switch (_currentUserRole.value.toLowerCase()) {
      case 'admin':
        return {
          'text': 'ADMIN',
          'color': 'red',
          'icon': 'admin_panel_settings',
          'description': 'Administrator dengan akses penuh'
        };
      case 'user':
        return {
          'text': 'USER',
          'color': 'blue',
          'icon': 'person',
          'description': 'Pengguna reguler'
        };
      default:
        return {
          'text': 'GUEST',
          'color': 'grey',
          'icon': 'person_outline',
          'description': 'Tamu'
        };
    }
  }
}

// Login result class
class LoginResult {
  final bool success;
  final String message;
  final String userRole;
  final Map<String, dynamic>? userProfile;

  LoginResult({
    required this.success,
    required this.message,
    required this.userRole,
    this.userProfile,
  });

  @override
  String toString() {
    return 'LoginResult(success: $success, message: $message, role: $userRole)';
  }
}
