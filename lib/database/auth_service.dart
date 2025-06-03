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
    print('🔍 Loaded stored user role: $storedRole');
  }

  // Listen to auth state changes
  void _listenToAuthChanges() {
    SupabaseService.to.authStateChanges.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        print('🔄 Auth state changed, refreshing user role for: ${user.id}');
        _refreshUserRole();
      } else {
        print('🚪 User logged out, clearing data');
        _clearUserData();
      }
    });
  }

  // Enhanced refresh user role from database with better error handling
  Future<void> _refreshUserRole() async {
    try {
      final user = SupabaseService.to.currentUser;
      if (user == null) {
        print('❌ No current user found');
        _currentUserRole.value = 'guest';
        return;
      }

      print('🔍 Fetching role for user: ${user.id}');

      // Try to get role from profiles table
      final response = await SupabaseService.to.client
          .from('profiles')
          .select('role, username, full_name, email, phone_number')
          .eq('id', user.id)
          .maybeSingle(); // Use maybeSingle to avoid exception if no record

      if (response != null && response['role'] != null) {
        final role = response['role'] as String;
        print('✅ Role found in database: $role');

        _currentUserRole.value = role;
        await storage.write('user_role', role);

        // Also store other user data
        await storage.write('user_id', user.id);
        await storage.write('user_name',
            response['full_name'] ?? response['username'] ?? 'User');
        await storage.write('user_email', response['email'] ?? user.email);
        await storage.write('user_phone', response['phone_number']);

        print('💾 Stored user data - Role: $role');
      } else {
        print('⚠️  No profile found in database, checking auth metadata');

        // Fallback: check auth user metadata
        final userMetadata = user.userMetadata;
        final metadataRole = userMetadata?['role'] as String?;

        if (metadataRole != null) {
          print('📋 Found role in metadata: $metadataRole');
          _currentUserRole.value = metadataRole;
          await storage.write('user_role', metadataRole);

          // Try to create profile record
          await _createMissingProfile(user, metadataRole);
        } else {
          print('❌ No role found anywhere, defaulting to user');
          _currentUserRole.value = 'user';
          await storage.write('user_role', 'user');
        }
      }
    } catch (e) {
      print('❌ Error refreshing user role: $e');
      _currentUserRole.value = 'user'; // Safe fallback
      await storage.write('user_role', 'user');
    }
  }

  // Create missing profile record
  Future<void> _createMissingProfile(User user, String role) async {
    try {
      print('🔧 Creating missing profile for user: ${user.id}');

      final profileData = {
        'id': user.id,
        'email': user.email,
        'role': role,
        'username': user.email?.split('@')[0] ?? 'User',
        'full_name': user.userMetadata?['full_name'] ??
            user.email?.split('@')[0] ??
            'User',
        'phone_number': user.userMetadata?['phone_number'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.to.client.from('profiles').insert(profileData);

      print('✅ Profile created successfully');
    } catch (e) {
      print('❌ Error creating profile: $e');
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
    print('🧹 User data cleared');
  }

  // Enhanced login with better role detection
  Future<LoginResult> loginWithRole({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      print('🔐 Starting login for: $email');

      // Step 1: Authenticate user
      final AuthResponse response = await SupabaseService.to.signIn(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        print('❌ Login failed: No session created');
        return LoginResult(
          success: false,
          message: 'Login gagal: Tidak ada session yang dibuat',
          userRole: 'guest',
        );
      }

      print('✅ Auth successful for user: ${response.user!.id}');

      // Step 2: Wait for database consistency
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Get user profile and role with multiple attempts
      String userRole = 'user';
      Map<String, dynamic>? userProfile;

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          print('🔍 Attempt ${attempt + 1}: Fetching user profile');

          final profileResponse = await SupabaseService.to.client
              .from('profiles')
              .select('*')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profileResponse != null) {
            userProfile = profileResponse;
            userRole = profileResponse['role'] ?? 'user';
            print('✅ Profile found: role = $userRole');
            break;
          } else {
            print('⚠️  Profile not found, attempt ${attempt + 1}');
            if (attempt < 2) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } catch (e) {
          print('❌ Error fetching profile (attempt ${attempt + 1}): $e');
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // Step 4: Fallback to metadata if profile not found
      if (userProfile == null) {
        print('🔄 Using auth metadata as fallback');
        final metadata = response.user!.userMetadata;
        userRole = metadata?['role'] ?? 'user';

        userProfile = {
          'id': response.user!.id,
          'email': response.user!.email,
          'role': userRole,
          'full_name':
              metadata?['full_name'] ?? response.user!.email?.split('@')[0],
          'phone_number': metadata?['phone_number'],
        };
      }

      // Step 5: Store user data
      await _storeUserData(response.user!, userProfile, userRole);

      // Step 6: Update reactive role
      _currentUserRole.value = userRole;

      print('🎉 Login successful with role: $userRole');

      return LoginResult(
        success: true,
        message: _getLoginSuccessMessage(userRole),
        userRole: userRole,
        userProfile: userProfile,
      );
    } on AuthException catch (e) {
      print('❌ Auth exception: ${e.message}');
      return LoginResult(
        success: false,
        message: _getAuthErrorMessage(e),
        userRole: 'guest',
      );
    } catch (e) {
      print('❌ General error during login: $e');
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

    print('💾 User data stored - Role: $userRole, ID: ${user.id}');
  }

  // Enhanced login success message
  String _getLoginSuccessMessage(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '🔑 Login berhasil sebagai ADMINISTRATOR! Selamat datang, Admin.';
      case 'user':
        return '👤 Login berhasil sebagai USER! Selamat datang.';
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
      print('🚪 Logging out user');
      await SupabaseService.to.signOut();
      _clearUserData();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
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
      print('❌ Reset password error: $e');
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

  // Manual role refresh (for debugging)
  Future<void> forceRefreshRole() async {
    print('🔄 Forcing role refresh...');
    await _refreshUserRole();
  }

  // Debug current state
  void debugCurrentState() {
    print('=== AUTH SERVICE DEBUG ===');
    print('Current User Role: ${_currentUserRole.value}');
    print('Is Admin: $isAdmin');
    print('Is User: $isUser');
    print('Is Guest: $isGuest');
    print('Stored Role: ${storage.read('user_role')}');
    print('Stored Name: ${storage.read('user_name')}');
    print('Stored Email: ${storage.read('user_email')}');
    print('========================');
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
