import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _waCtrl = TextEditingController(); // [NEW]
  String? _category; // [NEW]
  
  bool _isLoading = false;
  String _statusMessage = 'Daftar Sekarang';

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
       _isLoading = true;
       _statusMessage = 'Mendeteksi Lokasi...';
    });

    try {
      // ... (Location Logic skipped for brevity in diff, exists in file) ...
      // 1. Silent Location Capture
      Position? position;
      String? address;
      
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            if (position != null) {
               List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
               if (placemarks.isNotEmpty) {
                 final place = placemarks.first;
                 address = '${place.street}, ${place.subLocality}, ${place.locality}';
               }
            }
        }
      } catch (locErr) {
        // Silent fail
      }

      setState(() => _statusMessage = 'Mendaftarkan Akun...');

      // 2. Call API
      await ApiService().register(
        businessName: _nameCtrl.text, 
        email: _emailCtrl.text, 
        password: _passCtrl.text,
        waNumber: _waCtrl.text,
        category: _category!, // [NEW] Guaranteed by validator
        lat: position?.latitude,
        long: position?.longitude,
        address: address
      );
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')));
        Navigator.pop(context); // Go back to Login
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.store_mall_directory, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Bisnis / Toko', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // [NEW] Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori Usaha', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Apotik', child: Text('Apotik / Kesehatan', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Kedai Makanan', child: Text('Kedai Makanan / Resto', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Outlet Ponsel', child: Text('Outlet Ponsel / Pulsa', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Toko Baju', child: Text('Toko Baju / Fashion', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Kelontong', child: Text('Toko Kelontong / Sembako', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ], 
                isExpanded: true,
                onChanged: (val) => setState(() => _category = val),
                validator: (v) => v == null ? 'Pilih Kategori' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp Owner', border: OutlineInputBorder(), hintText: '0812...'),
                validator: (v) => v!.length < 9 ? 'Nomor tidak valid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) => v!.contains('@') ? null : 'Email tidak valid',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                 validator: (v) => v!.length < 6 ? 'Min 6 karakter' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi akan menyimpan lokasi toko Anda secara otomatis saat mendaftar.',
                style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading 
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [ const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), const SizedBox(width: 10), Text(_statusMessage)]) 
                    : const Text('DAFTAR SEKARANG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
