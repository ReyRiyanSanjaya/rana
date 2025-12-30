import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rana_market/services/realtime_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final RealtimeService _realtime = RealtimeService();
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _realtime.watchOrderStatus(_order['id'], onUpdate: (data) {
      if (!mounted) return;
      setState(() {
        _order = {..._order, ...data};
      });
    });
  }

  @override
  void dispose() {
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['orderStatus'] ?? 'PENDING';
    final type = _order['fulfillmentType'] ?? 'DELIVERY';
    final pickupCode = _order['pickupCode'];
    final items = _order['transactionItems'] ?? [];
    
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             // Status Card
             Card(
               color: status == 'COMPLETED' ? Colors.green.shade50 : Colors.indigo.shade50,
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   children: [
                     Icon(
                       status == 'COMPLETED' ? Icons.check_circle : Icons.access_time, 
                       size: 48, 
                       color: status == 'COMPLETED' ? Colors.green : Colors.indigo
                     ),
                     const SizedBox(height: 8),
                     Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                     Text('Order ID: ${_order['id']}', style: const TextStyle(color: Colors.grey)),
                   ],
                 ),
               ),
             ),
             
             // QR Code for Pickup
             if (type == 'PICKUP' && status != 'COMPLETED' && status != 'CANCELLED' && pickupCode != null && _order['paymentStatus'] == 'PAID')
               Container(
                 margin: const EdgeInsets.symmetric(vertical: 24),
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
                ),
                 child: Column(
                   children: [
                     const Text('Tunjukkan QR Code ini ke Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     QrImageView(
                       data: pickupCode,
                       version: QrVersions.auto,
                       size: 200.0,
                     ),
                     const SizedBox(height: 8),
                     Text(pickupCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 5)),
                   ],
                 ),
               ),
               
             const SizedBox(height: 24),
             const Align(alignment: Alignment.centerLeft, child: Text("Items:", style: TextStyle(fontWeight: FontWeight.bold))),
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: items.length,
               itemBuilder: (context, index) {
                  final item = items[index];
                  final prodName = item['product'] != null ? item['product']['name'] : 'Product #${item['productId']}';
                  return ListTile(
                    title: Text(prodName),
                    trailing: Text('x${item['quantity']}'),
                  );
               },
             )
          ],
        ),
      ),
    );
  }
}
