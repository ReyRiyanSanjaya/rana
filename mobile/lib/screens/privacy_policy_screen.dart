import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kebijakan Privasi',
            style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Pendahuluan',
              content:
                  'Rana Merchant ("Aplikasi") berkomitmen untuk melindungi privasi dan keamanan data Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda.',
            ),
            _buildSection(
              title: '2. Informasi yang Kami Kumpulkan',
              content:
                  'Kami dapat mengumpulkan informasi berikut:\n'
                  '• Informasi Identitas: Nama, alamat email, nomor telepon, dan data toko.\n'
                  '• Data Transaksi: Riwayat penjualan, inventaris, dan laporan keuangan.\n'
                  '• Informasi Perangkat: ID perangkat, jenis perangkat, dan sistem operasi.',
            ),
            _buildSection(
              title: '3. Penggunaan Informasi',
              content:
                  'Informasi yang kami kumpulkan digunakan untuk:\n'
                  '• Menyediakan dan memelihara layanan Aplikasi.\n'
                  '• Memproses transaksi dan mengelola akun Anda.\n'
                  '• Meningkatkan fitur dan pengalaman pengguna.\n'
                  '• Mengirimkan pemberitahuan penting terkait akun atau layanan.',
            ),
            _buildSection(
              title: '4. Keamanan Data',
              content:
                  'Kami menerapkan langkah-langkah keamanan teknis dan organisasi yang sesuai untuk melindungi data Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.',
            ),
            _buildSection(
              title: '5. Hubungi Kami',
              content:
                  'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, silakan hubungi kami melalui fitur "Hubungi Bantuan" di dalam aplikasi.',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Terakhir diperbarui: 1 Januari 2026',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
