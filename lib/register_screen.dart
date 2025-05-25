import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool isLoading = false;

  // Controllers untuk input fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void togglePasswordVisibility() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void toggleConfirmPasswordVisibility() {
    setState(() {
      confirmPasswordVisible = !confirmPasswordVisible;
    });
  }

  Future<void> handleRegister() async {
    // Validate all fields
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showSnackBar('Semua kolom harus diisi', Colors.red);
      return;
    }

    // Validate name length
    if (nameController.text.trim().length < 2) {
      _showSnackBar('Nama minimal 2 karakter', Colors.red);
      return;
    }

    // Validate email format
    if (!emailController.text.contains('@') || !emailController.text.contains('.')) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    // Validate phone number
    if (phoneController.text.trim().length < 10) {
      _showSnackBar('Nomor HP minimal 10 digit', Colors.red);
      return;
    }

    // Validate password match
    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Password tidak sama', Colors.red);
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      _showSnackBar('Password minimal 6 karakter', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1200));

      final box = GetStorage();

      // Check if email already exists
      String? existingEmail = box.read('registered_email');
      if (existingEmail != null && existingEmail == emailController.text.trim()) {
        _showSnackBar('Email sudah terdaftar. Silakan login.', Colors.red);
        return;
      }

      // Save user data to local storage
      await box.write('registered_name', nameController.text.trim());
      await box.write('registered_email', emailController.text.trim());
      await box.write('registered_phone', phoneController.text.trim());
      await box.write('registered_password', passwordController.text);

      _showSnackBar('Pendaftaran berhasil! Silakan login', Colors.green);

      // Clear all fields
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      // Navigate back to login screen after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      _showSnackBar('Pendaftaran gagal: ${e.toString()}', Colors.red);
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Logo
                Container(
                  height: 80,
                  width: 80,
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
                    size: 45,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 16),
                
                // App name
                const Text(
                  "Salon Cantik",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 32),
                
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
                  child: Column(
                    children: [
                      const Text(
                        "Daftar Akun Baru",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      TextField(
                        controller: nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: "Nama Lengkap",
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.pink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "Alamat Email",
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.pink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone field
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "Nomor HP",
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.pink),
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
                          labelText: "Password",
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
                      const SizedBox(height: 16),

                      // Confirm password field
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !confirmPasswordVisible,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
                          suffixIcon: IconButton(
                            icon: Icon(
                              confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.pink,
                            ),
                            onPressed: isLoading ? null : toggleConfirmPasswordVisibility,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Password requirements info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Password minimal 6 karakter",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleRegister,
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
                                  "Daftar Sekarang",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Sudah memiliki akun? "),
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            child: const Text(
                              "Masuk",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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