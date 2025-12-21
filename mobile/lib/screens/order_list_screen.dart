import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    // Polling logic would go here or socket
    // Standard Rest Call for now
    try {
       final auth = Provider.of<AuthProvider>(context, listen: false);
       final dio = Dio(); // Should use shared instance
       // Hardcoded IP for Demo, should be Config
       final res = await dio.get('http://10.0.2.2:4000/api/orders', 
         options: Options(headers: {'Authorization': 'Bearer ${auth.token}'}));
       
       if (res.data['success']) {
         setState(() {
           _orders = res.data['data'];
           _isLoading = false;
         });
       }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _updateStatus(String id, String status) async {
    try {
       final auth = Provider.of<AuthProvider>(context, listen: false);
       final dio = Dio();
       await dio.put('http://10.0.2.2:4000/api/orders/status', 
         data: {'orderId': id, 'status': status},
         options: Options(headers: {'Authorization': 'Bearer ${auth.token}'})
       );
       _fetchOrders(); // Refresh
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order $status')));
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'), 
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders)]
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _orders.isEmpty 
           ? const Center(child: Text('Belum ada pesanan baru'))
           : ListView.builder(
               itemCount: _orders.length,
               itemBuilder: (context, index) {
                 final order = _orders[index];
                 final items = order['transactionItems'] as List;
                 
                 return Card(
                   margin: const EdgeInsets.all(8),
                   child: ExpansionTile(
                     leading: CircleAvatar(
                       backgroundColor: Colors.orange.shade100,
                       child: const Icon(Icons.delivery_dining, color: Colors.orange),
                     ),
                     title: Text('${order['customerName']} (${order['orderStatus']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text('Rp ${order['totalAmount']} - ${items.length} Barang'),
                     children: [
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Alamat: ${order['deliveryAddress'] ?? '-'}'),
                             const Divider(),
                             ...items.map((i) => Text('${i['product']['name']} x${i['quantity']}')),
                             const SizedBox(height: 16),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               children: [
                                 if (order['orderStatus'] == 'PENDING')
                                   FilledButton(
                                     onPressed: () => _updateStatus(order['id'], 'ACCEPTED'), 
                                     style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                                     child: const Text('TERIMA')
                                   ),
                                 if (order['orderStatus'] == 'ACCEPTED')
                                   FilledButton(
                                     onPressed: () => _updateStatus(order['id'], 'READY'), 
                                     style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                                     child: const Text('SIAP KIRIM')
                                   ),
                                 if (order['orderStatus'] == 'READY')
                                   FilledButton(
                                     onPressed: () => _updateStatus(order['id'], 'COMPLETED'), 
                                     style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                     child: const Text('SELESAI')
                                   ),
                               ],
                             )
                           ],
                         ),
                       )
                     ],
                   ),
                 );
               },
             ),
    );
  }
}
