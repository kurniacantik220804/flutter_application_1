import 'package:flutter/material.dart';
import 'profil_screen.dart';

// halaman Login
class Login2Screen extends StatefulWidget {
  const Login2Screen({super.key});

  @override
  State<Login2Screen> createState() => _Login2ScreenState();
}

class _Login2ScreenState extends State<Login2Screen> {
  bool passwordTampil = true;

  // Tambahkan controller
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  menampilkanPassword() {
    setState(() {
      passwordTampil = !passwordTampil;
    });
  }

  // Fungsi untuk pindah ke halaman Profile
  void login() {
    if (usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilScreen()),
      );
    } else {
      // Bisa tambahkan snack bar jika ingin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username dan Password harus diisi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: passwordTampil ? Colors.yellow : Colors.green,
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Supaya ada jarak
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Tengah layar
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                hintText: "Masukkan Username",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: passwordTampil,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Masukkan Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: menampilkanPassword,
                  icon:
                      passwordTampil
                          ? Icon(Icons.visibility_off)
                          : Icon(Icons.visibility),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: menampilkanPassword,
              child: Text("Tampil Password"),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: login, child: Text("Login")),
          ],
        ),
      ),
    );
  }
}
