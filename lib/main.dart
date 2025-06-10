import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_application_1/database/auth_service.dart';
import 'package:flutter_application_1/screen/promo_screen.dart';
import 'splash/splash_screen.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login/login_2_screen.dart';
import 'screen/detail_layanan.dart';
import 'screen/riwayat_screen.dart';
import 'screen/main_screen.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'screen/admin/admin_promo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://xpzslbieloolznmowdax.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwenNsYmllbG9vbHpubW93ZGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNTY3ODUsImV4cCI6MjA2MzczMjc4NX0.kDWu37oK58OQsYldglPcrBYrAxTV7KXvZTJ2qww7ESg',
  );

  // Inisialisasi SupabaseService
  Get.put(SupabaseService());
  Get.put(PromoScreen());
  // Inisialisasi ThemeController
  Get.put(ThemeController());
  Get.put(AuthService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Salon Cantik',
          theme: themeController.getCurrentTheme(),
          home: const SplashScreen(), // Menggunakan splash screen eksternal
        );
      },
    );
  }
}
