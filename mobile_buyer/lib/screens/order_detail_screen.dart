import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/main_screen.dart';
import 'package:rana_market/services/realtime_service.dart';
import 'package:rana_market/widgets/buyer_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final RealtimeService _realtime = RealtimeService();
  late Map<String, dynamic> _order;
  bool _refreshing = false;
  void Function()? _unwatch;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _unwatch = _realtime.watchOrderStatus(_order['id'], onUpdate: (data) {
      if (!mounted) return;
      setState(() {
        _order = {..._order, ...data};
      });
    });
  }

  @override
  void dispose() {
    _unwatch?.call();
    super.dispose();
  }

  Future<void> _refreshOrder() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fromUser =
          (auth.user?['phone'] ?? auth.user?['phoneNumber'])?.toString().trim();
      String? phone =
          (fromUser != null && fromUser.isNotEmpty) ? fromUser : null;
      if (phone == null) {
        final prefs = await SharedPreferences.getInstance();
        final p = (prefs.getString('buyer_phone') ?? '').trim();
        if (p.isNotEmpty) phone = p;
      }
      if (phone == null) return;
      final list = await MarketApiService().getMyOrders(phone: phone);
      final id = _order['id'];
      final found = list.whereType<Map>().cast<Map>().firstWhere(
            (e) => e['id'] == id,
            orElse: () => const {},
          );
      if (found.isNotEmpty && mounted) {
        setState(() {
          _order = {..._order, ...Map<String, dynamic>.from(found)};
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openMapsForOrderStore() async {
    final store = _order['store'];
    String? address;
    double? lat;
    double? long;
    if (store is Map) {
      address = (store['address'] ?? store['location'] ?? store['alamat'])
          ?.toString();
      final dynamic latV = store['latitude'] ?? store['lat'];
      final dynamic longV = store['longitude'] ?? store['long'] ?? store['lng'];
      if (latV is num) lat = latV.toDouble();
      if (longV is num) long = longV.toDouble();
    }
    final query = (lat != null && long != null)
        ? '${lat.toStringAsFixed(6)},${long.toStringAsFixed(6)}'
        : (address ?? '');
    if (query.trim().isEmpty) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactSeller() async {
    final store = _order['store'];
    if (store is! Map) return;
    final phone = (store['phone'] ?? store['phoneNumber'] ?? '').toString();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon toko tidak tersedia')));
      return;
    }

    // Format phone to international format (assuming ID +62)
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    final uri = Uri.parse(
        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent('Halo, saya ingin menanyakan pesanan #${_order['id']}')}');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka WhatsApp')));
      }
    }
  }

  void _copyOrderId() {
    Clipboard.setData(ClipboardData(text: _order['id'].toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID disalin ke clipboard')),
    );
  }

  String _formatCurrency(num number) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(number);
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['orderStatus'] ?? 'PENDING';
    final type = _order['fulfillmentType'] ?? 'PICKUP';
    final pickupCode = _order['pickupCode'] ?? _order['id'];
    final items = _order['transactionItems'] ?? [];
    final store = _order['store'];
    final storeName = (store is Map ? store['name'] : null)?.toString();
    final storeAddress = (store is Map
            ? (store['address'] ?? store['location'] ?? store['alamat'])
            : null)
        ?.toString();

    // Determine status details
    Color statusColor;
    String statusText;
    IconData statusIcon;
    int currentStep = 0;

    switch (status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Menunggu Konfirmasi';
        statusIcon = Icons.hourglass_top;
        currentStep = 1;
        break;
      case 'ACCEPTED':
      case 'PROCESSING':
        statusColor = Colors.blue;
        statusText = 'Sedang Diproses';
        statusIcon = Icons.soup_kitchen;
        currentStep = 2;
        break;
      case 'READY_TO_PICKUP':
      case 'READY':
        statusColor = Colors.green;
        statusText = 'Siap Diambil';
        statusIcon = Icons.shopping_bag;
        currentStep = 3;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = 'Selesai';
        statusIcon = Icons.check_circle;
        currentStep = 4;
        break;
      case 'CANCELLED':
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        statusIcon = Icons.cancel;
        currentStep = 0;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Detail Pesanan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshing ? null : _refreshOrder,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status Timeline (Simplified)
              if (status != 'CANCELLED' && status != 'REJECTED')
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildStep(1, currentStep, 'Dipesan'),
                      _buildLine(1, currentStep),
                      _buildStep(2, currentStep, 'Diproses'),
                      _buildLine(2, currentStep),
                      _buildStep(3, currentStep, 'Siap'),
                      _buildLine(3, currentStep),
                      _buildStep(4, currentStep, 'Selesai'),
                    ],
                  ),
                ),

              // 2. Main Status Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            statusColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(statusIcon, color: statusColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _copyOrderId,
                                      child: Row(
                                        children: [
                                          Text(
                                            'ID: ${_order['id'].toString().substring(0, 12)}...',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.copy,
                                              size: 12, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                    if (_order['createdAt'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          DateFormat('dd MMM yyyy, HH:mm')
                                              .format(DateTime.parse(
                                                  _order['createdAt']
                                                      .toString())),
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Code Logic
                    if (type == 'PICKUP' &&
                        (status == 'READY_TO_PICKUP' ||
                            status == 'READY' ||
                            status == 'COMPLETED')) ...[
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Kode Pengambilan',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 2),
                              ),
                              child: QrImageView(
                                data: pickupCode.toString(),
                                version: QrVersions.auto,
                                size: 180.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pickupCode.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  letterSpacing: 4),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tunjukkan QR ini ke kasir',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ] else if (status == 'CANCELLED' ||
                        status == 'REJECTED') ...[
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 50, color: Colors.red.shade100),
                            const SizedBox(height: 8),
                            const Text(
                              'Pesanan ini telah dibatalkan',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Store Info
              const Text('Informasi Toko',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Color(0xFFE07A5F)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName ?? 'Nama Toko',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            storeAddress ?? 'Alamat tidak tersedia',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Color(0xFFE07A5F)),
                          onPressed: _openMapsForOrderStore,
                          tooltip: 'Lihat di Peta',
                        ),
                        if (store is Map &&
                            (store['phone'] != null ||
                                store['phoneNumber'] != null))
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.green),
                            onPressed: _contactSeller,
                            tooltip: 'Chat Penjual',
                          ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Order Items
              const Text('Rincian Pesanan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        // Robust Product Name Resolution
                        String prodName = 'Produk Tidak Dikenal';
                        if (item['productName'] != null) {
                          prodName = item['productName'];
                        } else if (item['name'] != null) {
                          prodName = item['name'];
                        } else if (item['product'] is Map &&
                            item['product']['name'] != null) {
                          prodName = item['product']['name'];
                        } else if (item['product'] is String) {
                          // Fallback if product is just ID but maybe we have it in list?
                          // Rarely happens if backend is good.
                          prodName = 'Item #${item['productId']}';
                        }

                        final price =
                            (item['price'] as num?)?.toDouble() ?? 0.0;
                        final qty = item['quantity'] as int? ?? 1;
                        final total = price * qty;
                        final note = item['note'] as String?;

                        final imageUrl = item['product'] is Map
                            ? (item['product']['imageUrl'] ??
                                item['product']['image'])
                            : null;
                        final resolvedImage = imageUrl != null
                            ? MarketApiService().resolveFileUrl(imageUrl)
                            : '';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: resolvedImage.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(resolvedImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey)),
                                    )
                                  : const Icon(Icons.fastfood,
                                      color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prodName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$qty x ${_formatCurrency(price)}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12),
                                  ),
                                  if (note != null && note.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Catatan: $note',
                                        style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(total),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(thickness: 1),
                    ),
                    // Payment Details
                    _buildPaymentRow(
                        'Subtotal',
                        (items as List).fold(
                            0,
                            (sum, item) =>
                                sum +
                                ((item['price'] as num? ?? 0) *
                                    (item['quantity'] as num? ?? 1)))),
                    const SizedBox(height: 8),
                    _buildPaymentRow(
                        'Biaya Layanan', (_order['buyerFee'] as num?) ?? 0),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          _formatCurrency(_order['totalAmount'] as num? ?? 0),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFE07A5F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BuyerBottomNav(
        selectedIndex: 1,
        onSelected: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => MainScreen(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildPaymentRow(String label, num value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(_formatCurrency(value),
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStep(int step, int currentStep, String label) {
    final isActive = step <= currentStep;
    final isCompleted = step < currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE07A5F) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Center(
                    child: Text(
                      step.toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int step, int currentStep) {
    final isActive = step < currentStep;
    return Container(
      width: 20,
      height: 2,
      color: isActive ? const Color(0xFFE07A5F) : Colors.grey.shade300,
      margin:
          const EdgeInsets.only(bottom: 14), // Align with circle center roughly
    );
  }
}
