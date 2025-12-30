import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:rana_market/screens/register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          actions: [
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
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
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
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
            Text(user?['phone'] ?? '-',
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 32),

            // Menu Options
            _buildMenuItem(Icons.location_on, 'Alamat Tersimpan', onTap: () {}),
            _buildMenuItem(Icons.payment, 'Metode Pembayaran', onTap: () {}),
            _buildMenuItem(Icons.favorite, 'Favorit', onTap: () {}),
            _buildMenuItem(Icons.help, 'Bantuan & Dukungan', onTap: () {}),

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
