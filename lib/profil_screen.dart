import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'login_2_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final List<Color> warnaTema = [
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  final List<String> namaTema = [
    "Biru Cerah",
    "Ungu Cerah",
    "Hijau Cerah",
    "Oranye Cerah",
    "Pink Cerah",
  ];

  int indexWarna = 0;

  @override
  void initState() {
    super.initState();
    _loadTema();
  }

  Future<void> _loadTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      indexWarna = prefs.getInt('indexWarna') ?? 0;
    });
  }

  Future<void> _saveTema(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('indexWarna', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaTema[indexWarna],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.pinkAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kurnia Ayu Anjani',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '230101104 - Sistem Informasi - C',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: indexWarna,
                    items: List.generate(
                      namaTema.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(namaTema[index]),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          indexWarna = value;
                        });
                        _saveTema(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final box = GetStorage();
                  box.remove('username');
                  Get.offAll(() => const Login2Screen());
                },
                icon: const Icon(Icons.logout),
                label: const Text("Keluar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class untuk shared preferences (implementasi sederhana)
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
