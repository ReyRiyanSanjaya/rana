import 'package:flutter/material.dart';
import 'package:rana_pos/data/remote/api_service.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  double _balance = 0;
  List<dynamic> _withdrawals = [];
  final _amountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();

  final _currency = NumberFormat.simpleCurrency(locale: 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getWalletData();
      setState(() {
        _balance = (data['balance'] as num).toDouble();
        _withdrawals = data['withdrawals'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarik Saldo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saldo Tersedia: ${_currency.format(_balance)}'),
            const SizedBox(height: 16),
            TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Penarikan', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _bankCtrl, decoration: const InputDecoration(labelText: 'Nama Bank', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _accountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nomor Rekening', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (_amountCtrl.text.isEmpty || _bankCtrl.text.isEmpty || _accountCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _submitWithdrawal();
            },
            child: const Text('Ajukan'),
          )
        ],
      ),
    );
  }

  Future<void> _submitWithdrawal() async {
    setState(() => _isLoading = true);
    try {
      await ApiService().requestWithdrawal(
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        bankName: _bankCtrl.text,
        accountNumber: _accountCtrl.text
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penarikan Berhasil Diajukan'), backgroundColor: Colors.green));
      _amountCtrl.clear();
      _loadData(); // Refresh balance
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet Merchant')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance Card
            Card(
              color: Colors.indigo,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_currency.format(_balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo),
                      icon: const Icon(Icons.download),
                      label: const Text('Tarik Dana'),
                      onPressed: _showWithdrawDialog,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Riwayat Penarikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _withdrawals.isEmpty 
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada riwayat')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _withdrawals.length,
                  itemBuilder: (context, index) {
                    final wd = _withdrawals[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          wd['status'] == 'APPROVED' ? Icons.check_circle : (wd['status'] == 'REJECTED' ? Icons.cancel : Icons.access_time),
                          color: wd['status'] == 'APPROVED' ? Colors.green : (wd['status'] == 'REJECTED' ? Colors.red : Colors.orange),
                        ),
                        title: Text(_currency.format(wd['amount'])),
                        subtitle: Text('${wd['bankName']} - ${wd['accountNumber']}\n${wd['createdAt']}'),
                        isThreeLine: true,
                        trailing: Text(wd['status'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                )
          ],
        ),
    );
  }
}
