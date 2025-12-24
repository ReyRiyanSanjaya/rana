import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> bankInfo = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await ApiService().getSystemSettings();
    if (mounted) setState(() => bankInfo = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // ... Existing Items ...
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
          
          // [NEW] Bank Info Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Info Transfer Platform', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          if (bankInfo.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(bankInfo['BANK_NAME'] ?? 'Bank'),
              subtitle: Text('${bankInfo['BANK_ACCOUNT_NUMBER'] ?? '-'} a.n ${bankInfo['BANK_ACCOUNT_NAME'] ?? '-'}'),
              trailing: IconButton(onPressed: (){}, icon: const Icon(Icons.copy, size: 16)), // Copy logic TODO
            ),
             ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('Biaya Admin Platform'),
              subtitle: Text('${bankInfo['PLATFORM_FEE_PERCENTAGE'] ?? '0'}% per penarikan'),
            ),
          ] else 
            const ListTile(title: Text('Memuat info bank...', style: TextStyle(color: Colors.grey))),
            
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
            const Divider(),
             // DEBUG SECTION
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('Debug Menu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
             ),
             ListTile(
               leading: const Icon(Icons.bug_report, color: Colors.red),
               title: const Text('Cek Status Langganan Manual'),
               onTap: () async {
                  final sub = Provider.of<SubscriptionProvider>(context, listen: false);
                  try {
                    await sub.codeCheckSubscription();
                    // ignore: use_build_context_synchronously
                    showDialog(
                      context: context, 
                      builder: (_) => AlertDialog(
                        title: const Text("Hasil Debug"),
                        content: Text("Status: ${sub.status}\nIsLocked: ${sub.isLocked}\nPackages: ${sub.packages.length}"),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                      )
                    );
                  } catch (e) {
                     // ignore: use_build_context_synchronously
                     showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Error"), content: Text(e.toString())));
                  }
               },
             ),
            const Divider(),
        ],
      ),
    );
  }
}
