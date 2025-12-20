import 'package:flutter/material.dart';
import 'package:rana_pos/data/local/database_helper.dart';
import 'package:rana_pos/data/remote/api_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _supplierCtrl = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  Map<String, int> _quantities = {};
  Map<String, double> _buyPrices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = prods;
      for (var p in prods) {
        _quantities[p['id']] = 0;
        _buyPrices[p['id']] = (p['costPrice'] as num).toDouble();
      }
      _isLoading = false;
    });
  }

  Future<void> _submitPurchase() async {
    // Filter items with qty > 0
    final items = _products.where((p) => (_quantities[p['id']] ?? 0) > 0).map((p) => {
       'productId': p['id'],
       'quantity': _quantities[p['id']],
       'costPrice': _buyPrices[p['id']]
    }).toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Direct API Call (Online Only feature for now for Purchasing)
      // Or we can make it offline-first, but Schema is complex. 
      // Let's assume Online for Restocking logic to ensure Server Master Data is sync.
      await ApiService().createPurchase(
         supplierName: _supplierCtrl.text.isEmpty ? 'Umum' : _supplierCtrl.text,
         items: items
      );
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembelian Berhasil Disimpan')));
        Navigator.pop(context);
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembelian Stok (Kulakan)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(labelText: 'Nama Supplier / Toko', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_shipping)),
            ),
          ),
          Expanded(
            child: _isLoading 
             ? const Center(child: CircularProgressIndicator())
             : ListView.separated(
                itemCount: _products.length,
                separatorBuilder: (_,__) => const Divider(),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  final id = p['id'];
                  return ListTile(
                    title: Text(p['name']),
                    subtitle: Row(
                      children: [
                         const Text('Beli: Rp '),
                         SizedBox(
                           width: 80,
                           child: TextField(
                             keyboardType: TextInputType.number,
                             decoration: const InputDecoration(isDense: true),
                             onChanged: (v) => _buyPrices[id] = double.tryParse(v) ?? 0,
                             controller: TextEditingController(text: _buyPrices[id]?.toInt().toString()),
                           ),
                         )
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                           setState(() {
                             if (_quantities[id]! > 0) _quantities[id] = _quantities[id]! - 1;
                           });
                        }),
                        Text('${_quantities[id]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () {
                           setState(() {
                             _quantities[id] = _quantities[id]! + 1;
                           });
                        }),
                      ],
                    ),
                  );
                },
             ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _isLoading ? null : _submitPurchase, child: const Text('SIMPAN PEMBELIAN'))),
          )
        ],
      ),
    );
  }
}
