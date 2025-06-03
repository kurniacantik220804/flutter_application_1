import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_application_1/login/login_2_screen.dart';
import 'edit_profile_screen.dart';
import 'package:flutter_application_1/theme/theme_settings_screen.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String userName = 'Loading...';
  String userEmail = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get current user from Supabase
      final user = SupabaseService.to.currentUser;

      if (user != null) {
        // Set email from auth
        userEmail = user.email ?? 'user@example.com';

        // Get profile data from database
        final profile = await SupabaseService.to.getUserProfile();

        if (profile != null && profile['username'] != null) {
          userName = profile['username'];
        } else {
          // Fallback to user metadata or email
          userName = user.userMetadata?['full_name'] ??
              user.email?.split('@')[0] ??
              'Pengguna';
        }
      } else {
        // Fallback to local storage if no user session
        final box = GetStorage();
        userName = box.read('registered_name') ?? 'Pengguna';
        userEmail = box.read('registered_email') ?? 'user@example.com';
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to local storage
      final box = GetStorage();
      userName = box.read('registered_name') ?? 'Pengguna';
      userEmail = box.read('registered_email') ?? 'user@example.com';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final themeController = ThemeController.to;
      final colors = themeController.getThemeColors();

      return Scaffold(
        appBar: _buildAppBar(colors, themeController),
        body: _buildBody(colors, themeController),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
      ThemeColors colors, ThemeController themeController) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Pengaturan'),
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeColors colors, ThemeController themeController) {
    return Container(
      decoration: BoxDecoration(
        gradient: themeController.getBackgroundGradient(),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _ProfileSection(
              userName: userName,
              userEmail: userEmail,
              isLoading: isLoading,
              colors: colors,
              onEditPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ).then((_) {
                        _loadUserData();
                      });
                    },
            ),
            const SizedBox(height: 24),

            // Settings Options (hanya tema)
            _SettingsOptions(colors: colors),
            const SizedBox(height: 24),

            // Logout Button
            _LogoutButton(
              colors: colors,
              onLogoutPressed: () => _showLogoutDialog(),
            ),
            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final themeController = ThemeController.to;
    final colors = themeController.getThemeColors();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Keluar',
          style: TextStyle(color: colors.primary),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Logout from Supabase
                await SupabaseService.to.signOut();

                // Clear local storage
                final box = GetStorage();
                box.remove('is_logged_in');

                // Navigate to login screen
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Login2Screen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                print('Logout error: $e');
                // Still navigate to login even if logout fails
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Login2Screen()),
                    (route) => false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// Separate stateless widgets untuk optimasi performa
class _ProfileSection extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isLoading;
  final ThemeColors colors;
  final VoidCallback? onEditPressed;

  const _ProfileSection({
    required this.userName,
    required this.userEmail,
    required this.isLoading,
    required this.colors,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Loading...' : userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? 'Loading...' : userEmail,
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
            onPressed: onEditPressed,
          ),
        ],
      ),
    );
  }
}

class _SettingsOptions extends StatelessWidget {
  final ThemeColors colors;

  const _SettingsOptions({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Theme Settings - Tema akan berubah otomatis tanpa refresh
        Obx(() {
          return _SettingsItem(
            colors: colors,
            icon: Icons.palette,
            title: 'Pengaturan Tema',
            subtitle: 'Tema: ${ThemeController.to.selectedTheme.name}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final ThemeColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colors.primary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final ThemeColors colors;
  final VoidCallback onLogoutPressed;

  const _LogoutButton({
    required this.colors,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Keluar',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: const Text(
          'Logout dari akun Anda',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onLogoutPressed,
      ),
    );
  }
}
