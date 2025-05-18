import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'login_2_screen.dart';
import 'detail_layanan.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart'; // Import the new screen
import 'promo_screen.dart'; // Import the promo screen
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
    Future.delayed(const Duration(seconds: 3), () {
      final box = GetStorage();
      String? username = box.read('username');

      if (username == null) {
        Get.off(() => const Login2Screen());
      } else {
        Get.to(() => const MainScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan MediaQuery untuk mendapatkan ukuran layar
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menggunakan ukuran responsif (70% dari lebar layar)
            Image.asset(
              'assets/logo.png',
              width:
                  screenSize.width * 0.5, // 50% dari lebar layar (lebih kecil)
              fit:
                  BoxFit
                      .contain, // Memastikan gambar sesuai dengan ukuran container
            ),
            const SizedBox(height: 15), // Jarak lebih dekat (sebelumnya 30)
            Text(
              "Salon Cantik",
              style: TextStyle(
                fontSize: 30, // Ukuran font yang lebih besar
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
