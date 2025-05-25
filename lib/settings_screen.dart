import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'login_2_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool notificationEnabled = true;
  bool emailNotification = false;
  bool smsNotification = true;
  bool promotionNotification = true;
  String selectedLanguage = 'Bahasa Indonesia';
  String selectedTheme = 'Terang';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final box = GetStorage();
    setState(() {
      notificationEnabled = box.read('notification_enabled') ?? true;
      emailNotification = box.read('email_notification') ?? false;
      smsNotification = box.read('sms_notification') ?? true;
      promotionNotification = box.read('promotion_notification') ?? true;
      selectedLanguage = box.read('selected_language') ?? 'Bahasa Indonesia';
      selectedTheme = box.read('selected_theme') ?? 'Terang';
    });
  }

  void _saveSettings() {
    final box = GetStorage();
    box.write('notification_enabled', notificationEnabled);
    box.write('email_notification', emailNotification);
    box.write('sms_notification', smsNotification);
    box.write('promotion_notification', promotionNotification);
    box.write('selected_language', selectedLanguage);
    box.write('selected_theme', selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pengaturan'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Notification Settings
            _buildSectionTitle('Notifikasi'),
            _buildNotificationSettings(),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionTitle('Pengaturan Aplikasi'),
            _buildAppSettings(),
            const SizedBox(height: 24),

            // Account Settings
            _buildSectionTitle('Akun'),
            _buildAccountSettings(),
            const SizedBox(height: 24),

            // Support & About
            _buildSectionTitle('Dukungan & Informasi'),
            _buildSupportSettings(),
            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final box = GetStorage();
    String userName = box.read('registered_name') ?? 'Pengguna';
    String userEmail = box.read('registered_email') ?? 'user@example.com';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent, Colors.pink[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showEditProfileDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Notifikasi Umum',
            'Aktifkan notifikasi untuk semua aktivitas',
            Icons.notifications,
            notificationEnabled,
            (value) {
              setState(() {
                notificationEnabled = value;
                if (!value) {
                  emailNotification = false;
                  smsNotification = false;
                  promotionNotification = false;
                }
              });
              _saveSettings();
            },
          ),
          if (notificationEnabled) ...[
            const Divider(height: 1),
            _buildSwitchTile(
              'Email',
              'Terima notifikasi melalui email',
              Icons.email,
              emailNotification,
              (value) {
                setState(() => emailNotification = value);
                _saveSettings();
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'SMS',
              'Terima notifikasi melalui SMS',
              Icons.sms,
              smsNotification,
              (value) {
                setState(() => smsNotification = value);
                _saveSettings();
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'Promo & Penawaran',
              'Terima notifikasi promo terbaru',
              Icons.local_offer,
              promotionNotification,
              (value) {
                setState(() => promotionNotification = value);
                _saveSettings();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            'Bahasa',
            selectedLanguage,
            Icons.language,
            () => _showLanguageDialog(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Tema',
            selectedTheme,
            Icons.palette,
            () => _showThemeDialog(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Hapus Cache',
            'Bersihkan data sementara',
            Icons.storage,
            () => _showClearCacheDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            'Ubah Password',
            'Ganti password akun Anda',
            Icons.lock,
            () => _showChangePasswordDialog(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Privasi',
            'Pengaturan privasi dan keamanan',
            Icons.privacy_tip,
            () => _showPrivacySettings(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Keluar',
            'Logout dari akun Anda',
            Icons.logout,
            () => _showLogoutDialog(),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            'Pusat Bantuan',
            'FAQ dan panduan aplikasi',
            Icons.help,
            () => _showHelpCenter(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Hubungi Kami',
            'Kontak customer service',
            Icons.contact_support,
            () => _showContactUs(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Tentang Aplikasi',
            'Versi 1.0.0',
            Icons.info,
            () => _showAboutApp(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            'Beri Rating',
            'Nilai aplikasi di store',
            Icons.star,
            () => _showRatingDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.pinkAccent, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor ?? Colors.pinkAccent, size: 20),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    final box = GetStorage();
    final nameController = TextEditingController(text: box.read('registered_name') ?? '');
    final emailController = TextEditingController(text: box.read('registered_email') ?? '');
    final phoneController = TextEditingController(text: box.read('registered_phone') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'No. HP'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              box.write('registered_name', nameController.text);
              box.write('registered_email', emailController.text);
              box.write('registered_phone', phoneController.text);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil diperbarui')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Bahasa Indonesia'),
              value: 'Bahasa Indonesia',
              groupValue: selectedLanguage,
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: selectedLanguage,
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Terang'),
              value: 'Terang',
              groupValue: selectedTheme,
              onChanged: (value) {
                setState(() => selectedTheme = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Gelap'),
              value: 'Gelap',
              groupValue: selectedTheme,
              onChanged: (value) {
                setState(() => selectedTheme = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Sistem'),
              value: 'Sistem',
              groupValue: selectedTheme,
              onChanged: (value) {
                setState(() => selectedTheme = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cache'),
        content: const Text('Apakah Anda yakin ingin menghapus semua data cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final box = GetStorage();
              final savedPassword = box.read('registered_password') ?? '';
              
              if (currentPasswordController.text != savedPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password lama salah')),
                );
                return;
              }
              
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi password tidak sama')),
                );
                return;
              }
              
              box.write('registered_password', newPasswordController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password berhasil diubah')),
              );
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan privasi akan segera hadir')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final box = GetStorage();
              box.remove('is_logged_in');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Login2Screen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pusat bantuan akan segera tersedia')),
    );
  }

  void _showContactUs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Kami'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WhatsApp: +62 812-3456-7890'),
            SizedBox(height: 8),
            Text('Email: support@saloncantik.com'),
            SizedBox(height: 8),
            Text('Telepon: (021) 1234-5678'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Salon Cantik'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('Developer: Salon Cantik Team'),
            SizedBox(height: 8),
            Text('© 2024 Salon Cantik. All rights reserved.'),
            SizedBox(height: 16),
            Text('Aplikasi booking salon terpercaya dengan layanan profesional dan berkualitas tinggi.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Beri Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seberapa puas Anda dengan aplikasi ini?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terima kasih atas rating $rating bintang!')),
                );
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}