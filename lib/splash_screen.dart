import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_screen.dart';
import 'login_2_screen.dart';
import 'main.dart';
import 'main_screen.dart'; // Impor main.dart untuk mengakses MainScreen
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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
        Get.off(
          () => const MainScreen(),
        ); // Arahkan ke MainScreen yang memiliki animated bottom navigation
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
            // Menggunakan ukuran responsif (50% dari lebar layar)
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
