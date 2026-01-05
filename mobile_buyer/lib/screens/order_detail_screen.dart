import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/config/app_config.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/main_screen.dart';
import 'package:rana_market/services/socket_service.dart';
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
  late Map<String, dynamic> _order;
  bool _refreshing = false;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocket();
    });
  }

  void _setupSocket() {
    final socket = Provider.of<SocketService>(context, listen: false);
    final orderId = _order['id'].toString();
    socket.joinOrder(orderId);
    _socketSub = socket.orderStatusStream.listen((data) {
      if (!mounted) return;
      if (data['id'].toString() == orderId) {
        setState(() {
          _order = {..._order, ...data};
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
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
        '${AppConfig.googleMapsSearchUrl}${Uri.encodeComponent(query)}');
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
        '${AppConfig.whatsappApiUrl}$formattedPhone?text=${Uri.encodeComponent('Halo, saya ingin menanyakan pesanan #${_order['id']}')}');

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
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
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
    final deliveryAddress = _order['deliveryAddress']?.toString() ?? '-';

    // Determine status details
    Color statusColor;
    String statusText;
    IconData statusIcon;
    int currentStep = 0;

    switch (status) {
      case 'PENDING':
        statusColor = ThemeConfig.colorWarning;
        statusText = 'Menunggu Konfirmasi';
        statusIcon = Icons.hourglass_top;
        currentStep = 1;
        break;
      case 'ACCEPTED':
      case 'PROCESSING':
        statusColor = ThemeConfig.colorInfo;
        statusText = 'Sedang Diproses';
        statusIcon = Icons.soup_kitchen;
        currentStep = 2;
        break;
      case 'READY_TO_PICKUP':
      case 'READY':
        statusColor = ThemeConfig.colorSuccess;
        statusText = 'Siap Diambil';
        statusIcon = Icons.shopping_bag;
        currentStep = 3;
        break;
      case 'ON_DELIVERY':
        statusColor = Colors.blue;
        statusText = 'Sedang Diantar';
        statusIcon = Icons.delivery_dining;
        currentStep = 3;
        break;
      case 'COMPLETED':
      case 'DELIVERED':
        statusColor = ThemeConfig.colorSuccess;
        statusText = 'Selesai';
        statusIcon = Icons.check_circle;
        currentStep = 4;
        break;
      case 'CANCELLED':
      case 'REJECTED':
        statusColor = ThemeConfig.colorError;
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
      backgroundColor: ThemeConfig.beigeBackground,
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
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status Timeline (Simplified)
              if (status != 'CANCELLED' && status != 'REJECTED')
                Container(
                  margin: EdgeInsets.only(bottom: 16 * scale),
                  padding: EdgeInsets.all(16 * scale),
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
                      _buildStep(3, currentStep,
                          type == 'DELIVERY' ? 'Diantar' : 'Siap'),
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
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
                                    fontSize: 18 * scale,
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
                                                fontSize: 12 * scale),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.copy,
                                              size: 12, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                    if (_order['createdAt'] != null)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(top: 2 * scale),
                                        child: Text(
                                          DateFormat('dd MMM yyyy, HH:mm')
                                              .format(DateTime.parse(
                                                  _order['createdAt']
                                                      .toString())),
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11 * scale),
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
                        padding: EdgeInsets.all(24 * scale),
                        child: Column(
                          children: [
                            Text(
                              'Kode Pengambilan',
                              style: TextStyle(
                                  fontSize: 14 * scale,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12 * scale),
                            Container(
                              padding: EdgeInsets.all(16 * scale),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 2),
                              ),
                              child: QrImageView(
                                data: pickupCode.toString(),
                                version: QrVersions.auto,
                                size: 180.0 * scale,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            Text(
                              pickupCode.toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24 * scale,
                                  letterSpacing: 4),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'Tunjukkan QR ini ke kasir',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12 * scale),
                            ),
                          ],
                        ),
                      )
                    ] else if (status == 'CANCELLED' ||
                        status == 'REJECTED') ...[
                      Padding(
                        padding: EdgeInsets.all(24 * scale),
                        child: Column(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 50 * scale,
                                color: ThemeConfig.colorError
                                    .withValues(alpha: 0.2)),
                            SizedBox(height: 8 * scale),
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

              SizedBox(height: 24 * scale),

              // 3. Store Info
              Text('Informasi Toko',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16 * scale)),
              SizedBox(height: 12 * scale),
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50 * scale,
                      height: 50 * scale,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          color: ThemeConfig.brandColor),
                    ),
                    SizedBox(width: 16 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName ?? 'Nama Toko',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * scale),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            storeAddress ?? 'Alamat tidak tersedia',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13 * scale),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map,
                              color: ThemeConfig.brandColor),
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

              if (type == 'DELIVERY') ...[
                SizedBox(height: 24 * scale),
                Text('Informasi Pengiriman',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16 * scale)),
                SizedBox(height: 12 * scale),
                Container(
                  padding: EdgeInsets.all(16 * scale),
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
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on,
                            color: Colors.blue.shade700),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat Tujuan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * scale),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              deliveryAddress,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13 * scale),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24 * scale),

              // 4. Order Items
              Text('Rincian Pesanan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16 * scale)),
              SizedBox(height: 12 * scale),
              Container(
                padding: EdgeInsets.all(16 * scale),
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

                        final isCompleted =
                            status == 'COMPLETED' || status == 'DELIVERED';

                        return InkWell(
                          onTap: () {
                            // Navigate to Product Detail
                            // Reconstruct product object from item
                            final productMap = item['product'] is Map
                                ? Map<String, dynamic>.from(item['product'])
                                : <String, dynamic>{};

                            // Ensure ID is present
                            if (productMap['id'] == null) {
                              productMap['id'] = item['productId'];
                            }
                            if (productMap['name'] == null) {
                              productMap['name'] = prodName;
                            }
                            if (productMap['sellingPrice'] == null) {
                              productMap['sellingPrice'] = price;
                            }
                            if (productMap['imageUrl'] == null) {
                              productMap['imageUrl'] = imageUrl;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: productMap,
                                  storeId: store is Map
                                      ? store['id']
                                      : (item['storeId'] ?? ''),
                                  storeName: storeName ?? 'Toko',
                                  storeAddress: storeAddress,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60 * scale,
                                    height: 60 * scale,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: resolvedImage.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(resolvedImage,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey)),
                                          )
                                        : const Icon(Icons.fastfood,
                                            color: Colors.grey),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prodName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14 * scale),
                                        ),
                                        SizedBox(height: 4 * scale),
                                        Text(
                                          '$qty x ${_formatCurrency(price)}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12 * scale),
                                        ),
                                        if (note != null && note.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: 4 * scale),
                                            child: Text(
                                              'Catatan: $note',
                                              style: TextStyle(
                                                  color: Colors
                                                      .orange.shade700,
                                                  fontSize: 11 * scale,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(total),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14 * scale),
                                  ),
                                ],
                              ),
                            if (isCompleted)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 8 * scale, left: 72 * scale),
                                child: GestureDetector(
                                    onTap: () {
                                      // Same navigation logic
                                      final productMap = item['product'] is Map
                                          ? Map<String, dynamic>.from(
                                              item['product'])
                                          : <String, dynamic>{};
                                      if (productMap['id'] == null) {
                                        productMap['id'] = item['productId'];
                                      }
                                      if (productMap['name'] == null) {
                                        productMap['name'] = prodName;
                                      }
                                      if (productMap['sellingPrice'] == null) {
                                        productMap['sellingPrice'] = price;
                                      }
                                      if (productMap['imageUrl'] == null) {
                                        productMap['imageUrl'] = imageUrl;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            product: productMap,
                                            storeId: store is Map
                                                ? store['id']
                                                : (item['storeId'] ?? ''),
                                            storeName: storeName ?? 'Toko',
                                            storeAddress: storeAddress,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Beri Ulasan',
                                      style: TextStyle(
                                        color: ThemeConfig.brandColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12 * scale,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 16 * scale),
                      child: const Divider(thickness: 1),
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
                    if ((_order['deliveryFee'] as num? ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      _buildPaymentRow(
                          'Ongkos Kirim', (_order['deliveryFee'] as num?) ?? 0),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * scale)),
                        Text(
                          _formatCurrency(_order['totalAmount'] as num? ?? 0),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18 * scale,
                              color: ThemeConfig.brandColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40 * scale),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BuyerBottomNav(
        selectedIndex: 1,
        onSelected: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildPaymentRow(String label, num value) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 13 * scale)),
        Text(_formatCurrency(value),
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13 * scale)),
      ],
    );
  }

  Widget _buildStep(int step, int currentStep, String label) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    final isActive = step <= currentStep;
    final isCompleted = step < currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              color: isActive ? ThemeConfig.brandColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Center(
                    child: Text(
                      step.toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10 * scale,
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
