import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BeautyTipsScreen extends StatelessWidget {
  const BeautyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips Kecantikan'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildTipsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent, Colors.pink[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, size: 40, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Kecantikan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Panduan lengkap perawatan kecantikan dari ahli',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsGrid() {
    final List<TipsData> tipsList = [
      TipsData(
        title: 'Rambut Sehat',
        subtitle: 'Konsumsi vitamin untuk rambut',
        icon: Icons.favorite,
        color: Colors.red[50]!,
        iconColor: Colors.red,
        content: '''
Tips untuk menjaga kesehatan rambut:

• Konsumsi vitamin E, biotin, dan omega-3
• Pijat kulit kepala secara teratur
• Gunakan masker rambut alami 2x seminggu
• Hindari penggunaan alat styling berlebihan
• Gunakan kondisioner setiap keramas
• Potong ujung rambut setiap 6-8 minggu
• Minum air putih minimal 8 gelas per hari
• Gunakan sarung bantal sutra atau satin

Bahan alami untuk masker rambut:
- Minyak kelapa + madu
- Alpukat + minyak zaitun  
- Telur + yogurt
- Lidah buaya + minyak argan
        ''',
      ),
      TipsData(
        title: 'Kulit Wajah',
        subtitle: 'Gunakan tabir surya setiap hari',
        icon: Icons.wb_sunny,
        color: Colors.orange[50]!,
        iconColor: Colors.orange,
        content: '''
Rutina perawatan wajah harian:

Pagi Hari:
• Cuci muka dengan cleanser lembut
• Gunakan toner untuk menyeimbangkan pH
• Aplikasikan serum vitamin C
• Pakai pelembab sesuai jenis kulit
• Wajib gunakan sunscreen SPF 30+

Malam Hari:
• Double cleansing (micellar water + cleanser)
• Gunakan toner
• Aplikasikan serum retinol (2-3x seminggu)
• Pakai pelembab malam yang lebih rich
• Gunakan sleeping mask 1-2x seminggu

Tips tambahan:
- Eksfoliasi wajah 1-2x seminggu
- Gunakan face mask sesuai kebutuhan kulit
- Hindari menyentuh wajah terlalu sering
- Ganti sarung bantal secara rutin
        ''',
      ),
      TipsData(
        title: 'Makeup Natural',
        subtitle: 'Gunakan warna alami',
        icon: Icons.face,
        color: Colors.pink[50]!,
        iconColor: Colors.pink,
        content: '''
Panduan makeup natural sehari-hari:

Base Makeup:
• Gunakan primer untuk hasil tahan lama
• Pilih foundation dengan coverage ringan
• Concealer hanya di area yang diperlukan
• Set dengan bedak translucent tipis

Mata:
• Eyeshadow netral (coklat muda, krem)
• Maskara 1-2 lapis untuk kesan natural
• Alis dirapikan sesuai bentuk alami
• Highlighter tipis di inner corner mata

Pipi & Bibir:
• Blush on warna peach atau pink muda
• Lip tint atau lip balm berwarna
• Highlighter tipis di tulang pipi

Tips aplikasi:
- Gunakan beauty blender basah untuk blend
- Build up produk secara bertahap
- Selalu remove makeup sebelum tidur
- Investasi pada brush berkualitas baik
        ''',
      ),
      TipsData(
        title: 'Perawatan Kuku',
        subtitle: 'Kuku sehat dan terawat',
        icon: Icons.gesture,
        color: Colors.purple[50]!,
        iconColor: Colors.purple,
        content: '''
Cara merawat kuku yang benar:

Perawatan Dasar:
• Potong kuku secara teratur
• Kikir dengan gerakan satu arah
• Push back kutikula dengan lembut
• Gunakan base coat sebelum cat kuku
• Aplikasikan cuticle oil setiap hari

Hand Care:
• Gunakan hand cream setelah cuci tangan
• Lakukan scrub tangan 1x seminggu
• Gunakan sarung tangan saat cleaning
• Pijat tangan untuk melancarkan sirkulasi

Nail Art Tips:
- Tunggu setiap layer kering sempurna
- Gunakan top coat untuk durability
- Variasikan warna sesuai outfit
- Bersihkan nail art tools setelah digunakan

Tanda kuku sehat:
✓ Warna pink muda alami
✓ Permukaan halus dan rata
✓ Tidak mudah patah atau mengelupas
        ''',
      ),
      TipsData(
        title: 'Body Care',
        subtitle: 'Kulit tubuh lembut dan sehat',
        icon: Icons.spa_outlined,
        color: Colors.green[50]!,
        iconColor: Colors.green,
        content: '''
Rutina perawatan tubuh:

Daily Routine:
• Mandi dengan air suam-suam kuku
• Gunakan body wash yang melembabkan
• Pat dry dengan handuk, jangan gosok keras
• Aplikasikan body lotion saat kulit masih lembab
• Fokus pada area kering (siku, lutut, tumit)

Weekly Treatment:
• Body scrub 1-2x seminggu
• Masker tubuh dengan bahan alami
• Pijat dengan body oil untuk relaksasi

Bahan alami untuk body scrub:
- Gula + minyak kelapa
- Garam laut + olive oil
- Kopi + madu
- Oatmeal + susu

Tips khusus:
• Gunakan lotion dengan SPF untuk aktivitas outdoor
• Pilih pakaian berbahan breathable
• Minum air putih yang cukup
• Konsumsi makanan kaya antioksidan
        ''',
      ),
      TipsData(
        title: 'Diet Kecantikan',
        subtitle: 'Nutrisi untuk kecantikan dari dalam',
        icon: Icons.restaurant,
        color: Colors.teal[50]!,
        iconColor: Colors.teal,
        content: '''
Makanan untuk kecantikan alami:

Untuk Kulit Glowing:
• Sayuran hijau (bayam, kale, brokoli)
• Buah beri (blueberry, strawberry)
• Ikan salmon kaya omega-3
• Kacang-kacangan dan biji-bijian
• Alpukat untuk vitamin E

Untuk Rambut Berkilau:
• Telur (protein dan biotin)
• Ubi jalar (beta karoten)
• Greek yogurt (protein dan probiotik)
• Oyster (zinc untuk pertumbuhan rambut)

Minuman Beauty:
• Green tea (antioksidan tinggi)
• Air lemon hangat di pagi hari
• Jus wortel dan jeruk
• Infused water mentimun dan mint
• Bone broth untuk kolagen alami

Yang harus dihindari:
✗ Gula berlebihan
✗ Makanan olahan
✗ Alkohol berlebihan
✗ Makanan tinggi garam
        ''',
      ),
    ];

    return Column(
      children: tipsList.map((tips) => _buildTipsCard(tips)).toList(),
    );
  }

  Widget _buildTipsCard(TipsData tips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tips.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tips.icon, color: tips.iconColor, size: 24),
        ),
        title: Text(
          tips.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          tips.subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tips.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tips.content.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialShareButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.blue,
                      onPressed: () => _shareGeneral(tips),
                    ),
                    _buildSocialShareButton(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onPressed: () => _shareToFacebook(tips),
                    ),
                    _buildSocialShareButton(
                      icon: Icons.message,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onPressed: () => _shareToWhatsApp(tips),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialShareButton(
                      icon: Icons.camera_alt,
                      label: 'Instagram',
                      color: const Color(0xFFE4405F),
                      onPressed: () => _shareToInstagram(tips),
                    ),
                    _buildSocialShareButton(
                      icon: Icons.flutter_dash,
                      label: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      onPressed: () => _shareToTwitter(tips),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  // General share function using share_plus
  void _shareGeneral(TipsData tips) {
    final String shareText = '''
🌟 Tips ${tips.title} 🌟

${tips.subtitle}

${tips.content}

#TipsKecantikan #BeautyCare #SelfCare
    ''';

    Share.share(shareText, subject: 'Tips Kecantikan: ${tips.title}');
  }

  // Share to Facebook
  void _shareToFacebook(TipsData tips) async {
    final String text = '''
🌟 Tips ${tips.title} 🌟

${tips.subtitle}

${tips.content}

#TipsKecantikan #BeautyCare #SelfCare
    ''';

    final String url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://example.com')}&quote=${Uri.encodeComponent(text)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback to general share
      _shareGeneral(tips);
    }
  }

  // Share to WhatsApp
  void _shareToWhatsApp(TipsData tips) async {
    final String text = '''
🌟 *Tips ${tips.title}* 🌟

_${tips.subtitle}_

${tips.content}

#TipsKecantikan #BeautyCare #SelfCare
    ''';

    final String url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback to general share
      _shareGeneral(tips);
    }
  }

  // Share to Instagram (will open Instagram app)
  void _shareToInstagram(TipsData tips) async {
    final String text = '''
🌟 Tips ${tips.title} 🌟

${tips.subtitle}

${tips.content}

#TipsKecantikan #BeautyCare #SelfCare #Beauty #Skincare
    ''';

    // Instagram doesn't support direct text sharing via URL, so we use general share
    // This will show Instagram as an option if installed
    Share.share(text, subject: 'Tips Kecantikan: ${tips.title}');
  }

  // Share to Twitter
  void _shareToTwitter(TipsData tips) async {
    final String text = '''
🌟 Tips ${tips.title} 🌟

${tips.subtitle}

#TipsKecantikan #BeautyCare #SelfCare
    ''';

    final String url =
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Fallback to general share
      _shareGeneral(tips);
    }
  }

  // Save bookmark function (placeholder)
  void _saveBookmark(TipsData tips) {
    // TODO: Implement actual bookmark saving to local storage or database
    // For now, just show a snackbar
    // You can implement this with GetStorage, SharedPreferences, or SQLite

    // Example implementation would be:
    // final storage = GetStorage();
    // List<String> bookmarks = storage.read('bookmarks') ?? [];
    // bookmarks.add(tips.title);
    // storage.write('bookmarks', bookmarks);

    print('Bookmark saved: ${tips.title}');
  }
}

class TipsData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String content;

  TipsData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.content,
  });
}
