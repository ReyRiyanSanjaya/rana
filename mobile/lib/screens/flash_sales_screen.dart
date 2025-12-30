import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

class FlashSalesScreen extends StatefulWidget {
  const FlashSalesScreen({super.key});

  @override
  State<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends State<FlashSalesScreen> {
  final _titleController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  bool _creating = false;
  bool _loading = false;
  List<dynamic> _sales = [];
  List<Map<String, dynamic>> _products = [];

  String _selectedSaleId = '';
  String? _selectedProductId;
  final _salePriceController = TextEditingController();
  final _maxQtyController = TextEditingController();
  final _saleStockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSales();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _salePriceController.dispose();
    _maxQtyController.dispose();
    _saleStockController.dispose();
    super.dispose();
  }

  Future<void> _ensureToken() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      ApiService().setToken(token);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      setState(() => _products = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);
    await _ensureToken();
    try {
      final sales = await ApiService().getMyFlashSales();
      setState(() => _sales = sales);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startAt = dt;
      } else {
        _endAt = dt;
      }
    });
  }

  Future<void> _createSale() async {
    if (_titleController.text.isEmpty || _startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan periode wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!(_startAt!.isBefore(_endAt!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai harus sebelum tanggal berakhir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _creating = true);
    await _ensureToken();
    try {
      await ApiService().createFlashSale(
        title: _titleController.text,
        startAt: _startAt!,
        endAt: _endAt!,
        items: const [],
      );
      _titleController.clear();
      setState(() {
        _startAt = null;
        _endAt = null;
      });
      await _loadSales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash Sale berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _addItem() async {
    if (_selectedSaleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Flash Sale terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedProductId == null || _selectedProductId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final salePrice = double.tryParse(_salePriceController.text);
    if (salePrice == null || salePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga sale harus valid dan > 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final maxQty = int.tryParse(_maxQtyController.text);
    final saleStock = int.tryParse(_saleStockController.text);
    await _ensureToken();
    try {
      await ApiService().addFlashSaleItem(
        saleId: _selectedSaleId,
        productId: _selectedProductId!,
        salePrice: salePrice,
        maxQtyPerOrder: maxQty,
        saleStock: saleStock,
      );
      _selectedProductId = null;
      _salePriceController.clear();
      _maxQtyController.clear();
      _saleStockController.clear();
      await _loadSales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(String saleId, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _ensureToken();
    try {
      await ApiService().deleteFlashSaleItem(saleId: saleId, itemId: itemId);
      await _loadSales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductPicker() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada produk tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Produk',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final price = NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(product['sellingPrice'] ?? 0);
                    final isSelected = _selectedProductId == product['id'].toString();
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProductId = product['id'].toString();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: product['imageUrl'] != null &&
                                      product['imageUrl'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['imageUrl'].toString(),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported,
                                                color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    price,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (product['stock'] != null)
                                    Text(
                                      'Stock: ${product['stock']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Selected Indicator
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSelectedProductName() {
    if (_selectedProductId == null) return '';
    final product = _products.firstWhere(
      (p) => p['id'].toString() == _selectedProductId,
      orElse: () => {},
    );
    return product['name']?.toString() ?? 'Produk tidak ditemukan';
  }

  String _getSelectedProductPrice() {
    if (_selectedProductId == null) return '';
    final product = _products.firstWhere(
      (p) => p['id'].toString() == _selectedProductId,
      orElse: () => {},
    );
    final price = product['sellingPrice'] ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _cancelSale(String saleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Flash Sale?'),
        content: const Text('Apakah Anda yakin ingin membatalkan flash sale ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _ensureToken();
    try {
      await ApiService().cancelFlashSale(saleId: saleId);
      await _loadSales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash Sale berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'APPROVED':
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'ENDED':
        color = Colors.grey;
        icon = Icons.event_busy;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Flash Sales',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFBF092F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0, // Default to Home
        onDestinationSelected: (idx) {
          if (idx == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (idx == 1) {
            // Navigate to History/Transaction
            Navigator.of(context).popUntil((route) => route.isFirst);
            // You can add navigation to history screen here if needed
          } else if (idx == 2) {
            // Navigate to Scan
            Navigator.of(context).popUntil((route) => route.isFirst);
            // You can add navigation to scan screen here if needed
          } else if (idx == 3) {
            // Navigate to Report
            Navigator.of(context).popUntil((route) => route.isFirst);
            // You can add navigation to report screen here if needed
          } else if (idx == 4) {
            // Navigate to Account
            Navigator.of(context).popUntil((route) => route.isFirst);
            // You can add navigation to account screen here if needed
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.red.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSales,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Create Flash Sale Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFFF6B6B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Buat Flash Sale Baru',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
            TextField(
              controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Flash Sale',
                        hintText: 'Contoh: Flash Sale Akhir Bulan',
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                          child: InkWell(
                            onTap: () => _pickDateTime(isStart: true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Mulai',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _startAt == null
                                        ? 'Pilih Tanggal'
                                        : fmt.format(_startAt!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                Expanded(
                          child: InkWell(
                            onTap: () => _pickDateTime(isStart: false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Berakhir',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
                                  Text(
                                    _endAt == null
                                        ? 'Pilih Tanggal'
                                        : fmt.format(_endAt!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _createSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _creating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.flash_on, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Buat Flash Sale',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

            const SizedBox(height: 24),

              // Add Item Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tambah Produk ke Flash Sale',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Flash Sale Dropdown - Simplified
            DropdownButtonFormField<String>(
              value: _selectedSaleId.isEmpty ? null : _selectedSaleId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Flash Sale',
                        prefixIcon: const Icon(Icons.local_offer),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: _sales.map((s) {
                        final start = DateTime.tryParse(s['startAt'] ?? '') ?? DateTime.now();
                        return DropdownMenuItem<String>(
                value: s['id'].toString(),
                          child: Text(
                            '${s['title'] ?? s['id'].toString()} - ${fmt.format(start)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
              onChanged: (val) => setState(() => _selectedSaleId = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    // Product Selection Button - Opens Dialog
                    InkWell(
                      onTap: _showProductPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
              children: [
                            const Icon(Icons.inventory_2, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedProductId == null
                                        ? 'Pilih Produk'
                                        : _getSelectedProductName(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: _selectedProductId == null
                                          ? Colors.grey.shade600
                                          : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedProductId != null)
                                    Text(
                                      _getSelectedProductPrice(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
            Row(
              children: [
                        Expanded(
                          child: TextField(
                            controller: _salePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Harga Flash Sale',
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxQtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Qty/Order',
                              prefixIcon: const Icon(Icons.shopping_cart),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _saleStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Flash Sale (Opsional)',
                        hintText: 'Kosongkan untuk unlimited',
                        prefixIcon: const Icon(Icons.inventory),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Tambah Produk',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: -0.1),

            const SizedBox(height: 24),

              // Sales List
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Daftar Flash Sale Saya',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!_loading && _sales.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada Flash Sale',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
            const SizedBox(height: 8),
                      Text(
                        'Buat flash sale pertama Anda sekarang!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
            if (!_loading && _sales.isNotEmpty)
                ..._sales.map((sale) {
                  final start = DateTime.tryParse(sale['startAt'] ?? '') ?? DateTime.now();
                  final end = DateTime.tryParse(sale['endAt'] ?? '') ?? DateTime.now();
                  final items = (sale['items'] ?? []) as List<dynamic>;
                  final status = sale['status'] ?? 'PENDING';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade50,
                                Colors.red.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale['title'] ?? sale['id'].toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                            children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '${fmt.format(start)} - ${fmt.format(end)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildStatusBadge(status),
                                  if (status == 'PENDING')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton.icon(
                                        onPressed: () => _cancelSale(sale['id'].toString()),
                                        icon: const Icon(Icons.cancel, size: 16),
                                        label: const Text('Batalkan'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Produk (${items.length})',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (items.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Belum ada produk',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          if (items.isNotEmpty)
                                ...items.map((it) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                it['product']?['name']
                                                        ?.toString() ??
                                                    it['productId']?.toString() ??
                                                    '-',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Rp ${NumberFormat('#,###').format((it['salePrice'] ?? 0).round())}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.green.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (it['maxQtyPerOrder'] != null &&
                                                      it['maxQtyPerOrder'] > 0)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'Max: ${it['maxQtyPerOrder']}',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          color: Colors.blue.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  if (it['saleStock'] != null)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'Stock: ${it['saleStock']}',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          color: Colors.orange.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                          onPressed: () => _deleteItem(
                                            sale['id'].toString(),
                                            it['id'].toString(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                        ],
                      ),
                    ),
                      ],
              ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                }),
          ],
          ),
        ),
      ),
    );
  }
}
