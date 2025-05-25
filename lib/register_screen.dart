import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_supabase.dart'; // Import service

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool isLoading = false;

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
    // Validasi input
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showSnackBar('Semua kolom harus diisi', Colors.red);
      return;
    }

    if (nameController.text.trim().length < 2) {
      _showSnackBar('Nama minimal 2 karakter', Colors.red);
      return;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    if (phoneController.text.trim().length < 10) {
      _showSnackBar('Nomor HP minimal 10 digit', Colors.red);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Password tidak sama', Colors.red);
      return;
    }

    if (passwordController.text.length < 6) {
      _showSnackBar('Password minimal 6 karakter', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Sign up user dengan Supabase Auth tanpa email verification
      final AuthResponse authResponse = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': nameController.text.trim(),
          'phone_number': phoneController.text.trim(),
        },
        emailRedirectTo: null, // Tidak perlu redirect URL untuk verifikasi
      );

      if (authResponse.user != null) {
        // Insert profile data ke table profiles
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': authResponse.user!.id,
            'username': nameController.text.trim(),
            'full_name': nameController.text.trim(),
            'phone_number': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          print('Profile inserted successfully');
        } catch (profileError) {
          print('Error inserting profile: $profileError');
          // Lanjutkan meskipun profile insert gagal
        }

        // Registrasi berhasil
        _showSnackBar('Pendaftaran berhasil! Anda akan login otomatis.', Colors.green);

        // Clear all fields
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        // Tunggu sebentar untuk menampilkan pesan sukses
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Jika ada session (email verification disabled), 
          // auth listener akan otomatis mengarahkan ke MainScreen
          // Atau kita bisa langsung pop untuk kembali ke login dan biarkan auth handle
          Navigator.pop(context);
        }
      } else {
        _showSnackBar('Pendaftaran gagal: User tidak berhasil dibuat', Colors.red);
      }

    } on AuthException catch (e) {
      String errorMessage = 'Pendaftaran gagal: ';
      
      // Handle specific error messages
      if (e.message.toLowerCase().contains('already registered') || 
          e.message.toLowerCase().contains('user already registered')) {
        errorMessage += 'Email sudah terdaftar';
      } else if (e.message.toLowerCase().contains('invalid email')) {
        errorMessage += 'Email tidak valid';
      } else if (e.message.toLowerCase().contains('weak password')) {
        errorMessage += 'Password terlalu lemah';
      } else if (e.message.toLowerCase().contains('signup is disabled')) {
        errorMessage += 'Pendaftaran sedang dinonaktifkan';
      } else {
        errorMessage += e.message;
      }
      
      _showSnackBar(errorMessage, Colors.red);
    } on PostgrestException catch (e) {
      // Handle database errors
      String errorMessage = 'Gagal menyimpan data profil: ';
      if (e.message.contains('duplicate key')) {
        errorMessage += 'Username sudah digunakan';
      } else {
        errorMessage += e.message;
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
      print('Registration error: $e'); // For debugging
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

                const Text(
                  "Salon Cantik",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 32),

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

                      // Info untuk user
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Email tidak perlu verifikasi, langsung bisa login setelah daftar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      TextField(
                        controller: nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: "Nama Lengkap / Username",
                          hintText: "Masukkan nama atau username",
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.pink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "Alamat Email",
                          hintText: "Contoh: user@email.com",
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.pink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "Nomor HP",
                          hintText: "Contoh: 08123456789",
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.pink),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pink, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

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