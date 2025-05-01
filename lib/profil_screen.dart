import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Load tema dari SharedPreferences
  Future<void> _loadTema() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      indexWarna = prefs.getInt('indexWarna') ?? 0;
    });
  }

  // Simpan tema ke SharedPreferences
  Future<void> _saveTema(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('indexWarna', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaTema[indexWarna],
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://instagram.fsoc16-1.fna.fbcdn.net/v/t51.2885-19/489036971_1562684597753907_6792625160551954835_n.jpg?_nc_ht=instagram.fsoc16-1.fna.fbcdn.net&_nc_cat=103&_nc_oc=Q6cZ2QHeqb2OBcReSWsRnX75HDaJO7Sa16qWBvA99-niohEy_Qk8FTS7Qeu115VKgD09URY&_nc_ohc=KSqiRssqDy0Q7kNvwGULtm4&_nc_gid=CtaPXG7M8eEnwHCkI-6wGw&edm=ALGbJPMBAAAA&ccb=7-5&oh=00_AfFRlDTN8oC2LC7opp7Owpkv7EEUMh1ILBeeaXrq5C5YpA&oe=6815889B&_nc_sid=7d3ac5',
              ), // contoh foto random
            ),
            const SizedBox(height: 16),
            // Nama
            const Text(
              'Nama User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Bio
            const Text(
              'Bio singkat tentang user di sini...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            // Dropdown pilih tema
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
            // Tombol Logout / Keluar
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // kembali ke halaman login
              },
              icon: const Icon(Icons.logout),
              label: const Text("Keluar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
