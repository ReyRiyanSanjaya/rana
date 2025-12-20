import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['orderStatus'] ?? 'PENDING';
    final type = order['fulfillmentType'] ?? 'DELIVERY';
    final pickupCode = order['pickupCode'];
    final items = order['transactionItems'] ?? []; // Adjust based on API structure (might be nested differently)
    
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
                     Text('Order ID: ${order['id']}', style: const TextStyle(color: Colors.grey)),
                   ],
                 ),
               ),
             ),
             
             // QR Code for Pickup
             if (type == 'PICKUP' && status != 'COMPLETED' && status != 'CANCELLED' && pickupCode != null && order['paymentStatus'] == 'PAID')
               Container(
                 margin: const EdgeInsets.symmetric(vertical: 24),
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   border: Border.all(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
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
             // Simple item listing, assuming items is list of {product: {name}, quantity, price} or similar
             // For MVP, if detailed objects aren't populated, just show count
             // In real app, API should return populated items.
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: items.length,
               itemBuilder: (context, index) {
                  final item = items[index];
                  // If 'product' object is populated by prisma include
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
