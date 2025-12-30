import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

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
            Text(user?['name'] ?? 'Pengguna Rana', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?['email'] ?? '-', style: const TextStyle(color: Colors.grey)),
            Text(user?['phone'] ?? '-', style: const TextStyle(color: Colors.grey)),
            
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
