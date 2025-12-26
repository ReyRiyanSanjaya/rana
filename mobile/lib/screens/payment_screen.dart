import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/services/sound_service.dart';

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
       _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
     });
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.totalAmount;
    double change = payAmount - total;
    
    // Quick cash suggestions
    final suggestions = [total, 20000.0, 50000.0, 100000.0];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          const SizedBox(height: 16),
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal Diterima',
                border: OutlineInputBorder()
              ),
              controller: _amountController,
              onChanged: (v) {
                // Don't call setAmount here to avoid loop with controller text update
                setState(() => payAmount = double.tryParse(v) ?? 0);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: suggestions.map((amt) {
                if (amt < total && amt != total) return const SizedBox.shrink(); 
                return ActionChip(
                  label: Text('Rp ${NumberFormat.decimalPattern('id').format(amt)}'),
                  onPressed: () => setAmount(amt),
                  backgroundColor: payAmount == amt ? Colors.green[100] : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: change >= 0 ? Colors.green[50] : Colors.red[50],
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: change >= 0 ? Colors.green[200]! : Colors.red[200]!)
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Kembalian', style: TextStyle(fontSize: 16)),
                   Text('Rp ${change < 0 ? 0 : NumberFormat.decimalPattern('id').format(change)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 ],
               ),
             )
          ],
          
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _isProcessing || (method == 'CASH' && payAmount < total) ? null : () async {
              setState(() => _isProcessing = true);
              try {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final user = auth.currentUser;

                if (user == null || user['storeId'] == null) {
                   throw Exception('User data or Store configuration missing. Please login again.');
                }

                await widget.cart.checkout(
                  user['tenantId'], 
                  user['storeId'], 
                  user['id'], // Cashier ID
                  paymentMethod: method
                );
                
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('SELESAIKAN'),
          )
        ],
      ),
    );
  }
  
  Widget _buildMethodCard(String id, IconData icon, bool selected) {
    final isSelected = method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { method = id; payAmount = 0; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
             color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 24),
              const SizedBox(height: 8),
              Text(id, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold))
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
  State<TransactionSuccessDialog> createState() => _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState extends State<TransactionSuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () { // 2 seconds is snappy enough
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
            const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
