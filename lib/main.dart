import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'login_2_screen.dart';
import 'detail_layanan.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';
import 'promo_screen.dart';
import 'booking_screen.dart';
import 'main_screen.dart';

// Centralized SharedPreferences class - can be moved to a separate utilities file
class SharedPreferences {
  static final SharedPreferences _instance = SharedPreferences._internal();

  static Future<SharedPreferences> getInstance() async {
    return _instance;
  }

  SharedPreferences._internal();

  final Map<String, dynamic> _data = {};

  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  int? getInt(String key) {
    return _data[key];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
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
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    Future.delayed(const Duration(seconds: 3), () {
      final box = GetStorage();
      bool? isLoggedIn = box.read('isLoggedIn');
      String? username = box.read('username');

      if (isLoggedIn == true && username != null) {
        // User is logged in, go to main screen
        Get.offAll(() => const MainScreen());
      } else {
        // User is not logged in, go to login screen
        Get.offAll(() => const Login2Screen());
      }
    });
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
