import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/home_screen.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen> {
  int currentStep = 0;
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String? _pickedImageBase64;
  bool _isSubmitting = false;

  @override
  void dispose() {
    shopNameController.dispose();
    productNameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep == 1) {
      if (shopNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Isi nama toko dulu atau tekan Lewati.'),
          ),
        );
        return;
      }
    }
    if (currentStep == 3) {
      if (productNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Isi nama produk dulu atau tekan Lewati.'),
          ),
        );
        return;
      }
    }
    if (currentStep < 4) {
      setState(() {
        currentStep++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void previousStep() {
    if (currentStep > 0 && !_isSubmitting) {
      setState(() {
        currentStep--;
      });
    }
  }

  Future<void> _finishOnboarding({bool skip = false}) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      if (!skip) {
        await _updateStoreProfileIfNeeded();
        await _createFirstProductIfNeeded();
      }
    } catch (_) {}
    if (!mounted) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
      await prefs.setBool('should_show_onboarding_success', true);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _updateStoreProfileIfNeeded() async {
    final name = shopNameController.text.trim();
    if (name.isEmpty) return;
    try {
      final auth = context.read<AuthProvider>();
      final profile = auth.currentUser;
      final wa =
          (profile?['waNumber'] ?? profile?['phone'] ?? '').toString().trim();
      final address = (profile?['address'] ?? '').toString().trim();
      final lat = profile?['latitude']?.toString();
      final lng = profile?['longitude']?.toString();
      if (wa.isEmpty || address.isEmpty) return;
      await ApiService().updateStoreProfile(
        businessName: name,
        waNumber: wa,
        address: address,
        latitude: lat,
        longitude: lng,
      );
      await auth.refreshProfile();
    } catch (_) {}
  }

  Future<void> _createFirstProductIfNeeded() async {
    final productName = productNameController.text.trim();
    if (productName.isEmpty) return;
    final rawPrice = priceController.text;
    final parsed =
        double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    try {
      final Map<String, dynamic> payload = {
        'name': productName,
        'sku': '',
        'sellingPrice': parsed,
        'basePrice': 0,
        'stock': 0,
        'minStock': 5,
        'trackStock': true,
        'category': 'All',
      };
      if (_pickedImageBase64 != null) {
        payload['imageBase64'] = _pickedImageBase64;
      }
      final newProduct = await ApiService().createProduct(payload);
      await DatabaseHelper.instance.insertProduct({
        'id': newProduct['id'],
        'tenantId': newProduct['tenantId'],
        'sku': newProduct['sku'],
        'name': newProduct['name'],
        'costPrice': newProduct['basePrice'] ?? 0,
        'sellingPrice': newProduct['sellingPrice'],
        'trackStock': 1,
        'stock': newProduct['stock'] ?? 0,
        'category': 'All',
        'imageUrl': newProduct['imageUrl'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk pertama berhasil dibuat.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal membuat produk pertama. Bisa ditambah nanti di menu Produk.',
          ),
        ),
      );
    }
  }

  void _skipFlow() {
    _finishOnboarding(skip: true);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
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

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (currentStep == 0) {
      content = buildWelcomeStep();
    } else if (currentStep == 1) {
      content = buildShopNameStep();
    } else if (currentStep == 2) {
      content = buildPhotoStep();
    } else if (currentStep == 3) {
      content = buildFirstProductStep();
    } else {
      content = buildConfirmStep();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Langkah ${currentStep + 1} dari 5'),
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: previousStep,
              )
            : null,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _skipFlow,
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  key: ValueKey(currentStep),
                  width: double.infinity,
                  child: content,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : nextStep,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        currentStep == 4 ? 'Mulai jualan sekarang' : 'Lanjut',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 160,
          child: Lottie.asset('assets/lottie/empty_store.json'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Selamat datang di Rana',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Yuk mulai jualan dalam beberapa langkah singkat.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildShopNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama toko Anda',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: shopNameController,
          decoration: const InputDecoration(
            labelText: 'Nama toko',
            hintText: 'Contoh: Toko Sari Jaya',
          ),
        ),
      ],
    );
  }

  Widget buildFirstProductStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk pertama',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: productNameController,
          decoration: const InputDecoration(
            labelText: 'Nama produk',
            hintText: 'Contoh: Beras 5kg',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Harga (Rp)',
            hintText: 'Contoh: 75000',
          ),
        ),
      ],
    );
  }

  Widget buildConfirmStep() {
    final shopName =
        shopNameController.text.isEmpty ? 'Nama toko' : shopNameController.text;
    final productName = productNameController.text.isEmpty
        ? 'Produk pertama'
        : productNameController.text;
    final priceText =
        priceController.text.isEmpty ? 'Rp 0' : 'Rp ${priceController.text}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cek dulu ya',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront),
            title: Text(shopName),
            subtitle: Text('$productName • $priceText'),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Kalau sudah pas, tekan tombol di bawah.'),
      ],
    );
  }

  Widget buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto produk (opsional)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                  ),
                ),
                child: _pickedImageBytes == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Pilih dari galeri'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Ambil foto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
