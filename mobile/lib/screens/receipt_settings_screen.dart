import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  bool _showLogo = true;
  String _paperSize = '58mm'; // 58mm or 80mm
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _headerController.text = prefs.getString('receipt_header') ?? '';
      _footerController.text = prefs.getString('receipt_footer') ?? 'Terima Kasih atas Kunjungan Anda';
      _showLogo = prefs.getBool('receipt_show_logo') ?? true;
      _paperSize = prefs.getString('receipt_paper_size') ?? '58mm';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receipt_header', _headerController.text);
    await prefs.setString('receipt_footer', _footerController.text);
    await prefs.setBool('receipt_show_logo', _showLogo);
    await prefs.setString('receipt_paper_size', _paperSize);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan Struk Disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Pengaturan Struk',
            style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Tampilan Struk'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Tampilkan Logo Toko',
                          subtitle: 'Cetak logo di bagian atas struk',
                          value: _showLogo,
                          onChanged: (val) => setState(() => _showLogo = val),
                        ),
                        const Divider(height: 1),
                        _buildDropdownTile(
                          title: 'Ukuran Kertas',
                          value: _paperSize,
                          items: ['58mm', '80mm'],
                          onChanged: (val) =>
                              setState(() => _paperSize = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Konten Teks'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _headerController,
                          label: 'Header Struk (Opsional)',
                          hint: 'Contoh: Selamat Datang',
                          maxLines: 2,
                        ),
                        const Divider(height: 24),
                        _buildTextField(
                          controller: _footerController,
                          label: 'Footer Struk',
                          hint: 'Contoh: Terima Kasih',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan Pengaturan',
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE07A5F),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE07A5F)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
