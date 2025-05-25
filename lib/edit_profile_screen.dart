import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isObscureCurrentPassword = true;
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmNewPassword = true;
  bool _isLoadingProfile = true; // State untuk loading data profil

  // Inisialisasi Supabase client
  final SupabaseClient supabase = Supabase.instance.client;
  User? _currentUser; // Untuk menyimpan data user Supabase Auth

  @override
  void initState() {
    super.initState();
    _currentUser = supabase.auth.currentUser; // Ambil user yang sedang login
    _fetchUserProfile(); // Panggil fungsi untuk memuat data profil
  }

  Future<void> _fetchUserProfile() async {
    if (_currentUser == null) {
      _showSnackBar('Pengguna tidak login.', Colors.red);
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      // Ambil data dari tabel 'profiles' berdasarkan ID pengguna
      final response = await supabase
          .from('profiles')
          .select('username, email, phone_number') // Pilih kolom yang Anda inginkan
          .eq('id', _currentUser!.id)
          .single(); // Ambil satu baris saja

      if (response != null) {
        setState(() {
          _nameController.text = response['username'] ?? '';
          // Mengambil email dari profiles, fallback ke Supabase Auth jika tidak ada di profiles
          _emailController.text = response['email'] ?? _currentUser!.email ?? '';
          _phoneController.text = response['phone_number'] ?? '';
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data profil: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        _showSnackBar('Pengguna tidak login.', Colors.red);
        return;
      }

      setState(() {
        _isLoadingProfile = true; // Mengaktifkan loading saat menyimpan
      });

      try {
        // PERBARUI DATA PROFIL DI TABEL 'profiles'
        await supabase
            .from('profiles')
            .update({
              'username': _nameController.text.trim(),
              'email': _emailController.text.trim(), // Pastikan kolom email ada di tabel profiles
              'phone_number': _phoneController.text.trim(), // Pastikan kolom phone_number ada di tabel profiles
              'updated_at': DateTime.now().toIso8601String(), // Perbarui timestamp
            })
            .eq('id', _currentUser!.id);

        // Jika Anda juga ingin memperbarui email di Supabase Auth (hati-hati dengan verifikasi email)
        // Ini akan memicu email verifikasi lagi jika email diubah.
        if (_emailController.text.trim() != _currentUser!.email) {
          await supabase.auth.updateUser(UserAttributes(
            email: _emailController.text.trim(),
          ));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke SettingsScreen
      } on PostgrestException catch (e) {
        _showSnackBar('Gagal memperbarui profil: ${e.message}', Colors.red);
      } catch (e) {
        _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
      } finally {
        setState(() {
          _isLoadingProfile = false; // Menonaktifkan loading
        });
      }
    }
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        _showSnackBar('Pengguna tidak login.', Colors.red);
        return;
      }

      // Validasi konfirmasi password
      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        _showSnackBar('Konfirmasi kata sandi tidak cocok.', Colors.red);
        return;
      }
      
      // Kata sandi saat ini tidak diperlukan secara eksplisit oleh Supabase Auth
      // saat memperbarui kata sandi dengan updateUser, tetapi Anda bisa menambahkannya
      // untuk validasi di sisi klien jika mau.
      // Untuk Supabase Auth, cukup panggil updateUser dengan password baru.
      // Logika di bawah ini mengasumsikan validasi password saat ini akan dilakukan oleh backend Supabase
      // atau tidak diperlukan untuk metode otentikasi yang digunakan.
      // Jika Anda memerlukan validasi password saat ini di sisi klien, Anda perlu mengambil
      // dan memverifikasi password dari backend Anda atau state lokal (jika ada).

      setState(() {
        _isLoadingProfile = true; // Mengaktifkan loading saat mengubah password
      });

      try {
        // Mengubah kata sandi di Supabase Auth
        await supabase.auth.updateUser(UserAttributes(
          password: _newPasswordController.text,
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diubah!')),
        );
        // Bersihkan field password setelah berhasil
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } on AuthException catch (e) {
        _showSnackBar('Gagal mengubah kata sandi: ${e.message}', Colors.red);
      } catch (e) {
        _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false; // Menonaktifkan loading
          });
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pinkAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator()) // Tampilkan loading
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              const Text(
                'Ubah Kata Sandi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureCurrentPassword = !_isObscureCurrentPassword;
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureNewPassword = !_isObscureNewPassword;
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmNewPasswordController,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirmNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureConfirmNewPassword = !_isObscureConfirmNewPassword;
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
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}