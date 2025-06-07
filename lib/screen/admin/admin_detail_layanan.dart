import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/produk_service.dart';

class AdminDetailLayanan extends StatefulWidget {
  final String idProduk;
  final VoidCallback? onPriceUpdated;

  const AdminDetailLayanan({
    super.key,
    required this.idProduk,
    this.onPriceUpdated,
  });

  @override
  State<AdminDetailLayanan> createState() => _AdminDetailLayananState();
}

class _AdminDetailLayananState extends State<AdminDetailLayanan> {
  final ThemeController _themeController = Get.find<ThemeController>();
  final TextEditingController _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Map<String, dynamic>? produkData;
  bool isLoading = true;
  bool isSavingPrice = false;
  bool isEditingPrice = false;

  @override
  void initState() {
    super.initState();
    _loadProdukData();
  }

  Future<void> _loadProdukData() async {
    try {
      print('Loading produk with ID: ${widget.idProduk}');
      
      final data = await ProdukService.getProdukById(widget.idProduk);
      
      print('Produk data received: $data');
      
      if (mounted) {
        setState(() {
          produkData = data;
          if (data != null && data['harga'] != null) {
            _priceController.text = data['harga'].toString();
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadProdukData: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;
    if (produkData == null) return;

    setState(() {
      isSavingPrice = true;
    });

    try {
      final newPrice = int.parse(_priceController.text); // Ubah ke int karena database menggunakan int4
      
      print('Updating price to: $newPrice for ID: ${widget.idProduk}');
      
      // Update harga di database Supabase
      final response = await Supabase.instance.client
          .from('produk')
          .update({'harga': newPrice})
          .eq('id_produk', widget.idProduk) // Pastikan menggunakan id_produk bukan id
          .select();

      print('Update response: $response');

      if (mounted) {
        // Update data lokal
        setState(() {
          produkData!['harga'] = newPrice;
          isEditingPrice = false;
          isSavingPrice = false;
        });

        // Callback untuk refresh parent screen
        if (widget.onPriceUpdated != null) {
          widget.onPriceUpdated!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga berhasil diperbarui!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating price: $e');
      if (mounted) {
        setState(() {
          isSavingPrice = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui harga: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _cancelEditPrice() {
    if (produkData != null && produkData!['harga'] != null) {
      setState(() {
        _priceController.text = produkData!['harga'].toString();
        isEditingPrice = false;
      });
    }
  }

  Widget _buildIconFallback(dynamic colors) {
    IconData icon = Icons.local_offer;
    
    if (produkData != null && produkData!['icon_name'] != null) {
      icon = ProdukService.getIconFromString(produkData!['icon_name']);
    }
        
    return AnimatedThemedContainer(
      padding: const EdgeInsets.all(20),
      withGradient: true,
      child: Icon(
        icon,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Memuat...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (produkData == null) {
      return ThemedScaffold(
        appBar: ThemedAppBar(title: 'Error'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Produk tidak ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.idProduk}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();
        String imagePath = produkData?['image_path'] ?? '';
        String namaProduk = produkData?['nama_produk'] ?? 'Produk Tidak Dikenal';
        String idProduk = produkData?['id_produk'] ?? widget.idProduk;

        return ThemedScaffold(
          appBar: ThemedAppBar(
            title: namaProduk,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imagePath.isNotEmpty
                          ? Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildIconFallback(colors);
                              },
                            )
                          : _buildIconFallback(colors),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Product Info Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              namaProduk,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: $idProduk',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ProdukService.getDefaultDescription(
                          namaProduk,
                          produkData?['deskripsi'],
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Price Management Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Kelola Harga',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (!isEditingPrice && !isSavingPrice)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isEditingPrice = true;
                                });
                              },
                              icon: Icon(
                                Icons.edit,
                                color: colors.primary,
                              ),
                              tooltip: 'Edit Harga',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (!isEditingPrice) ...[
                        // Display current price
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga Saat Ini:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ProdukService.formatHarga(produkData?['harga'] ?? 0),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Price editing form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga Baru:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                enabled: !isSavingPrice,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Masukkan harga baru',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.primary),
                                  ),
                                  filled: true,
                                  fillColor: colors.primary.withOpacity(0.05),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Harga tidak boleh kosong';
                                  }
                                  final numValue = int.tryParse(value);
                                  if (numValue == null) {
                                    return 'Harga harus berupa angka';
                                  }
                                  if (numValue <= 0) {
                                    return 'Harga harus lebih dari 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isSavingPrice ? null : _cancelEditPrice,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Batal'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isSavingPrice ? null : _updatePrice,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: isSavingPrice
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text('Simpan'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Info Section
                ThemedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Tambahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Kategori', produkData?['kategori'] ?? 'Layanan'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Status', 'Aktif'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Terakhir Diperbarui', 
                        DateTime.now().toString().split('.')[0]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}