import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Perangkat & Printer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Printer Bluetooth'),
            subtitle: const Text('Belum Terhubung / Panda Printer'),
            trailing: TextButton(onPressed: () {}, child: const Text('CARI')),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Ukuran Kertas'),
            subtitle: const Text('58mm (Standard)'),
            onTap: () {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Akun & Toko', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Profil Toko'),
            subtitle: const Text('Kopi Kenangan - Cabang 1'),
          ),
           ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Nomor WA Owner (Laporan)'),
            subtitle: const Text('081234567890'),
          ),
          const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Versi Aplikasi'),
              trailing: const Text('v1.0.0 (Beta)'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: const Text('Hubungi CS (Bantuan)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              subtitle: const Text('WhatsApp Administrator'),
              onTap: () async {
                 final Uri url = Uri.parse('https://wa.me/628887992299?text=Halo%20Admin%20Rana%20POS,%20saya%20butuh%20bantuan');
                 if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp')));
                    }
                 }
              },
            ),
        ],
      ),
    );
  }
}
