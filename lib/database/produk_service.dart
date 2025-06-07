import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukService {
  // Method yang sudah ada (contoh)
  static Future<List<Map<String, dynamic>>> getAllProduk() async {
    try {
      final response = await Supabase.instance.client
          .from('produk')
          .select('*')
          .order('nama_produk');
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error in getAllProduk: $e');
      throw Exception('Gagal memuat data produk: $e');
    }
  }

  // DIPERBAIKI - getProdukById untuk detail produk
  static Future<Map<String, dynamic>?> getProdukById(String idProduk) async {
    try {
      print('Fetching produk with ID: $idProduk');
      
      final response = await Supabase.instance.client
          .from('produk')
          .select('*')
          .eq('id_produk', idProduk) // Pastikan menggunakan id_produk
          .maybeSingle(); // Gunakan maybeSingle() untuk menghindari error jika tidak ditemukan
      
      print('Database response: $response');
      
      if (response != null) {
        return response;
      } else {
        throw Exception('Produk dengan ID $idProduk tidak ditemukan');
      }
    } catch (e) {
      print('Error in getProdukById: $e');
      if (e.toString().contains('PGRST116')) {
        throw Exception('Produk dengan ID $idProduk tidak ditemukan');
      }
      throw Exception('Gagal memuat data produk: $e');
    }
  }

  // DIPERBAIKI - updateHarga untuk update harga
  static Future<bool> updateHarga(String idProduk, int hargaBaru) async {
    try {
      print('Updating harga for ID: $idProduk to $hargaBaru');
      
      final response = await Supabase.instance.client
          .from('produk')
          .update({'harga': hargaBaru})
          .eq('id_produk', idProduk) // Pastikan menggunakan id_produk
          .select();
      
      print('Update response: $response');
      
      if (response.isNotEmpty) {
        return true;
      } else {
        throw Exception('Tidak ada data yang diperbarui');
      }
    } catch (e) {
      print('Error updating harga: $e');
      throw Exception('Gagal memperbarui harga: $e');
    }
  }

  // TAMBAHAN - Method untuk test update dengan debug
  static Future<bool> testUpdateHarga(String idProduk, int hargaBaru) async {
    try {
      print('=== TEST UPDATE HARGA ===');
      print('ID Produk: $idProduk');
      print('Harga Baru: $hargaBaru');
      
      // Cek dulu apakah produk ada
      final existingData = await Supabase.instance.client
          .from('produk')
          .select('*')
          .eq('id_produk', idProduk)
          .maybeSingle();
      
      print('Data yang ada: $existingData');
      
      if (existingData == null) {
        throw Exception('Produk dengan ID $idProduk tidak ditemukan');
      }
      
      // Lakukan update
      final response = await Supabase.instance.client
          .from('produk')
          .update({'harga': hargaBaru})
          .eq('id_produk', idProduk)
          .select();
      
      print('Response update: $response');
      print('=== END TEST ===');
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error in testUpdateHarga: $e');
      throw Exception('Test update gagal: $e');
    }
  }

  // TAMBAHAN - test koneksi database
  static Future<bool> testDatabaseConnection() async {
    try {
      final response = await Supabase.instance.client
          .from('produk')
          .select('count')
          .limit(1);
      
      print('Database connection test successful: $response');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // DIPERBAIKI - Method untuk format harga (disesuaikan dengan int)
  static String formatHarga(dynamic harga) {
    if (harga == null) return 'Rp 0';
    
    try {
      final numHarga = int.parse(harga.toString());
      return 'Rp ${numHarga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';
    } catch (e) {
      return 'Rp 0';
    }
  }

  // Method untuk get icon (mungkin sudah ada)
  static IconData getIconFromString(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.local_offer;
    }
    
    switch (iconName.toLowerCase()) {
      case 'cut':
      case 'potong':
        return Icons.content_cut;
      case 'face':
      case 'wajah':
        return Icons.face;
      case 'brush':
      case 'makeup':
        return Icons.brush;
      case 'spa':
      case 'perawatan':
        return Icons.spa;
      default:
        return Icons.local_offer;
    }
  }

  // Method untuk get default description (mungkin sudah ada)
  static String getDefaultDescription(String namaProduk, String? existingDesc) {
    if (existingDesc != null && existingDesc.isNotEmpty) {
      return existingDesc;
    }
    
    // Default description berdasarkan nama produk
    switch (namaProduk.toLowerCase()) {
      case 'potong rambut':
        return 'Layanan potong rambut profesional dengan gaya terkini sesuai bentuk wajah Anda.';
      case 'perawatan rambut':
        return 'Perawatan rambut lengkap untuk menjaga kesehatan dan kilau rambut Anda.';
      case 'perawatan wajah':
        return 'Treatment wajah profesional untuk menjaga kesehatan dan kecantikan kulit wajah.';
      case 'tata rias':
        return 'Layanan makeup profesional untuk berbagai acara dan kebutuhan Anda.';
      default:
        return 'Layanan kecantikan berkualitas tinggi dengan standar profesional.';
    }
  }

  // TAMBAHAN - Method untuk debug database structure
  static Future<void> debugDatabaseStructure() async {
    try {
      print('=== DEBUG DATABASE STRUCTURE ===');
      
      // Ambil semua data untuk melihat struktur
      final allData = await Supabase.instance.client
          .from('produk')
          .select('*')
          .limit(1);
      
      if (allData.isNotEmpty) {
        print('Struktur tabel:');
        allData.first.keys.forEach((key) {
          print('- $key: ${allData.first[key].runtimeType}');
        });
      }
      
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debug: $e');
    }
  }
}