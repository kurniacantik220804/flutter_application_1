import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _storage = GetStorage();
  static const String _themeKey = 'selected_theme';
  static const String _customColorsKey = 'custom_colors';

  // Observable untuk tema yang dipilih
  final _selectedTheme = AppThemeType.pink.obs;
  final _isDarkMode = false.obs;
  final Rx<Color> _customPrimaryColor =
      const Color(0xFFFF4081).obs; // Colors.pinkAccent
  final Rx<Color> _customSecondaryColor =
      const Color(0xFFE91E63).obs; // Colors.pink

  // Getters
  AppThemeType get selectedTheme => _selectedTheme.value;
  bool get isDarkMode => _isDarkMode.value;
  Color get customPrimaryColor => _customPrimaryColor.value;
  Color get customSecondaryColor => _customSecondaryColor.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  // Load tema dari storage
  void _loadTheme() {
    try {
      final themeIndex = _storage.read(_themeKey) ?? 0;
      if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
        _selectedTheme.value = AppThemeType.values[themeIndex];
      }

      final customColors = _storage.read(_customColorsKey);
      if (customColors != null && customColors is Map) {
        try {
          final primaryValue = customColors['primary'];
          final secondaryValue = customColors['secondary'];

          if (primaryValue != null && primaryValue is int) {
            _customPrimaryColor.value = Color(primaryValue);
          }
          if (secondaryValue != null && secondaryValue is int) {
            _customSecondaryColor.value = Color(secondaryValue);
          }
        } catch (e) {
          print('Error loading custom colors: $e');
          // Reset to default colors if there's an error
          _resetCustomColors();
        }
      }
    } catch (e) {
      print('Error loading theme: $e');
      // Reset to default if there's an error
      _selectedTheme.value = AppThemeType.pink;
      _resetCustomColors();
    }
  }

  // Reset custom colors to default
  void _resetCustomColors() {
    _customPrimaryColor.value = const Color(0xFFFF4081); // Colors.pinkAccent
    _customSecondaryColor.value = const Color(0xFFE91E63); // Colors.pink
  }

  // Simpan tema ke storage
  void _saveTheme() {
    try {
      _storage.write(_themeKey, _selectedTheme.value.index);
      _storage.write(_customColorsKey, {
        'primary': _customPrimaryColor.value.value,
        'secondary': _customSecondaryColor.value.value,
      });
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Ganti tema
  void changeTheme(AppThemeType theme) {
    _selectedTheme.value = theme;
    _saveTheme();
    _updateAppTheme();
  }

  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode.value = !_isDarkMode.value;
    _updateAppTheme();
  }

  // Set custom colors
  void setCustomColors(Color primary, Color secondary) {
    _customPrimaryColor.value = primary;
    _customSecondaryColor.value = secondary;
    if (_selectedTheme.value == AppThemeType.custom) {
      _saveTheme();
      _updateAppTheme();
    }
  }

  // Update tema aplikasi
  void _updateAppTheme() {
    Get.changeTheme(getCurrentTheme());
  }

  // Dapatkan tema saat ini
  ThemeData getCurrentTheme() {
    final themeColors = getThemeColors();

    return ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode.value ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors.primary,
        brightness: _isDarkMode.value ? Brightness.dark : Brightness.light,
      ),
      primaryColor: themeColors.primary,
      scaffoldBackgroundColor:
          _isDarkMode.value ? const Color(0xFF121212) : themeColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: themeColors.primary,
        unselectedItemColor: Colors.grey,
      ),
      cardTheme: CardTheme(
        color: _isDarkMode.value ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return themeColors.primary;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return themeColors.primary.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }

  // Dapatkan warna tema
  ThemeColors getThemeColors() {
    switch (_selectedTheme.value) {
      case AppThemeType.pink:
        return ThemeColors(
          primary: const Color(0xFFFF4081), // Colors.pinkAccent
          secondary: const Color(0xFFE91E63), // Colors.pink
          background: const Color(0xFFFFF0F5),
          surface: Colors.white,
        );
      case AppThemeType.blue:
        return ThemeColors(
          primary: const Color(0xFF2196F3), // Colors.blue
          secondary: const Color(0xFF03A9F4), // Colors.lightBlue
          background: const Color(0xFFF0F8FF),
          surface: Colors.white,
        );
      case AppThemeType.purple:
        return ThemeColors(
          primary: const Color(0xFF9C27B0), // Colors.purple
          secondary: const Color(0xFF673AB7), // Colors.deepPurple
          background: const Color(0xFFF8F0FF),
          surface: Colors.white,
        );
      case AppThemeType.green:
        return ThemeColors(
          primary: const Color(0xFF4CAF50), // Colors.green
          secondary: const Color(0xFF8BC34A), // Colors.lightGreen
          background: const Color(0xFFF0FFF0),
          surface: Colors.white,
        );
      case AppThemeType.orange:
        return ThemeColors(
          primary: const Color(0xFFFF9800), // Colors.orange
          secondary: const Color(0xFFFF5722), // Colors.deepOrange
          background: const Color(0xFFFFF8F0),
          surface: Colors.white,
        );
      case AppThemeType.teal:
        return ThemeColors(
          primary: const Color(0xFF009688), // Colors.teal
          secondary: const Color(0xFF00BCD4), // Colors.cyan
          background: const Color(0xFFF0FFFF),
          surface: Colors.white,
        );
      case AppThemeType.custom:
        return ThemeColors(
          primary: _customPrimaryColor.value,
          secondary: _customSecondaryColor.value,
          background: const Color(0xFFFAFAFA), // Colors.grey[50]
          surface: Colors.white,
        );
    }
  }

  // Dapatkan gradient background berdasarkan tema
  LinearGradient getBackgroundGradient() {
    final colors = getThemeColors();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.background,
        colors.primary.withOpacity(0.1),
        colors.secondary.withOpacity(0.05),
      ],
    );
  }

  // Dapatkan decorasi container dengan tema
  BoxDecoration getThemedDecoration({
    double borderRadius = 12,
    bool withShadow = true,
    bool withGradient = false,
  }) {
    final colors = getThemeColors();

    return BoxDecoration(
      color: withGradient ? null : colors.surface,
      gradient: withGradient
          ? LinearGradient(
              colors: [
                colors.primary.withOpacity(0.1),
                colors.secondary.withOpacity(0.05),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: colors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ]
          : null,
    );
  }
}

// Enum untuk tipe tema
enum AppThemeType {
  pink,
  blue,
  purple,
  green,
  orange,
  teal,
  custom,
}

// Class untuk menyimpan warna tema
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
  });
}

// Extension untuk mendapatkan nama tema
extension AppThemeTypeExtension on AppThemeType {
  String get name {
    switch (this) {
      case AppThemeType.pink:
        return 'Pink';
      case AppThemeType.blue:
        return 'Blue';
      case AppThemeType.purple:
        return 'Purple';
      case AppThemeType.green:
        return 'Green';
      case AppThemeType.orange:
        return 'Orange';
      case AppThemeType.teal:
        return 'Teal';
      case AppThemeType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeType.pink:
        return Icons.favorite;
      case AppThemeType.blue:
        return Icons.water_drop;
      case AppThemeType.purple:
        return Icons.auto_awesome;
      case AppThemeType.green:
        return Icons.eco;
      case AppThemeType.orange:
        return Icons.wb_sunny;
      case AppThemeType.teal:
        return Icons.spa;
      case AppThemeType.custom:
        return Icons.palette;
    }
  }
}
