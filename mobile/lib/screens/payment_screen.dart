import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
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
  
  void setAmount(double val) {
     setState(() => payAmount = val);
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
              onChanged: (v) => setAmount(double.tryParse(v) ?? 0),
              controller: TextEditingController(text: payAmount == 0 ? '' : payAmount.toStringAsFixed(0))..selection = TextSelection.fromPosition(TextPosition(offset: (payAmount == 0 ? '' : payAmount.toStringAsFixed(0)).length)),
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
                await widget.cart.checkout('tenant-1', 'store-1', 'cashier-1', paymentMethod: method);
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

class TransactionSuccessDialog extends StatelessWidget {
  const TransactionSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) Navigator.of(context).pop();
    });

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
