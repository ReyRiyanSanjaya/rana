import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/constants.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // [NEW] Optional product for editing
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController(); 
  final _sellPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  List<String> _existingCategories = []; // [NEW] Dynamic Categories
  String _selectedCategory = 'Beverage'; 
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String? _pickedImageBase64;
  String? _existingImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadCategories(); // [NEW] Load categories
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p['name'];
      _skuCtrl.text = p['sku'] ?? '';
      _sellPriceCtrl.text = p['sellingPrice'].toString();
      _costPriceCtrl.text = (p['costPrice'] ?? 0).toString();
      _selectedCategory = p['category'] ?? 'Beverage';
      _existingImageUrl = p['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageBase64 = 'data:image/jpeg;base64,$b64';
    });
  }

  // [NEW] Fetch unique categories from DB
  Future<void> _loadCategories() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    final Set<String> cats = {};
    for (var p in products) {
      if (p['category'] != null && p['category'].toString().isNotEmpty) {
        cats.add(p['category']);
      }
    }
    // Add default if empty
    if (cats.isEmpty) cats.addAll(['Makanan', 'Minuman', 'Sembako']);
    
    if (mounted) setState(() => _existingCategories = cats.toList());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      double sell = double.tryParse(_sellPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      double cost = double.tryParse(_costPriceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

      if (widget.product == null) {
        // --- CREATE MODE ---
        final newProduct = await ApiService().createProduct({
          'name': _nameCtrl.text,
          'sku': _skuCtrl.text,
          'sellingPrice': sell,
          'basePrice': cost,
          'stock': 0, 
          'minStock': 5, 
          'trackStock': true,
          'category': _selectedCategory,
          if (_pickedImageBase64 != null) 'imageBase64': _pickedImageBase64
        });

        await DatabaseHelper.instance.insertProduct({
          'id': newProduct['id'],
          'tenantId': newProduct['tenantId'],
          'sku': newProduct['sku'],
          'name': newProduct['name'],
          'costPrice': newProduct['basePrice'] ?? cost,
          'sellingPrice': newProduct['sellingPrice'],
          'trackStock': 1,
          'stock': 0,
          'category': _selectedCategory,
          'imageUrl': newProduct['imageUrl']
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk Berhasil Ditambahkan!')));

      } else {
        // --- EDIT MODE ---
        final id = widget.product!['id'];
        final updateData = {
          'name': _nameCtrl.text,
          'sku': _skuCtrl.text,
          'sellingPrice': sell,
          'basePrice': cost,
          'category': _selectedCategory,
          if (_pickedImageBase64 != null) 'imageBase64': _pickedImageBase64
        };
        
        final updated = await ApiService().updateProduct(id, updateData);
        
        // Update Local DB
        await DatabaseHelper.instance.updateProductDetails(id, {
          'name': _nameCtrl.text,
          'sku': _skuCtrl.text,
          'sellingPrice': sell,
          'costPrice': updated['basePrice'] ?? cost,
          'category': _selectedCategory,
          'imageUrl': updated['imageUrl']
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk Berhasil Diupdate!')));
      }

      if (mounted) Navigator.pop(context, true); 
      
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message ?? 'Terjadi Kesalahan Server';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $msg'), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = _existingImageUrl;
    final existingImageFullUrl = existingImage == null
        ? null
        : (existingImage.toString().startsWith('http')
            ? existingImage.toString()
            : '${AppConstants.baseUrl}${existingImage.toString()}');

    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Tambah Produk Baru' : 'Edit Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _pickedImageBytes != null
                            ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                            : (existingImageFullUrl != null && existingImageFullUrl.isNotEmpty
                                ? Image.network(existingImageFullUrl, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: Text(widget.product == null ? 'Pilih Gambar Produk' : 'Ganti Gambar Produk'),
                          ),
                        ),
                        if (_pickedImageBytes != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() {
                                      _pickedImageBytes = null;
                                      _pickedImageBase64 = null;
                                    }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ]
                      ],
                    ),
                    if (kIsWeb)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Jika di web, gambar akan diupload sebagai base64.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuCtrl,
                decoration: const InputDecoration(labelText: 'Kode Barang / SKU', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // [NEW] Autocomplete for Category
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<String>(
                    initialValue: TextEditingValue(text: _selectedCategory),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _existingCategories.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() => _selectedCategory = selection);
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Initial check to ensure controller is in sync if state changed externally
                      if (textEditingController.text != _selectedCategory && _selectedCategory.isNotEmpty && textEditingController.text.isEmpty) {
                          textEditingController.text = _selectedCategory;
                      }

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                           labelText: 'Kategori', 
                           border: OutlineInputBorder(), 
                           prefixIcon: Icon(Icons.category),
                           hintText: 'Pilih atau Ketik Kategori Baru'
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        onChanged: (val) => _selectedCategory = val, // Update state on typing
                      );
                    },
                  );
                }
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Modal (HPP)', border: OutlineInputBorder(), prefixText: 'Rp '),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga Jual', border: OutlineInputBorder(), prefixText: 'Rp '),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(widget.product == null ? Icons.save : Icons.update),
                  onPressed: _isLoading ? null : _submit,
                  label: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.product == null ? 'Simpan Produk' : 'Update Produk'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
