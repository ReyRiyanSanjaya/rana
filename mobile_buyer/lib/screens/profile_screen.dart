import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:rana_market/screens/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _buyerName;
  String? _buyerPhone;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadBuyerContact();
  }

  Future<void> _loadBuyerContact() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('buyer_name')?.trim();
    final phone = prefs.getString('buyer_phone')?.trim();
    if (!mounted) return;
    setState(() {
      _buyerName = (name != null && name.isNotEmpty) ? name : null;
      _buyerPhone = (phone != null && phone.isNotEmpty) ? phone : null;
      _loadingPrefs = false;
    });
  }

  Future<void> _openContactEditor() async {
    final nameCtrl = TextEditingController(text: _buyerName ?? '');
    final phoneCtrl = TextEditingController(text: _buyerPhone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Kontak Pesanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final phone = phoneCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          if (phone.isEmpty) return;
                          setLocal(() => saving = true);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('buyer_phone', phone);
                          if (name.isNotEmpty) {
                            await prefs.setString('buyer_name', name);
                          } else {
                            await prefs.remove('buyer_name');
                          }
                          if (mounted) {
                            setState(() {
                              _buyerPhone = phone;
                              _buyerName = name.isNotEmpty ? name : null;
                            });
                          }
                          if (context.mounted) Navigator.pop(ctx, true);
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontak pesanan diperbarui')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Masuk untuk melanjutkan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kamu bisa melihat pesanan, profil, dan melakukan transaksi.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.indigo),
                      title: const Text('Kontak pesanan'),
                      subtitle: _loadingPrefs
                          ? const Text('Memuat...')
                          : Text(
                              [
                                if ((_buyerName ?? '').isNotEmpty) _buyerName!,
                                if ((_buyerPhone ?? '').isNotEmpty) _buyerPhone!,
                              ].join(' • ').isEmpty
                                  ? 'Belum diatur'
                                  : [
                                      if ((_buyerName ?? '').isNotEmpty)
                                        _buyerName!,
                                      if ((_buyerPhone ?? '').isNotEmpty)
                                        _buyerPhone!,
                                    ].join(' • '),
                            ),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey),
                      onTap: () => _openContactEditor(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Masuk'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Daftar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(user?['name'] ?? 'Pengguna Rana',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?['email'] ?? '-',
                style: const TextStyle(color: Colors.grey)),
            Text((user?['phone'] ?? user?['phoneNumber'] ?? '-').toString(),
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 32),

            _buildMenuItem(Icons.phone, 'Kontak Pesanan',
                onTap: () => _openContactEditor()),

            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () async {
                await auth.logout();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Keluar'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
