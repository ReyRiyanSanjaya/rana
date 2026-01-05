import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/services/printer_service.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:rana_merchant/services/sync_service.dart'; // [NEW]

class PaymentScreen extends StatefulWidget {
  final CartProvider cart;

  const PaymentScreen({super.key, required this.cart});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'CASH';
  double payAmount = 0;
  bool _isProcessing = false;

  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    // Auto-fill amount for QRIS
    if (method == 'QRIS') {
      payAmount = widget.cart.totalAmount;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void setAmount(double val) {
    setState(() {
      payAmount = val;
      _amountController.text = val == 0 ? '' : val.toStringAsFixed(0);
      _amountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _amountController.text.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.totalAmount;
    double change = payAmount - total;

    // Quick cash suggestions
    final suggestions = [total, 20000.0, 50000.0, 100000.0];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pembayaran',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildMethodCard('CASH', Icons.payments, true),
                    const SizedBox(width: 12),
                    _buildMethodCard('QRIS', Icons.qr_code_2, false),
                  ],
                ),
                if (method == 'CASH') ...[
                  const SizedBox(height: 24),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        prefixText: 'Rp ',
                        labelText: 'Nominal Diterima',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50]),
                    controller: _amountController,
                    onChanged: (v) {
                      setState(() => payAmount = double.tryParse(v) ?? 0);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: suggestions.map((amt) {
                      if (amt < total && amt != total)
                        return const SizedBox.shrink();
                      return ActionChip(
                        label: Text(
                            'Rp ${NumberFormat.decimalPattern('id').format(amt)}'),
                        onPressed: () => setAmount(amt),
                        backgroundColor:
                            payAmount == amt ? Colors.green[100] : Colors.white,
                        side: BorderSide(
                            color: payAmount == amt
                                ? Colors.green
                                : Colors.grey[300]!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: change >= 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: change >= 0
                                ? Colors.green[200]!
                                : Colors.red[200]!)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kembalian',
                            style: GoogleFonts.poppins(fontSize: 16)),
                        Text(
                            'Rp ${change < 0 ? 0 : NumberFormat.decimalPattern('id').format(change)}',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: change >= 0
                                    ? Colors.green[800]
                                    : Colors.red[800])),
                      ],
                    ),
                  )
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isProcessing ||
                          (method == 'CASH' && payAmount < total)
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          try {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            final user = auth.currentUser;

                            String? storeId = user?['storeId'];
                            String? tenantId = user?['tenantId'];

                            if (tenantId == null) {
                              final tenant =
                                  await DatabaseHelper.instance.getTenantInfo();
                              tenantId = tenant?['id'];
                            }

                            if (tenantId == null) {
                              throw Exception(
                                  'Data sesi tidak valid. Silakan login ulang.');
                            }

                            final cashierId = user?['id'] ?? 'OFFLINE_CASHIER';

                            final items = List<Map<String, dynamic>>.from(
                                widget.cart.items.values.map((e) => {
                                      'name': e.name,
                                      'quantity': e.quantity,
                                      'price': e.price,
                                    }));
                            final totalAmt = widget.cart.totalAmount;
                            final discAmt = widget.cart.discountAmount;

                            await widget.cart.checkout(
                              tenantId,
                              storeId ?? tenantId,
                              cashierId,
                              paymentMethod: method,
                              customerName: widget.cart.customerName,
                              notes: widget.cart.notes,
                            );

                            if (!mounted) return;

                            SoundService.playSuccess();

                            // [NEW] Trigger Sync in background
                            SyncService().syncTransactions();

                            final txnData = {
                              'offlineId':
                                  'TXN-${DateTime.now().millisecondsSinceEpoch}',
                              'totalAmount': totalAmt,
                              'payAmount': payAmount,
                              'changeAmount': change,
                              'cashierName': user?['name'] ?? 'Kasir',
                              'customerName': widget.cart.customerName,
                              'discount': discAmt,
                              'storeId': storeId
                            };

                            Navigator.pop(context, true);

                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: Column(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.green, size: 64),
                                          const SizedBox(height: 16),
                                          Text('Transaksi Berhasil',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Text(
                                          'Pembayaran telah berhasil disimpan.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins()),
                                      actions: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            await PrinterService().printReceipt(
                                                txnData, items,
                                                storeName: 'RANA STORE');
                                          },
                                          icon: const Icon(Icons.print),
                                          label: const Text('Cetak Struk'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            side: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            padding: const EdgeInsets.all(16),
                                            minimumSize:
                                                const Size.fromHeight(50),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                          },
                                          style: FilledButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              minimumSize:
                                                  const Size.fromHeight(50),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12))),
                                          child: const Text('Tutup'),
                                        )
                                      ],
                                      actionsAlignment:
                                          MainAxisAlignment.center,
                                    ));
                          } catch (e) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        },
                  style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text('SELESAIKAN',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String id, IconData icon, bool selected) {
    final isSelected = method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          method = id;
          payAmount = (id == 'QRIS' ? widget.cart.totalAmount : 0);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE07A5F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      isSelected ? const Color(0xFFE07A5F) : Colors.grey[300]!),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: const Color(0xFFE07A5F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : []),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 28),
              const SizedBox(height: 8),
              Text(id,
                  style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionSuccessDialog extends StatefulWidget {
  const TransactionSuccessDialog({super.key});

  @override
  State<TransactionSuccessDialog> createState() =>
      _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState extends State<TransactionSuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      // 2 seconds is snappy enough
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Transaksi Berhasil!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
