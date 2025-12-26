import 'package:flutter/material.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/constants.dart';
import 'package:dio/dio.dart';

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
    }
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
          'category': _selectedCategory
        });

        await DatabaseHelper.instance.insertProduct({
          'id': newProduct['id'],
          'tenantId': newProduct['tenantId'],
          'sku': newProduct['sku'],
          'name': newProduct['name'],
          'costPrice': newProduct['basePrice'] ?? 0, 
          'sellingPrice': newProduct['sellingPrice'],
          'trackStock': 1,
          'stock': 0,
          'category': _selectedCategory 
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
          'category': _selectedCategory
        };
        
        await ApiService().updateProduct(id, updateData);
        
        // Update Local DB
        await DatabaseHelper.instance.updateProductDetails(id, {
          'name': _nameCtrl.text,
          'sku': _skuCtrl.text,
          'sellingPrice': sell,
          'costPrice': cost,
          'category': _selectedCategory
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Tambah Produk Baru' : 'Edit Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
