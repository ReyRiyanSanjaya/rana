import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await ApiService().getSubscriptionPackages();
    setState(() {
      _packages = pkgs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade900, Colors.indigo.shade600]
          )
        ),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Upgrade ke Premium',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            const Text(
              'Akses fitur Sync & Manajemen tanpa batas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView.builder(
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final pkg = _packages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(pkg['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('${pkg['durationDays']} Hari', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(currency.format(pkg['price']), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(pkg['description'] ?? '', style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                                  onPressed: () {
                                      // In real app, trigger Payment Gateway logic here
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Memilih ${pkg['name']}...')));
                                  }, 
                                  child: const Text('Pilih Paket')
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Tutup (Mode Baca)', style: TextStyle(color: Colors.white))
            )
          ],
        ),
      ),
    );
  }
}
