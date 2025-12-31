import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  String? _category;
  
  bool _isLoading = false;
  String _statusMessage = 'Daftar Sekarang';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String? _pickedImageBase64;
  final MapController _mapController = MapController();
  LatLng? _locationPoint;
  String? _locationAddress;
  bool _isLocationLoading = true;
  bool _isLocationResolving = false;
  bool _isLocationVerified = false;
  Timer? _locationDebounce;

  @override
  void initState() {
    super.initState();
    _initDefaultLocation();
  }

  Future<void> _showErrorDialog(String message) async {
    final clean = message.trim().isEmpty ? 'Terjadi kesalahan' : message.trim();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrasi Gagal'),
        content: Text(clean),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _errorText(Object e) {
    var msg = e.toString().trim();
    msg = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
    msg = msg.replaceFirst(RegExp(r'^Registration Failed:\s*'), '');
    msg = msg.replaceFirst(RegExp(r'^Registration Failed:\s*Exception:\s*'), '');
    msg = msg.trim();
    return msg.isEmpty ? 'Terjadi kesalahan' : msg;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _waCtrl.dispose();
    _locationDebounce?.cancel();
    super.dispose();
  }

  bool _isStrongPassword(String value) {
    if (value.length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    return hasLetter && hasNumber;
  }

  Future<void> _pickOutletPhoto() async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final nameParts = xfile.name.split('.');
    final ext = (nameParts.length > 1 ? nameParts.last : 'jpg').toLowerCase();
    final safeExt = RegExp(r'^[a-z0-9]+$').hasMatch(ext) ? ext : 'jpg';
    final mime = safeExt == 'png' ? 'image/png' : 'image/jpeg';
    final b64 = base64Encode(bytes);
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageBase64 = 'data:$mime;base64,$b64';
    });
  }

  Future<void> _initDefaultLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _isLocationVerified = false;
    });

    LatLng center = const LatLng(-6.200000, 106.816666);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        center = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _locationPoint = center;
      _isLocationLoading = false;
    });

    try {
      _mapController.move(center, 16);
    } catch (_) {}

    _reverseGeocode(center);
  }

  String _formatPlacemark(Placemark p) {
    final parts = <String?>[
      p.street,
      p.subLocality,
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  Future<void> _reverseGeocode(LatLng p) async {
    if (!mounted) return;
    setState(() => _isLocationResolving = true);
    String? addr;
    try {
      final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isNotEmpty) {
        addr = _formatPlacemark(placemarks.first);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _locationAddress = (addr ?? '').trim().isEmpty ? null : addr!.trim();
      _isLocationResolving = false;
    });
  }

  void _setLocationPoint(LatLng p) {
    setState(() {
      _locationPoint = p;
      _isLocationVerified = false;
    });
    _locationDebounce?.cancel();
    _locationDebounce = Timer(const Duration(milliseconds: 450), () {
      _reverseGeocode(p);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locationPoint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi belum siap. Coba lagi.')),
        );
      }
      return;
    }
    if (!_isLocationVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan verifikasi lokasi di peta terlebih dahulu.')),
        );
      }
      return;
    }
    
    setState(() {
       _isLoading = true;
       _statusMessage = 'Mendaftarkan Akun...';
    });

    try {
      final p = _locationPoint!;

      // 2. Call API
      await ApiService().register(
        businessName: _nameCtrl.text, 
        ownerName: _ownerCtrl.text,
        email: _emailCtrl.text, 
        password: _passCtrl.text,
        waNumber: _waCtrl.text,
        category: _category!, // [NEW] Guaranteed by validator
        storeImageBase64: _pickedImageBase64,
        lat: p.latitude,
        long: p.longitude,
        address: _locationAddress
      );
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')));
        Navigator.pop(context); // Go back to Login
      }
    } catch (e) {
      await _showErrorDialog(_errorText(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Daftar Sekarang';
        });
      }
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
              TextFormField(
                controller: _ownerCtrl,
                decoration: const InputDecoration(labelText: 'Nama Pemilik', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
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
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nomor tidak boleh kosong';
                  if (v.length < 9) return 'Nomor terlalu pendek';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Hanya angka yang diperbolehkan';
                  return null;
                },
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
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Wajib diisi';
                  if (!_isStrongPassword(val)) return 'Min 8 karakter, huruf & angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Ulangi Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Wajib diisi';
                  if (val != _passCtrl.text) return 'Password tidak sama';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickOutletPhoto,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _pickedImageBytes == null
                            ? const Icon(Icons.store, color: Colors.grey)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                              ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Tambah foto outlet (opsional)'),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lokasi Toko',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: (_isLocationLoading || _isLocationResolving)
                          ? null
                          : _initDefaultLocation,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh lokasi',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLocationLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _locationPoint!,
                                initialZoom: 16,
                                onTap: (tapPosition, latLng) => _setLocationPoint(latLng),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.rana_merchant',
                                ),
                                DragMarkers(
                                  markers: [
                                    DragMarker(
                                      key: const ValueKey('store_pin_inline'),
                                      point: _locationPoint!,
                                      size: const Size.square(54),
                                      offset: const Offset(0, -24),
                                      builder: (context, point, isDragging) => const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 54,
                                      ),
                                      onDragEnd: (details, latLng) => _setLocationPoint(latLng),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: (_isLocationLoading || _isLocationResolving)
                                      ? null
                                      : _initDefaultLocation,
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(Icons.my_location, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLocationResolving
                                          ? 'Mengambil alamat...'
                                          : (_locationAddress ?? 'Geser pin untuk menentukan lokasi'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: FilledButton(
                                        onPressed: _isLocationResolving
                                            ? null
                                            : () {
                                                setState(() => _isLocationVerified = true);
                                              },
                                        child: Text(_isLocationVerified ? 'Lokasi Terverifikasi' : 'Verifikasi Lokasi'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Merchant wajib memastikan pin sudah sesuai sebelum daftar.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
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
