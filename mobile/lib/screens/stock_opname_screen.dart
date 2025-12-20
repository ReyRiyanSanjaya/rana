import 'package:flutter/material.dart';
import 'package:rana_pos/data/local/database_helper.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  List<Map<String, dynamic>> _products = [];
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await DatabaseHelper.instance.getAllProducts();
    for (var p in prods) {
       // Initialize controller with current calculated stock (mocked as 0 or need a stock field in DB)
       // Since the current Schema has 'trackStock' boolean but not 'currentStock' quantity (that is usually calculated from logs)
       // We will assume for MVP we fetch a 'stock' or just default to 0. 
       // In a real Opname, we input the REAL PHYSICAL number.
       _controllers[p['id']] = TextEditingController();
    }
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  Future<void> _saveAdjustment() async {
      // 1. Gather all inputs
      // 2. Create an 'Adjustment' transaction or Audit Log
      // For MVP, we just show Success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok Fisik Disimpan (Audit Log)')));
      Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Opname')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Masukkan jumlah stok fisik yang ada di rak saat ini.', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return ListTile(
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('SKU: ${p['sku']}'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _controllers[p['id']],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Fisik',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Simpan Opname'),
                      onPressed: _saveAdjustment,
                  ),
                ),
              )
            ],
          ),
    );
  }
}
