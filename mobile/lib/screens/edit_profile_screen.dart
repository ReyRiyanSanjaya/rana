import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _waNumberController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  String? _latitude;
  String? _longitude;

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.initialData['businessName'] ?? '');
    _waNumberController = TextEditingController(
        text: widget.initialData['waNumber'] ??
            widget.initialData['phone'] ??
            '');
    _addressController =
        TextEditingController(text: widget.initialData['address'] ?? '');

    // Initialize Lat/Long if available
    _latitude = widget.initialData['latitude']?.toString();
    _longitude = widget.initialData['longitude']?.toString();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _waNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen');
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.postalCode
          ]
              .where((element) => element != null && element.isNotEmpty)
              .join(', ');

          if (address.isNotEmpty) {
            _addressController.text = address;
          }
        }
      } catch (e) {
        // Ignore geocoding errors, just keep coordinates
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lokasi berhasil diperbarui'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengambil lokasi: $e'),
              backgroundColor: const Color(0xFFE07A5F)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Password',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Lama'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                validator: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password Baru'),
                validator: (v) =>
                    v != newPassController.text ? 'Password tidak sama' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context); // Close dialog first
                setState(() => _isLoading = true);
                try {
                  await ApiService().changePassword(
                    oldPassController.text,
                    newPassController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password berhasil diubah'),
                          backgroundColor: const Color(0xFFE07A5F)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07A5F)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().updateStoreProfile(
        businessName: _businessNameController.text.trim(),
        waNumber: _waNumberController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        // Refresh global state
        await Provider.of<AuthProvider>(context, listen: false)
            .refreshProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF81B29A),
          ),
        );
        Navigator.pop(context, true); // Return success result
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Color(0xFFE07A5F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Edit Profil Toko',
            style: GoogleFonts.outfit(
                color: const Color(0xFFE07A5F), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFE07A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Toko'),
              _buildTextField(
                controller: _businessNameController,
                hint: 'Contoh: Toko Berkah',
                icon: Icons.store_mall_directory_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Nama toko tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Nomor WhatsApp'),
              _buildTextField(
                controller: _waNumberController,
                hint: 'Contoh: 081234567890',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? 'Nomor WA tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Alamat Lengkap'),
              _buildTextField(
                controller: _addressController,
                hint: 'Contoh: Jl. Sudirman No. 123, Jakarta',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (v) =>
                    v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Ambil Lokasi Saat Ini'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE07A5F),
                  side: const BorderSide(color: Color(0xFFE07A5F)),
                ),
              ),
              if (_latitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Koordinat: $_latitude, $_longitude',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Keamanan Akun',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Ubah password akun anda',
                    style: GoogleFonts.outfit(color: Colors.grey)),
                trailing: TextButton(
                  onPressed: _showChangePasswordDialog,
                  child: const Text('Ubah Password'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE07A5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE07A5F)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE07A5F)),
        ),
      ),
    );
  }
}
