import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/service_supabase.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool isLoading = false;
  String selectedRole = 'user'; // Default role adalah user

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
      print('Starting registration with role: $selectedRole'); // Debug log

      // Step 1: Sign up user dengan Supabase Auth
      final AuthResponse authResponse =
          await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': nameController.text.trim(),
          'phone_number': phoneController.text.trim(),
          'role': selectedRole, // Metadata role
        },
        emailRedirectTo: null,
      );

      if (authResponse.user != null) {
        print('Auth user created with ID: ${authResponse.user!.id}'); // Debug

        // Step 2: Wait a moment for auth to settle
        await Future.delayed(const Duration(milliseconds: 500));

        // Step 3: Insert profile data dengan EXPLICIT role
        try {
          final profileData = {
            'id': authResponse.user!.id,
            'username': nameController.text.trim(),
            'full_name': nameController.text.trim(),
            'phone_number': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'role': selectedRole, // PASTIKAN role disimpan
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          print('Inserting profile with data: $profileData'); // Debug log

          final insertResponse = await Supabase.instance.client
              .from('profiles')
              .insert(profileData)
              .select()
              .single();

          print('Profile inserted successfully: $insertResponse'); // Debug

          // Step 4: Verify the inserted role
          final verifyResponse = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', authResponse.user!.id)
              .single();

          print(
              'Verified role in database: ${verifyResponse['role']}'); // Debug

          // Success message
          _showSnackBar(
              'Pendaftaran berhasil sebagai ${selectedRole.toUpperCase()}! Role: ${verifyResponse['role'] ?? 'UNKNOWN'}',
              Colors.green);

          // Clear all fields
          nameController.clear();
          emailController.clear();
          phoneController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          setState(() {
            selectedRole = 'user'; // Reset role ke default
          });

          // Wait for success message to show
          await Future.delayed(const Duration(milliseconds: 2000));

          if (mounted) {
            Navigator.pop(context);
          }
        } catch (profileError) {
          print('Error inserting profile: $profileError');

          // Try to update instead of insert (in case profile already exists)
          try {
            print('Attempting to update existing profile...');
            await Supabase.instance.client.from('profiles').update({
              'username': nameController.text.trim(),
              'full_name': nameController.text.trim(),
              'phone_number': phoneController.text.trim(),
              'email': emailController.text.trim(),
              'role': selectedRole, // Update role
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', authResponse.user!.id);

            print('Profile updated successfully with role: $selectedRole');
            _showSnackBar('Pendaftaran berhasil (updated)!', Colors.green);

            // Clear and navigate
            nameController.clear();
            emailController.clear();
            phoneController.clear();
            passwordController.clear();
            confirmPasswordController.clear();

            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) Navigator.pop(context);
          } catch (updateError) {
            print('Error updating profile: $updateError');
            _showSnackBar(
                'Akun dibuat tapi profil gagal disimpan: $updateError',
                Colors.orange);
          }
        }
      } else {
        _showSnackBar(
            'Pendaftaran gagal: User tidak berhasil dibuat', Colors.red);
      }
    } on AuthException catch (e) {
      print('Auth error: $e'); // Debug
      String errorMessage = 'Pendaftaran gagal: ';

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
      print('Database error: $e'); // Debug
      String errorMessage = 'Gagal menyimpan data profil: ';
      if (e.message.contains('duplicate key')) {
        errorMessage += 'Username sudah digunakan';
      } else {
        errorMessage += e.message;
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      print('General error: $e'); // Debug
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
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
          duration: const Duration(seconds: 4), // Longer duration to read
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

                      // Info untuk user dengan debug info
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.green, size: 16),
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
                            const SizedBox(height: 4),
                            Text(
                              "Role yang dipilih: ${selectedRole.toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedRole == 'admin'
                                    ? Colors.red[700]
                                    : Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role Selection - Enhanced
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pilih Tipe Akun",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              selectedRole = 'user';
                                            });
                                            print(
                                                'Selected role: user'); // Debug
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selectedRole == 'user'
                                            ? Colors.blue[50]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selectedRole == 'user'
                                              ? Colors.blue
                                              : Colors.grey[300]!,
                                          width: selectedRole == 'user' ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: selectedRole == 'user'
                                                ? Colors.blue
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "User",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedRole == 'user'
                                                      ? Colors.blue
                                                      : Colors.grey[700],
                                                ),
                                              ),
                                              Text(
                                                "Pelanggan",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: selectedRole == 'user'
                                                      ? Colors.blue[700]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              selectedRole = 'admin';
                                            });
                                            print(
                                                'Selected role: admin'); // Debug
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selectedRole == 'admin'
                                            ? Colors.red[50]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selectedRole == 'admin'
                                              ? Colors.red
                                              : Colors.grey[300]!,
                                          width:
                                              selectedRole == 'admin' ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings,
                                            color: selectedRole == 'admin'
                                                ? Colors.red
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Admin",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedRole == 'admin'
                                                      ? Colors.red
                                                      : Colors.grey[700],
                                                ),
                                              ),
                                              Text(
                                                "Pengelola",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: selectedRole == 'admin'
                                                      ? Colors.red[700]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Colors.pink),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.pink, width: 2),
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
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.pink),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.pink, width: 2),
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
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: Colors.pink),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.pink, width: 2),
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
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.pink),
                          suffixIcon: IconButton(
                            icon: Icon(
                              passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.pink,
                            ),
                            onPressed:
                                isLoading ? null : togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.pink, width: 2),
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
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.pink),
                          suffixIcon: IconButton(
                            icon: Icon(
                              confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.pink,
                            ),
                            onPressed: isLoading
                                ? null
                                : toggleConfirmPasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.pink, width: 2),
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
                            backgroundColor: selectedRole == 'admin'
                                ? Colors.red
                                : Colors.pink,
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
                              : Text(
                                  "Daftar sebagai ${selectedRole.toUpperCase()}",
                                  style: const TextStyle(
                                    fontSize: 16,
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
                            onPressed:
                                isLoading ? null : () => Navigator.pop(context),
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
