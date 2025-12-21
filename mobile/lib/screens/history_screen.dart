import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/services/digital_receipt_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = DatabaseHelper.instance;
    final allTxns = await db.getAllTransactions(); // Need to implement this in DB Helper
    setState(() {
      _transactions = allTxns.reversed.toList(); // Newest first
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _transactions.isEmpty 
            ? const Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final txn = _transactions[index];
                  final isSynced = txn['isSynced'] == 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSynced ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          isSynced ? Icons.cloud_done : Icons.cloud_upload,
                          color: isSynced ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text('Order #${txn['id']}'),
                      subtitle: Text('Total: Rp ${txn['totalAmount']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                           // Show Detail logic
                      },
                    ),
                  );
                },
              ),
    );
  }

  void _showPhoneDialog(BuildContext context, Map<String, dynamic> txn, List<Map<String, dynamic>> items) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Struk via WA'),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nomor WhatsApp (62...)', hintText: '628123456789'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              DigitalReceiptService.sendViaWhatsApp(phoneCtrl.text, txn, items);
            }, 
            child: const Text('Kirim')
          )
        ],
      )
    );
  }
}
