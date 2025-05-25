import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_2_screen.dart';
import 'detail_layanan.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';
import 'promo_screen.dart';
import 'booking_screen.dart';
import 'main_screen.dart';
import 'service_supabase.dart'; // Import service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://xpzslbieloolznmowdax.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwenNsYmllbG9vbHpubW93ZGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNTY3ODUsImV4cCI6MjA2MzczMjc4NX0.kDWu37oK58OQsYldglPcrBYrAxTV7KXvZTJ2qww7ESg',
  );

  // Inisialisasi SupabaseService
  Get.put(SupabaseService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salon Cantik',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
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
            Get.offAll(() => const Login2Screen());
          }
          break;
        case AuthChangeEvent.signedIn:
          Get.offAll(() => const MainScreen());
          break;
        case AuthChangeEvent.signedOut:
          Get.offAll(() => const Login2Screen());
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
        Get.offAll(() => const Login2Screen());
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: screenSize.width * 0.4,
              height: screenSize.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.spa,
                size: screenSize.width * 0.2,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 30),
            // App name
            Text(
              "Salon Cantik",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              "2023",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}