import 'package:flutter/material.dart';
import 'package:rana_merchant/data/local/database_helper.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'EXPENSE_PETTY';
  bool _isLoading = false;

  Future<void> _submitExpense() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan jumlah yang valid')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Save locally
      await DatabaseHelper.instance.insertExpense({
        'storeId': 'store-1', // Default or sync with settings
        'amount': amount,
        'category': _category,
        'description': _descCtrl.text,
        'date': DateTime.now().toIso8601String(),
        'synced': 0
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengeluaran Berhasil Disimpan'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pengeluaran')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'EXPENSE_PETTY', child: Text('Petty Cash (Es/Plastik)')),
                DropdownMenuItem(value: 'EXPENSE_OPERATIONAL', child: Text('Operasional (Listrik/Air)')),
              ],
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Keterangan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitExpense,
                child: const Text('Simpan Pengeluaran'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
