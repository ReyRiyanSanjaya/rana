import 'package:flutter/material.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/services/digital_receipt_service.dart';
import 'package:rana_merchant/services/sync_service.dart'; // [FIX] Added SyncService
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
    // [FIX] Sync from server first
    try {
      await SyncService().syncTransactionHistory();
    } catch (e) {
      // Continue even if sync fails (offline mode)
    }

    final db = DatabaseHelper.instance;
    final allTxns = await db.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = allTxns; // [FIX] Removed reversed to show Newest First
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
            ? RefreshIndicator(
                onRefresh: _loadHistory,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    const SliverFillRemaining(
                      child: Center(
                          child: Text('Belum ada transaksi',
                              style: TextStyle(color: Colors.grey))),
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
                            final date =
                                DateTime.tryParse(txn['occurredAt'] ?? '') ??
                                    DateTime.now();
                            final dateStr =
                                DateFormat('dd MMM HH:mm').format(date);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      const Color(0xFFE07A5F).withOpacity(0.12),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isSynced
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  child: Icon(
                                    isSynced ? Icons.check_circle : Icons.sync,
                                    color:
                                        isSynced ? Colors.green : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Order #${txn['offlineId'].toString().substring(0, 8)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '$dateStr • Rp ${NumberFormat('#,##0', 'id_ID').format(txn['total'] ?? 0)}',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                                onTap: () async {
                                  // Fetch items from DB
                                  final db = DatabaseHelper.instance;
                                  final items = await db
                                      .getItemsForTransaction(txn['offlineId']);
                                  if (context.mounted) {
                                    _showPhoneDialog(context, txn, items);
                                  }
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
              );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) return body;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: body,
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFFFF8F0),
      iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
      title: const Text('Riwayat Transaksi',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE07A5F))),
      centerTitle: true,
    );
  }

  void _showPhoneDialog(BuildContext context, Map<String, dynamic> txn,
      List<Map<String, dynamic>> items) {
    final phoneCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Kirim Struk via WA'),
              content: TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp (62...)',
                    hintText: '628123456789'),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      DigitalReceiptService.sendViaWhatsApp(
                          phoneCtrl.text, txn, items);
                    },
                    child: const Text('Kirim'))
              ],
            ));
  }
}
