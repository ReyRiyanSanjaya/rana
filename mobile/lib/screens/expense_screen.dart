import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

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
    setState(() => _isLoading = true);
    try {
      // Direct call to API (Expenses are usually online-only or queued)
      // For MVP, assuming online for expenses
      final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:4000/api'));
      
      await dio.post('/reports/expenses', data: {
         'storeId': 'store-1', // Mock
         'amount': double.tryParse(_amountCtrl.text) ?? 0,
         'category': _category,
         'description': _descCtrl.text,
         'date': DateTime.now().toIso8601String()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense Recorded!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
