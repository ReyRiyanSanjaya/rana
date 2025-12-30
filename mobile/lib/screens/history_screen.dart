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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _transactions.isEmpty 
            ? RefreshIndicator(
                onRefresh: _loadHistory,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    const SliverFillRemaining(
                      child: Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))),
                    )
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadHistory,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final txn = _transactions[index];
                            final isSynced = txn['status'] == 'SYNCED';
                            final date = DateTime.tryParse(txn['occurredAt'] ?? '') ?? DateTime.now();
                            final dateStr = DateFormat('dd MMM HH:mm').format(date);
            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSynced ? Colors.green.shade50 : Colors.orange.shade50,
                                  child: Icon(
                                    isSynced ? Icons.check_circle : Icons.sync,
                                    color: isSynced ? Colors.green : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                title: Text('Order #${txn['offlineId'].toString().substring(0,8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$dateStr • Rp ${NumberFormat('#,##0', 'id_ID').format(txn['total'] ?? 0)}'),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                     // Show Detail logic
                                     _showPhoneDialog(context, txn, []); // Passing empty items for now as they are not loaded in list
                                },
                              ),
                            );
                          },
                          childCount: _transactions.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFBF092F),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter
            )
          ),
        ),
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
