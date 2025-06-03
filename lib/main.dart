import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_application_1/database/auth_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login/login_2_screen.dart';
import 'screen/detail_layanan.dart';
import 'screen/riwayat_screen.dart';
import 'screen/promo_screen.dart';
import 'screen/main_screen.dart';
import 'package:flutter_application_1/database/service_supabase.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';

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
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    _authSubscription = SupabaseService.to.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.initialSession:
          // Initial session check
          if (session != null) {
            Get.offAll(() => const MainScreen());
          } else {
            Get.offAll(() => const login2screen());
          }
          break;
        case AuthChangeEvent.signedIn:
          Get.offAll(() => const MainScreen());
          break;
        case AuthChangeEvent.signedOut:
          Get.offAll(() => const login2screen());
          break;
        default:
          break;
      }
    });

    // Initial delay untuk splash screen
    Future.delayed(const Duration(seconds: 2), () {
      // Jika tidak ada perubahan auth state dalam 2 detik, cek manual
      final currentSession = SupabaseService.to.currentSession;
      if (currentSession != null) {
        Get.offAll(() => const MainScreen());
      } else {
        Get.offAll(() => const login2screen());
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return Scaffold(
          body: ThemedBackground(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  AnimatedThemedContainer(
                    padding: EdgeInsets.all(screenSize.width * 0.1),
                    child: Icon(
                      Icons.spa,
                      size: screenSize.width * 0.2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // App name
                  ThemedText(
                    text: "Salon Cantik",
                    isPrimary: true,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  ThemedText(
                    text: "2023",
                    isSecondary: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Loading indicator
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
