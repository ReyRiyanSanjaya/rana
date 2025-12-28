import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // [NEW] Clipboard
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart'; // [FIX] Added missing import
import 'package:rana_merchant/screens/printer_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> bankInfo = {};
  Map<String, dynamic> userProfile = {}; // [NEW]

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ApiService().getSystemSettings();
      final profile = await ApiService().getProfile(); 
      if (mounted) {
        setState(() {
          bankInfo = data;
          userProfile = profile;
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFBF092F),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter
                  )
                ),
              ),
            ),
            actions: [
                IconButton(
                 onPressed: () {
                   // Clear internal state
                   Provider.of<AuthProvider>(context, listen: false).logout();
                   // Clear any strict cache if needed, but wrapper handles nav
                 }, 
                 icon: const Icon(Icons.logout)
               )
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Top Profile Card (Optional, can be added later)
              
              // ... Existing Items ...
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Perangkat & Printer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
              ListTile(
                title: const Text('Printer Bluetooth'),
                subtitle: const Text('Kelola koneksi printer thermal'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
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
    
              // [NEW] Akun & Toko Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Akun & Toko', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Profil Toko'),
                subtitle: Text(userProfile['tenant']?['name'] ?? userProfile['store']?['name'] ?? 'Memuat...'),
              ),
              // [NEW] Display Merchant ID
              if (userProfile.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: Color(0xFFBF092F)),
                  title: const Text('ID Merchant (Store ID)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBF092F))),
                  subtitle: Text(userProfile['store']?['id'] ?? userProfile['tenant']?['id'] ?? 'Belum ada ID'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      final id = userProfile['store']?['id'] ?? userProfile['tenant']?['id'];
                      if (id != null) {
                        Clipboard.setData(ClipboardData(text: id));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Merchant disalin')));
                      }
                    },
                  ),
                ),

               ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Nomor WA Owner (Laporan)'),
                subtitle: Text(userProfile['store']?['waNumber'] ?? '-'),
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
            ]),
          ),
        ],
      ),
    );
  }
}
