import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk password fields
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  // Visibility states
  bool _isObscureCurrentPassword = true;
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmNewPassword = true;
  bool _isLoading = false;

  // User info untuk display
  String _userEmail = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = SupabaseService.to.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email ?? '';
        });

        // Load profile info untuk display
        final profile = await SupabaseService.to.getUserProfile();
        if (profile != null) {
          setState(() {
            _userName = profile['username'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi konfirmasi password
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showSnackBar('Konfirmasi kata sandi tidak cocok.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Untuk Supabase, kita perlu re-authenticate user terlebih dahulu
      // karena updateUser untuk password memerlukan user yang baru login
      final currentUser = SupabaseService.to.currentUser;
      if (currentUser == null) {
        _showSnackBar('Pengguna tidak login.', Colors.red);
        return;
      }

      // Re-authenticate dengan password saat ini
      await SupabaseService.to.signIn(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );

      // Setelah re-authentication berhasil, update password
      await SupabaseService.to.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      _showSnackBar('Kata sandi berhasil diubah!', Colors.green);

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();

      // Optional: Navigate back after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      String errorMessage = 'Gagal mengubah kata sandi: ';

      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
          errorMessage += 'Kata sandi saat ini salah';
          break;
        case 'weak password':
          errorMessage += 'Kata sandi baru terlalu lemah';
          break;
        case 'same password':
          errorMessage += 'Kata sandi baru tidak boleh sama dengan yang lama';
          break;
        default:
          errorMessage += e.message;
      }

      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
      print('Change password error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = ThemeController.to;
      final colors = themeController.getThemeColors();

      return ThemedScaffold(
        appBar: ThemedAppBar(
          title: 'Edit Profil',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card (Read-only)
              ThemedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemedText(
                      text: 'Informasi Akun',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Email', _userEmail, Icons.email, colors),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Nama',
                      _userName.isEmpty ? 'Belum diatur' : _userName,
                      Icons.person,
                      colors,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Password Change Form
              ThemedCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemedText(
                        text: 'Ubah Kata Sandi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),

                      // Current Password
                      TextFormField(
                        controller: _currentPasswordController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi Saat Ini',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                          prefixIcon: Icon(Icons.lock, color: colors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureCurrentPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colors.primary,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isObscureCurrentPassword =
                                          !_isObscureCurrentPassword;
                                    });
                                  },
                          ),
                        ),
                        obscureText: _isObscureCurrentPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi saat ini tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      TextFormField(
                        controller: _newPasswordController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi Baru',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: colors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colors.primary,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isObscureNewPassword =
                                          !_isObscureNewPassword;
                                    });
                                  },
                          ),
                        ),
                        obscureText: _isObscureNewPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi baru tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm New Password
                      TextFormField(
                        controller: _confirmNewPasswordController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi Baru',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: colors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureConfirmNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colors.primary,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isObscureConfirmNewPassword =
                                          !_isObscureConfirmNewPassword;
                                    });
                                  },
                          ),
                        ),
                        obscureText: _isObscureConfirmNewPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi kata sandi tidak boleh kosong';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ubah Kata Sandi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, ThemeColors colors) {
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
