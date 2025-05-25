import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class Login2Screen extends StatefulWidget {
  const Login2Screen({super.key});

  @override
  State<Login2Screen> createState() => _Login2ScreenState();
}

class _Login2ScreenState extends State<Login2Screen> {
  bool passwordVisible = false;
  bool isResetMode = false;
  bool isLoading = false;

  // Controllers untuk input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void togglePasswordVisibility() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void showResetPasswordScreen() {
    setState(() {
      isResetMode = true;
      // Clear fields
      emailController.clear();
      passwordController.clear();
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
    if (!emailController.text.contains('@')) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      final box = GetStorage();

      // Check if user has registered before
      String? registeredEmail = box.read('registered_email');
      String? registeredPassword = box.read('registered_password');

      bool isValidLogin = false;

      // Check against registered credentials first
      if (registeredEmail != null && registeredPassword != null) {
        if (emailController.text.trim() == registeredEmail &&
            passwordController.text == registeredPassword) {
          isValidLogin = true;
        }
      }

      if (isValidLogin) {
        // Save login state
        await box.write('username', emailController.text.trim());
        await box.write('isLoggedIn', true);

        // Clear form
        emailController.clear();
        passwordController.clear();

        // Show success message
        _showSnackBar('Login berhasil!', Colors.green);

        // Navigate to MainScreen
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Get.offAll(() => const MainScreen());
        }
      } else {
        // Login failed
        _showSnackBar(
          'Email atau password salah!\nSilakan daftar terlebih dahulu jika belum memiliki akun.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Login gagal: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> handleResetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showSnackBar('Masukkan email Anda', Colors.red);
      return;
    }

    if (!emailController.text.contains('@')) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      _showSnackBar('Cek email Anda untuk reset password', Colors.green);

      setState(() {
        isResetMode = false;
        emailController.clear();
      });
    } catch (e) {
      _showSnackBar('Reset password gagal: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
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

        // Info untuk user
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Column(
            children: [
              Text(
                "📝 Silakan daftar terlebih dahulu jika belum memiliki akun",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Email field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
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
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: "Masukkan Password",
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.pink,
              ),
              onPressed: isLoading ? null : togglePasswordVisibility,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : showResetPasswordScreen,
            child: const Text("Lupa password?",
                style: TextStyle(color: Colors.pink)),
          ),
        ),
        const SizedBox(height: 24),
        
        // Login button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Register option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Belum punya akun? "),
            TextButton(
              onPressed: isLoading ? null : () {
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

  Widget buildResetPasswordForm() {
    return Column(
      children: [
        const Text(
          "Lupa Password",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Masukkan email Anda dan tunggu kode aktivasi dikirimkan",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        
        // Email field
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
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
        const SizedBox(height: 24),
        
        // Send reset code button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Kirim",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Back to login
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    isResetMode = false;
                    emailController.clear();
                  });
                },
          child: const Text(
            "Kembali ke halaman Masuk",
            style: TextStyle(color: Colors.pink),
          ),
        ),
      ],
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
                // Logo
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
                  child: const Icon(
                    Icons.spa,
                    size: 60,
                    color: Colors.pink,
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
                // Subtitle
                const Text(
                  "2023",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
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
                  child: isResetMode
                      ? buildResetPasswordForm()
                      : buildLoginForm(),
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