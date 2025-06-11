import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/main_screen.dart';
import 'package:flutter_application_1/screen/admin/admin_main_screen.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'package:flutter_application_1/database/auth_service.dart';

class login2screen extends StatefulWidget {
  const login2screen({super.key});

  @override
  State<login2screen> createState() => _login2screenState();
}

class _login2screenState extends State<login2screen> {
  bool passwordVisible = false;

  // Controllers untuk input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Get AuthService instance
  final AuthService authService = Get.put(AuthService());

  void togglePasswordVisibility() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  Future<void> handleLogin() async {
    // Validate input
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar('Email dan Password harus diisi', Colors.red);
      return;
    }

    // Basic email validation
    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    // Use AuthService for login
    final result = await authService.loginWithRole(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    // Show result message
    _showSnackBar(
      result.message,
      result.success ? Colors.green : Colors.red,
    );

    if (result.success) {
      // Clear form
      emailController.clear();
      passwordController.clear();

      // Show additional info for admin
      if (result.userRole == 'admin') {
        _showAdminWelcomeDialog();
      }

      // Navigate based on user role
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        // Navigate to different screens based on role
        if (result.userRole == 'admin') {
          Get.offAll(
              () => const AdminMainScreen()); // Navigate to AdminMainScreen
        } else {
          Get.offAll(
              () => const MainScreen()); // Navigate to regular MainScreen
        }
      }
    }
  }

  void _showAdminWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Akses Administrator'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda berhasil login sebagai Administrator.'),
              SizedBox(height: 8),
              Text('Akses yang tersedia:'),
              SizedBox(height: 4),
              Text('• Dashboard Admin'),
              Text('• Kelola Promo'),
              Text('• Manajemen pengguna'),
              Text('• Kontrol sistem'),
              Text('• Laporan dan analitik'),
              Text('• Pengaturan aplikasi'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget buildLoginForm() {
    return Column(
      children: [
        const Text(
          "Masuk",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        // Email field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !authService.isLoading,
          decoration: InputDecoration(
            labelText: "Masukkan Email",
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.pink),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: passwordController,
          obscureText: !passwordVisible,
          enabled: !authService.isLoading,
          decoration: InputDecoration(
            labelText: "Masukkan Password",
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.pink,
              ),
              onPressed:
                  authService.isLoading ? null : togglePasswordVisibility,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Login button with loading state
        Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authService.isLoading ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: authService.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Masuk",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            )),
        const SizedBox(height: 20),

        // Register option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Belum punya akun? "),
            TextButton(
              onPressed: authService.isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text(
                "Daftar",
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleIndicator(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo - Updated to use PNG from assets
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pink[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to original icon if image fails to load
                        return const Icon(
                          Icons.spa,
                          size: 60,
                          color: Colors.pink,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // App name
                const Text(
                  "Salon Cantik",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 10),
                // Role status only
                Obx(() => Column(
                      children: [
                        if (!authService.isGuest) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: authService.isAdmin
                                  ? Colors.red[100]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Masuk sebagai ${authService.currentUserRole.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: authService.isAdmin
                                    ? Colors.red[800]
                                    : Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    )),
                const SizedBox(height: 40),
                // Main content card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: buildLoginForm(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
