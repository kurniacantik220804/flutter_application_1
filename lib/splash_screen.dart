import 'package:flutter/material.dart';
import 'login_2_screen.dart';
import 'main.dart'; // Impor main.dart untuk mengakses MainScreen
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            Text(
              "Salon Cantik",
              style: TextStyle(
                fontSize: 24,
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
