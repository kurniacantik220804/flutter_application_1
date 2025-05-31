import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static ThemeController get to {
    try {
      return Get.find<ThemeController>();
    } catch (e) {
      Get.put(ThemeController());
      return Get.find<ThemeController>();
    }
  }

  final _storage = GetStorage();
  static const String _themeKey = 'tema_terpilih';

  // Observable untuk tema yang dipilih
  final _selectedTheme = AppThemeType.pink.obs;

  // Cache untuk warna tema agar tidak dihitung berulang
  ThemeColors? _cachedColors;
  AppThemeType? _lastCachedTheme;

  // Getters
  AppThemeType get selectedTheme => _selectedTheme.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
    _cacheThemeColors(); // Cache warna di init
  }

  // Cache warna tema untuk performa
  void _cacheThemeColors() {
    if (_lastCachedTheme != _selectedTheme.value) {
      _lastCachedTheme = _selectedTheme.value;
      _cachedColors = _getThemeColorsInternal(_selectedTheme.value);
    }
  }

  // Muat tema dari penyimpanan
  void _loadTheme() {
    try {
      final themeIndex = _storage.read(_themeKey) ?? 0;
      if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
        _selectedTheme.value = AppThemeType.values[themeIndex];
      } else {
        _selectedTheme.value = AppThemeType.pink;
      }
    } catch (e) {
      print('Error memuat tema: $e');
      _selectedTheme.value = AppThemeType.pink;
    }
  }

  // Simpan tema ke penyimpanan
  void _saveTheme() {
    try {
      _storage.write(_themeKey, _selectedTheme.value.index);
    } catch (e) {
      print('Error menyimpan tema: $e');
    }
  }

  // Ganti tema dengan optimasi
  void changeTheme(AppThemeType theme) {
    if (_selectedTheme.value == theme) return; // Tidak perlu update jika sama
    
    _selectedTheme.value = theme;
    _cacheThemeColors(); // Update cache
    _saveTheme();
    _updateAppTheme();
    
    // Update hanya widget tertentu, bukan semua
    update(['dashboard', 'theme_settings']); // ID spesifik
  }

  // Update tema aplikasi
  void _updateAppTheme() {
    try {
      Get.changeTheme(getCurrentTheme());
    } catch (e) {
      print('Error mengupdate tema aplikasi: $e');
    }
  }

  // Dapatkan tema saat ini dengan cache
  ThemeData getCurrentTheme() {
    _cacheThemeColors();
    final themeColors = _cachedColors!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors.primary,
        brightness: Brightness.light,
      ),
      primaryColor: themeColors.primary,
      scaffoldBackgroundColor: themeColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: themeColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.primary,
          side: BorderSide(color: themeColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

  // Dapatkan warna tema dengan cache
  ThemeColors getThemeColors() {
    _cacheThemeColors();
    return _cachedColors!;
  }

  // Internal method untuk mendapatkan warna tema
  ThemeColors _getThemeColorsInternal(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.pink:
        return const ThemeColors(
          primary: Color(0xFFFF4081),
          secondary: Color(0xFFE91E63),
          background: Color(0xFFFFF0F5),
          surface: Colors.white,
        );
      case AppThemeType.purple:
        return const ThemeColors(
          primary: Color(0xFF9C27B0),
          secondary: Color(0xFF673AB7),
          background: Color(0xFFF8F0FF),
          surface: Colors.white,
        );
      case AppThemeType.teal:
        return const ThemeColors(
          primary: Color(0xFF009688),
          secondary: Color(0xFF00BCD4),
          background: Color(0xFFF0FFFF),
          surface: Colors.white,
        );
      default:
        return const ThemeColors(
          primary: Color(0xFFFF4081),
          secondary: Color(0xFFE91E63),
          background: Color(0xFFFFF0F5),
          surface: Colors.white,
        );
    }
  }

  // Dapatkan gradient background dengan cache
  LinearGradient getBackgroundGradient() {
    _cacheThemeColors();
    final colors = _cachedColors!;

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

  // Dapatkan dekorasi container dengan tema dan cache
  BoxDecoration getThemedDecoration({
    double borderRadius = 12,
    bool withShadow = true,
    bool withGradient = false,
  }) {
    _cacheThemeColors();
    final colors = _cachedColors!;

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

  // Method untuk inisialisasi controller
  static Future<void> initialize() async {
    try {
      await GetStorage.init();
      Get.put(ThemeController());
    } catch (e) {
      print('Error menginisialisasi ThemeController: $e');
    }
  }

  // Method untuk cek apakah controller sudah diinisialisasi
  static bool get isInitialized {
    try {
      Get.find<ThemeController>();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Method untuk force refresh cache (jika diperlukan)
  void refreshCache() {
    _lastCachedTheme = null;
    _cacheThemeColors();
    update();
  }
}

// Enum untuk tipe tema (hanya 3 pilihan)
enum AppThemeType {
  pink,
  purple,
  teal,
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

  // Operator == untuk perbandingan
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeColors &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.background == background &&
        other.surface == surface;
  }

  @override
  int get hashCode {
    return primary.hashCode ^
        secondary.hashCode ^
        background.hashCode ^
        surface.hashCode;
  }
}

// Extension untuk mendapatkan nama tema dalam bahasa Indonesia
extension AppThemeTypeExtension on AppThemeType {
  String get name {
    switch (this) {
      case AppThemeType.pink:
        return 'Pink';
      case AppThemeType.purple:
        return 'Ungu';
      case AppThemeType.teal:
        return 'Tosca';
    }
  }

  String get description {
    switch (this) {
      case AppThemeType.pink:
        return 'Tema Pink - Feminin dan Elegan';
      case AppThemeType.purple:
        return 'Tema Ungu - Mewah dan Misterius';
      case AppThemeType.teal:
        return 'Tema Tosca - Segar dan Modern';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeType.pink:
        return Icons.favorite;
      case AppThemeType.purple:
        return Icons.auto_awesome;
      case AppThemeType.teal:
        return Icons.spa;
    }
  }
}