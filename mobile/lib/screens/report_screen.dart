import 'dart:async'; // [NEW]
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart'; // [FIX] Added import
import 'package:rana_merchant/screens/expense_screen.dart';
import 'package:rana_merchant/services/sync_service.dart'; // [NEW]
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _categorySales = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _lowStock = [];
  List<Map<String, dynamic>> _expenses = []; // [NEW]
  List<Map<String, dynamic>> _expenseCategories = []; // [NEW]
  int _touchedIndex = -1; // [NEW] For Pie Chart interaction
  int _touchedExpenseIndex = -1; // [NEW] For Expense Pie Chart interaction
  int? _dailyTarget;
  double _todaySales = 0;

  final currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String formatCurrency(dynamic v) {
    num? numVal;
    if (v is num) {
      numVal = v;
    } else if (v is String) {
      numVal = num.tryParse(v);
    }
    final doubleVal = (numVal as num?)?.toDouble() ?? 0.0;
    final safeVal = doubleVal.isFinite ? doubleVal : 0.0;
    return currency.format(safeVal);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadDailyTarget();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Ensure API token is set from AuthProvider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null && token.isNotEmpty) {
        ApiService().setToken(token);
      }

      final start =
          DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final localSummary =
          await DatabaseHelper.instance.getSalesReport(start: start, end: end);
      final top = await DatabaseHelper.instance
          .getTopSellingProductsDetailed(limit: 5, start: start, end: end);
      final categories = await DatabaseHelper.instance
          .getSalesByCategory(start: start, end: end);
      final payments = await DatabaseHelper.instance
          .getSalesByPaymentMethod(start: start, end: end);
      final lowStock =
          await DatabaseHelper.instance.getLowStockProducts(threshold: 5);
      final expenses =
          await DatabaseHelper.instance.getExpenses(start: start, end: end);
      final remotePnl = await ApiService().getProfitLoss(
          startDate: start.toIso8601String().split('T')[0],
          endDate: end.toIso8601String().split('T')[0]);
      final analytics = await ApiService().getAnalytics(
          startDate: start.toIso8601String().split('T')[0],
          endDate: end.toIso8601String().split('T')[0]);

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day, 0, 0, 0);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final todaySummary = await DatabaseHelper.instance
          .getSalesReport(start: todayStart, end: todayEnd);
      final todayRemote = await ApiService()
          .getDashboardStats(date: todayStart.toIso8601String().split('T')[0]);

      // Process Expense Categories
      final expenseCatMap = <String, double>{};
      for (var e in expenses) {
        final cat = e['category'] as String? ?? 'Lain-lain';
        final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
        expenseCatMap[cat] = (expenseCatMap[cat] ?? 0) + amt;
      }
      final processedExpenseCats = expenseCatMap.entries
          .map((e) => {'category': e.key, 'total': e.value})
          .toList();
      processedExpenseCats.sort(
          (a, b) => (b['total'] as double).compareTo(a['total'] as double));

      if (mounted) {
        setState(() {
          final remotePnlData = Map<String, dynamic>.from(remotePnl['pnl'] ?? {});
          final remoteRevenue = (remotePnlData['revenue'] as num?)?.toDouble() ?? 0.0;
          final remoteNet = (remotePnlData['netProfit'] as num?)?.toDouble() ?? 0.0;
          final remoteExp = (remotePnlData['totalExpenses'] as num?)?.toDouble() ?? 0.0;
          final remoteSummary = Map<String, dynamic>.from(analytics['summary'] ?? {});
          final remoteTrend = List<Map<String, dynamic>>.from(analytics['trend'] ?? const []);
          final remoteTopRaw = List<Map<String, dynamic>>.from(analytics['topProducts'] ?? const []);
          final remoteCatsRaw = List<Map<String, dynamic>>.from(analytics['categorySales'] ?? const []);
          final remotePaysRaw = List<Map<String, dynamic>>.from(analytics['paymentMethods'] ?? const []);
          final remoteLowRaw = List<Map<String, dynamic>>.from(analytics['lowStock'] ?? const []);
          final remoteExpensesMap = Map<String, dynamic>.from(analytics['expenses'] ?? {});
          final remoteExpenseCats = remoteExpensesMap.entries
              .map((e) => {'category': e.key, 'total': (e.value as num?)?.toDouble() ?? 0.0})
              .toList();
          _summary = {
            'grossSales': ((localSummary['grossSales'] as num?)?.toDouble() ?? 0.0) > 0
                ? (localSummary['grossSales'] as num?)?.toDouble() ?? 0.0
                : ((remoteSummary['revenue'] as num?)?.toDouble() ?? remoteRevenue),
            'netProfit': ((localSummary['netProfit'] as num?)?.toDouble() ?? 0.0) > 0
                ? (localSummary['netProfit'] as num?)?.toDouble() ?? 0.0
                : ((remoteSummary['netProfit'] as num?)?.toDouble() ?? remoteNet),
            'totalExpenses': ((localSummary['totalExpenses'] as num?)?.toDouble() ?? 0.0) > 0
                ? (localSummary['totalExpenses'] as num?)?.toDouble() ?? 0.0
                : ((remoteSummary['totalExpenses'] as num?)?.toDouble() ?? remoteExp),
            'totalTransactions': localSummary['totalTransactions'] ?? remoteSummary['totalTransactions'] ?? 0,
            'averageOrderValue': localSummary['averageOrderValue'] ?? remoteSummary['averageOrderValue'] ?? 0,
            'trend': (localSummary['trend'] is List && (localSummary['trend'] as List).isNotEmpty)
                ? localSummary['trend']
                : remoteTrend
          };

          final remoteTop = remoteTopRaw
              .map((e) => {
                    'name': (e['product'] is Map
                            ? (e['product']['name'] ?? '')
                            : (e['name'] ?? ''))
                        .toString(),
                    'totalQty': (e['quantity'] as num?)?.toInt() ??
                        (e['quantitySold'] as num?)?.toInt() ??
                        0
                  })
              .toList();
          final remoteCats = remoteCatsRaw
              .map((e) => {
                    'category': e['category']?.toString() ?? '',
                    'totalSales': (e['revenue'] as num?)?.toDouble() ?? 0.0
                  })
              .toList();
          final remotePays = remotePaysRaw
              .map((e) => {
                    'paymentMethod': e['method']?.toString() ?? 'UNKNOWN',
                    'totalAmount': (e['total'] as num?)?.toDouble() ?? 0.0
                  })
              .toList();
          final remoteLow = remoteLowRaw
              .map((e) => {
                    'name': (e['product'] is Map
                            ? (e['product']['name'] ?? '')
                            : (e['name'] ?? ''))
                        .toString()
                  })
              .toList();
          _topProducts =
              remoteTop.isNotEmpty ? remoteTop : List<Map<String, dynamic>>.from(top);
          _categorySales = remoteCats.isNotEmpty
              ? remoteCats
              : List<Map<String, dynamic>>.from(categories);
          _paymentMethods = remotePays.isNotEmpty
              ? remotePays
              : List<Map<String, dynamic>>.from(payments);
          _lowStock = remoteLow.isNotEmpty
              ? remoteLow
              : List<Map<String, dynamic>>.from(lowStock);
          _expenses = List<Map<String, dynamic>>.from(expenses);
          _expenseCategories = remoteExpenseCats.isNotEmpty ? remoteExpenseCats : processedExpenseCats;
          final localToday =
              (todaySummary['grossSales'] as num?)?.toDouble() ?? 0.0;
          final remoteToday = (Map<String, dynamic>.from(
                      todayRemote['financials'] ?? {})['totalSales'] as num?)
                  ?.toDouble() ??
              0.0;
          _todaySales = localToday == 0.0 ? remoteToday : localToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchLocalOnly() async {
    final start =
        DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final end =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final summary =
        await DatabaseHelper.instance.getSalesReport(start: start, end: end);
    final top = await DatabaseHelper.instance
        .getTopSellingProductsDetailed(limit: 5, start: start, end: end);
    final categories = await DatabaseHelper.instance
        .getSalesByCategory(start: start, end: end);
    final payments = await DatabaseHelper.instance
        .getSalesByPaymentMethod(start: start, end: end);
    final lowStock =
        await DatabaseHelper.instance.getLowStockProducts(threshold: 5);
    final expenses =
        await DatabaseHelper.instance.getExpenses(start: start, end: end);

    if (mounted) {
      setState(() {
        _summary = Map<String, dynamic>.from(summary);
        if (_summary['trend'] is List) {
          _summary['trend'] =
              List<Map<String, dynamic>>.from(_summary['trend']);
        }
        _topProducts = List<Map<String, dynamic>>.from(top);
        _categorySales = List<Map<String, dynamic>>.from(categories);
        _paymentMethods = List<Map<String, dynamic>>.from(payments);
        _lowStock = List<Map<String, dynamic>>.from(lowStock);
        _expenses = List<Map<String, dynamic>>.from(expenses);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDailyTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('daily_sales_target');
    if (!mounted) return;
    setState(() {
      _dailyTarget = value;
    });
  }

  Future<void> _saveDailyTarget(int? target) async {
    final prefs = await SharedPreferences.getInstance();
    if (target == null || target <= 0) {
      await prefs.remove('daily_sales_target');
    } else {
      await prefs.setInt('daily_sales_target', target);
    }
    if (!mounted) return;
    setState(() {
      _dailyTarget = target;
    });
  }

  void _showDailyTargetSheet() {
    final controller = TextEditingController(
        text: _dailyTarget != null && _dailyTarget! > 0
            ? _dailyTarget!.toString()
            : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text(
                  'Target Penjualan Harian',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan target omzet harian yang ingin dicapai.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target harian (Rp)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveDailyTarget(null);
                        },
                        child: const Text('Hapus Target'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final raw = controller.text.replaceAll('.', '');
                          final parsed = int.tryParse(raw);
                          Navigator.pop(context);
                          _saveDailyTarget(parsed);
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyTargetCard() {
    final target = _dailyTarget ?? 0;
    final progress = target > 0 ? (_todaySales / target).clamp(0.0, 2.0) : 0.0;
    final progressPct =
        target > 0 ? (_todaySales / target * 100).clamp(0.0, 999.0) : 0.0;
    final todayLabel = DateFormat('EEEE, dd MMM', 'id_ID').format(
      DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Hari Ini',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showDailyTargetSheet,
                child: const Text('Atur Target'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (target <= 0)
            const Text(
              'Belum ada target harian. Atur dulu supaya progress bisa dipantau.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tercapai',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(_todaySales),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D405B)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(target),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE07A5F)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE07A5F)),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${progressPct.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final items = <String>[];
    final grossSales = (_summary['grossSales'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (_summary['netProfit'] as num?)?.toDouble() ?? 0.0;

    if (grossSales > 0) {
      final marginPct = (netProfit / grossSales * 100);
      items.add(
          'Margin bersih periode ini sekitar ${marginPct.toStringAsFixed(1)}%.');
      if (marginPct < 5) {
        items.add(
            'Margin masih tipis, pertimbangkan naikkan harga atau negosiasi ulang harga beli.');
      } else if (marginPct > 25) {
        items.add(
            'Margin cukup sehat, bisa coba promo agresif di produk tertentu untuk dorong volume.');
      }
    }

    if (_topProducts.isNotEmpty) {
      final top = _topProducts.first;
      final name = top['name'] ?? '';
      final qty = (top['totalQty'] as num?)?.toInt() ?? 0;
      items.add(
          'Produk terlaris: $name ($qty terjual). Pastikan stok aman dan jadikan produk utama di etalase dan promosi.');
    }

    if (_expenseCategories.isNotEmpty) {
      final topExp = _expenseCategories.first;
      final label = _getCategoryLabel(topExp['category']);
      final total = (topExp['total'] as num?)?.toDouble() ?? 0.0;
      items.add(
          'Pengeluaran terbesar ada di kategori $label (${formatCurrency(total)}). Cek apakah ada biaya yang bisa dipangkas.');
    }

    if (_paymentMethods.length > 1) {
      double totalAmount = 0;
      double nonCash = 0;
      for (final pm in _paymentMethods) {
        final amount = (pm['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalAmount += amount;
        if (pm['paymentMethod'] != 'CASH') {
          nonCash += amount;
        }
      }
      if (totalAmount > 0 && nonCash > 0) {
        final share = nonCash / totalAmount * 100;
        items.add(
            'Pembayaran non-tunai menyumbang sekitar ${share.toStringAsFixed(1)}% omzet. Pertimbangkan dorong metode ini untuk pencatatan lebih rapi.');
      }
    }

    if (_lowStock.isNotEmpty) {
      final names = _lowStock
          .take(3)
          .map((e) => e['name']?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        items.add(
            'Stok menipis untuk: ${names.join(', ')}. Segera lakukan pembelian ulang agar tidak kehabisan saat permintaan naik.');
      }
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFE07A5F)),
              SizedBox(width: 8),
              Text(
                'Insight dari data periode ini',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme:
                  ColorScheme.light(primary: Theme.of(context).primaryColor),
            ),
            child: child!,
          );
        });

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'EXPENSE_PETTY':
        return Icons.wallet;
      case 'EXPENSE_OPERATIONAL':
        return Icons.bolt;
      case 'EXPENSE_PURCHASE':
        return Icons.inventory_2;
      case 'EXPENSE_SALARY':
        return Icons.badge;
      case 'EXPENSE_MARKETING':
        return Icons.campaign;
      case 'EXPENSE_RENT':
        return Icons.store;
      case 'EXPENSE_MAINTENANCE':
        return Icons.build;
      default:
        return Icons.more_horiz;
    }
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'EXPENSE_PETTY':
        return 'Petty Cash (Harian)';
      case 'EXPENSE_OPERATIONAL':
        return 'Operasional';
      case 'EXPENSE_PURCHASE':
        return 'Pembelian Stok';
      case 'EXPENSE_SALARY':
        return 'Gaji Karyawan';
      case 'EXPENSE_MARKETING':
        return 'Pemasaran';
      case 'EXPENSE_RENT':
        return 'Sewa Tempat';
      case 'EXPENSE_MAINTENANCE':
        return 'Perbaikan';
      case 'EXPENSE_OTHER':
        return 'Lain-lain';
      default:
        return category ?? '-';
    }
  }

  void _showExpenseDetail(Map<String, dynamic> expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final date = DateTime.tryParse(expense['date'] ?? '');
        final dateStr = date != null
            ? DateFormat('EEEE, d MMMM yyyy HH:mm').format(date)
            : '-';
        final imagePath = expense['imagePath'];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(expense['category']),
                        color: const Color(0xFFE07A5F), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getCategoryLabel(expense['category']),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        Text(formatCurrency((expense['amount'] as num?)?.toDouble() ?? 0.0),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE07A5F))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailItem(Icons.calendar_today, 'Tanggal', dateStr),
              const SizedBox(height: 16),
              _buildDetailItem(
                  Icons.notes, 'Keterangan', expense['description'] ?? '-'),
              if (imagePath != null) ...[
                const SizedBox(height: 24),
                const Text('Bukti Foto:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 100,
                      color: Colors.grey[100],
                      child: const Center(child: Text('File tidak ditemukan')),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteExpense(expense['id']),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.shade200),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close bottom sheet
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ExpenseScreen(expenseToEdit: expense)),
                        );
                        if (result == true) {
                          _fetchData(); // Refresh list
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFE07A5F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('Tutup', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengeluaran?'),
        content: const Text(
            'Data yang dihapus tidak dapat dikembalikan. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pop(context); // Close bottom sheet
      setState(() => _isLoading = true);
      await DatabaseHelper.instance.deleteExpense(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pengeluaran dihapus'),
            backgroundColor: Colors.redAccent));
      }
      _fetchData();
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 15, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Soft Beige
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to Expense Screen
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExpenseScreen()));
          if (result == true) _fetchData(); // Refresh if expense added
        },
        label: const Text('Catat Pengeluaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        icon: const Icon(Icons.add_card, size: 24),
        backgroundColor: const Color(0xFFE07A5F),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                // [FIX] Switch to CustomScrollView for SliverAppBar
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFFFFF8F0),
                    iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
                    title: const Text('Laporan Bisnis',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE07A5F))),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickDateRange,
                        tooltip: 'Pilih Tanggal',
                      ),
                      IconButton(
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sinkronisasi Produk',
                        onPressed: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Sinkronisasi produk...')));
                            await ApiService().fetchAndSaveProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Produk tersinkron. Laporan diperbarui.')));
                            await _fetchData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Gagal sinkronisasi: $e'),
                                backgroundColor: Colors.red));
                          }
                        },
                      ),
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 16.0, left: 8.0),
                          child: Text(
                            '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                            style: const TextStyle(
                                color: Color(0xFFE07A5F),
                                fontWeight: FontWeight.w600), // Brand text
                          ),
                        ),
                      )
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: const Color(0xFFFFF8F0),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildDailyTargetCard()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 16),

                        _buildSummaryCards()
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        _buildInsightsCard()
                            .animate()
                            .fadeIn(delay: 150.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                                child: _buildStatTile(
                                    'Total Transaksi',
                                    '${_summary['totalTransactions']}',
                                    Icons.receipt_long)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatTile(
                                    'Rata-rata Order',
                                    currency
                                        .format(_summary['averageOrderValue']),
                                    Icons.shopping_basket_outlined)),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 32),

                        // [NEW] Low Stock Alert
                        if (_lowStock.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Color(0xFFDC2626)),
                                    SizedBox(width: 8),
                                    Text('Stok Menipis!',
                                        style: TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._lowStock
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(e['name'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text('${e['stock']} tersisa',
                                                  style: const TextStyle(
                                                      color: Color(0xFFDC2626),
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).shake(),
                          const SizedBox(height: 32),
                        ],

                        // 2. Main Chart Section
                        const Text('Tren Pemasukan & Pengeluaran',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 16),
                        Container(
                          height: 340, // Increased height for legend
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            children: [
                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildChartLegend(
                                      'Penjualan', const Color(0xFF4F46E5)),
                                  const SizedBox(width: 16),
                                  _buildChartLegend(
                                      'Pengeluaran', const Color(0xFFEF4444)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _buildSalesChart(_summary['trend']
                                    as List<Map<String, dynamic>>),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).scale(),

                        const SizedBox(height: 32),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3. Category Pie Chart
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kategori Terlaris',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 250,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: _buildCategoryPieChart(),
                                  ),
                                ],
                              ),
                            ),
                            if (MediaQuery.of(context).size.width > 600)
                              const SizedBox(width: 24),
                            // 4. Payment Methods (Show on side for desktop, below for mobile?)
                            // For simplicity in this responsive view logic, we just stack them or use Expanded on wide
                            if (MediaQuery.of(context).size.width > 600)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Metode Pembayaran',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    const SizedBox(height: 16),
                                    _buildPaymentMethodsList(),
                                  ],
                                ),
                              )
                          ],
                        ).animate().fadeIn(delay: 500.ms),

                        if (MediaQuery.of(context).size.width <= 600) ...[
                          const SizedBox(height: 32),
                          const Text('Metode Pembayaran',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 16),
                          _buildPaymentMethodsList(),
                        ],

                        const SizedBox(height: 32),

                        const SizedBox(height: 32),

                        // [NEW] Expense List & Chart
                        if (_expenses.isNotEmpty) ...[
                          const Divider(height: 48),

                          // Expense Analysis Section
                          const Text('Analisa Pengeluaran',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Expense Pie Chart
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 250,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: _buildExpensePieChart(),
                                ),
                              ),
                              // Legend for Expenses (Only on wider screens or if needed)
                              if (MediaQuery.of(context).size.width > 600) ...[
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: _expenseCategories.map((e) {
                                      final colors = [
                                        const Color(0xFFE63946),
                                        const Color(0xFFF4A261),
                                        const Color(0xFFE9C46A),
                                        const Color(0xFF2A9D8F),
                                        const Color(0xFF264653),
                                      ];
                                      final idx = _expenseCategories.indexOf(e);
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              colors[idx % colors.length],
                                          radius: 6,
                                        ),
                                        title: Text(
                                            _getCategoryLabel(e['category']),
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        trailing: Text(
                                            formatCurrency((e['total'] as num?)?.toDouble() ?? 0.0),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        dense: true,
                                      );
                                    }).toList(),
                                  ),
                                )
                              ]
                            ],
                          ).animate().fadeIn(delay: 520.ms),

                          const SizedBox(height: 32),

                          const Text('Riwayat Pengeluaran',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: _expenses.map((e) {
                                final date = DateTime.tryParse(e['date'] ?? '');
                                final dateStr = date != null
                                    ? DateFormat('dd MMM HH:mm').format(date)
                                    : '-';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFFFF8F0),
                                    child: Icon(_getCategoryIcon(e['category']),
                                        color: const Color(0xFFE07A5F),
                                        size: 20),
                                  ),
                                  title: Text(e['description'] ?? 'Pengeluaran',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(dateStr,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      if (e['imagePath'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.attach_file,
                                                  size: 14,
                                                  color: Color(0xFFE07A5F)),
                                              const SizedBox(width: 4),
                                              Text('Lihat Bukti',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: const Color(
                                                          0xFFE07A5F),
                                                      decoration: TextDecoration
                                                          .underline)),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '- ${formatCurrency((e['amount'] as num?)?.toDouble() ?? 0.0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE07A5F)),
                              ),
                              onTap: () => _showExpenseDetail(e),
                                );
                              }).toList(),
                            ),
                          ).animate().fadeIn(delay: 550.ms),
                          const SizedBox(height: 32),
                        ],

                        // 5. Top Products Table
                        const Text('Produk Terlaris',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: _buildProductSalesChart(),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: _topProducts.isEmpty
                                      ? [
                                          const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              'Belum ada data penjualan produk',
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        ]
                                      : _topProducts
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          return ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundColor: index < 3
                                                  ? const Color(0xFFFFF8F0)
                                                  : const Color(0xFFF3F4F6),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: index < 3
                                                      ? const Color(0xFFE07A5F)
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              item['name'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${item['totalQty']} terjual',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            trailing: Text(
                                              currency
                                                  .format(item['totalRevenue']),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3D405B),
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 48),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return Column(
      children: _paymentMethods.map((pm) {
        final isCash = pm['paymentMethod'] == 'CASH';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: isCash
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(
                    isCash ? Icons.payments_outlined : Icons.qr_code_scanner,
                    color: isCash ? Colors.green : Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pm['paymentMethod'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${pm['count']} Transaksi',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                formatCurrency((pm['totalAmount'] as num?)?.toDouble() ?? 0.0),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductSalesChart() {
    if (_topProducts.isEmpty) {
      return const Center(child: Text('Belum ada data grafik produk'));
    }

    final spots = <BarChartGroupData>[];
    double maxRevenue = 0;
    final colors = [
      const Color(0xFFE07A5F),
      const Color(0xFF81B29A),
      const Color(0xFFF2CC8F),
      const Color(0xFF3D405B),
      const Color(0xFFE07A5F),
    ];

    for (int i = 0; i < _topProducts.length; i++) {
      final item = _topProducts[i];
      final revenue = (item['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
      }
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              gradient: LinearGradient(
                colors: [
                  colors[i % colors.length],
                  colors[i % colors.length].withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(6),
              width: 14,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue <= 0 ? 1 : maxRevenue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue <= 0 ? 1 : maxRevenue / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFF3F4F6),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = _topProducts[groupIndex];
              final name = item['name'] as String? ?? '';
              final qty = (item['totalQty'] as num?)?.toInt() ?? 0;
              final revenue = (item['totalRevenue'] as num?)?.toDouble() ?? 0.0;
              return BarTooltipItem(
                '$name\n',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
                children: [
                  TextSpan(
                    text: '${formatCurrency(revenue)}\n',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 10),
                  ),
                  TextSpan(
                    text: '$qty terjual',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        fontSize: 10),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value == 0 ? '0' : '${(value / 1000).round()}k',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _topProducts.length) {
                  return const SizedBox.shrink();
                }
                final name = _topProducts[idx]['name'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: spots,
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    if (_categorySales.isEmpty)
      return const Center(child: Text('Belum ada data'));

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _categorySales.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final value = (data['totalSales'] as num?)?.toDouble() ?? 0.0;
              final isTouched = index == _touchedIndex;
              final radius = isTouched ? 60.0 : 50.0;
              final totalGross =
                  (_summary['grossSales'] as num?)?.toDouble() ?? 0.0;

              final colors = [
                const Color(0xFFE07A5F), // Terra Cotta
                const Color(0xFF81B29A), // Sage Green
                const Color(0xFFF2CC8F), // Sunset Yellow
                const Color(0xFF3D405B), // Deep Blue
                const Color(0xFFE07A5F).withOpacity(0.7),
              ];

              return PieChartSectionData(
                color: colors[index % colors.length],
                value: value,
                title: isTouched
                    ? formatCurrency(value)
                    : '${((value / (totalGross > 0 ? totalGross : 1.0)) * 100).toStringAsFixed(0)}%',
                radius: radius,
                titleStyle: TextStyle(
                    fontSize: isTouched ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                badgeWidget: isTouched ? _buildBadge(data['category']) : null,
                badgePositionPercentageOffset: .98,
              );
            }).toList(),
          ),
        ),
        // Center Info
        if (_touchedIndex != -1 && _touchedIndex < _categorySales.length)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_categorySales[_touchedIndex]['category'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              // Text(currency.format(_categorySales[_touchedIndex]['totalSales']), style: const TextStyle(fontSize: 10, color: Colors.indigo)),
            ],
          )
        else
          const Text('Total',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpensePieChart() {
    if (_expenseCategories.isEmpty)
      return const Center(child: Text('Belum ada data pengeluaran'));

    final totalExp = (_summary['totalExpenses'] as num?)?.toDouble() ?? 1.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedExpenseIndex = -1;
                    return;
                  }
                  _touchedExpenseIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _expenseCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final value = (data['total'] as num?)?.toDouble() ?? 0.0;
              final isTouched = index == _touchedExpenseIndex;
              final radius = isTouched ? 60.0 : 50.0;

              // Different color palette for expenses (Red/Orange based)
              final colors = [
                const Color(0xFFE63946), // Red
                const Color(0xFFF4A261), // Sandy Brown
                const Color(0xFFE9C46A), // Saffron
                const Color(0xFF2A9D8F), // Persian Green (Contrast)
                const Color(0xFF264653), // Charcoal
              ];

              return PieChartSectionData(
                color: colors[index % colors.length],
                value: value,
                title: isTouched
                    ? formatCurrency(value)
                : '${((value / totalExp) * 100).toStringAsFixed(0)}%',
                radius: radius,
                titleStyle: TextStyle(
                    fontSize: isTouched ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                badgeWidget: isTouched
                    ? _buildBadge(_getCategoryLabel(data['category']))
                    : null,
                badgePositionPercentageOffset: .98,
              );
            }).toList(),
          ),
        ),
        // Center Info
        if (_touchedExpenseIndex != -1 &&
            _touchedExpenseIndex < _expenseCategories.length)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  _getCategoryLabel(
                      _expenseCategories[_touchedExpenseIndex]['category']),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          )
        else
          const Text('Total',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: Text(text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGradientCard(
      String title, double value, List<Color> colors, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: colors.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Icon(icon, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(value),
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final itemWidth =
            isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
        children: [
          SizedBox(
              width: itemWidth,
              child: _buildGradientCard(
                  'Omzet',
                  (_summary['grossSales'] as num?)?.toDouble() ?? 0.0,
                  const [Color(0xFF4F46E5), Color(0xFF818CF8)],
                  Icons.attach_money)),
          SizedBox(
              width: itemWidth,
              child: _buildGradientCard(
                    'Biaya',
                    _summary['totalExpenses'] ?? 0.0,
                    const [Color(0xFFEF4444), Color(0xFFF87171)],
                    Icons.money_off)),
            SizedBox(width: itemWidth, child: _buildProfitCard()),
          ],
        );
      },
    );
  }

  Widget _buildProfitCard() {
    final omzet = (_summary['grossSales'] as num?)?.toDouble() ?? 0.0;
    final pengeluaran = (_summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final labaBersih = (_summary['netProfit'] as num?)?.toDouble() ?? 0.0;
    final hpp = (omzet - (labaBersih + pengeluaran)).clamp(0, double.infinity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final valueStyle = TextStyle(
            color: Colors.white,
            fontSize: isNarrow ? 11 : 12,
            fontWeight: FontWeight.w600);
        final labelStyle =
            TextStyle(color: Colors.white70, fontSize: isNarrow ? 11 : 12);
        final totalStyle = TextStyle(
            color: Colors.white,
            fontSize: isNarrow ? 20 : 24,
            fontWeight: FontWeight.bold);

        Widget valueText(String s) => Flexible(
              child: Text(s,
                  style: valueStyle,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [
                  Color(0xFF81B29A),
                  Color(0xFFA5CDBA)
                ], // Sage Green variants
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF81B29A).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Laba Bersih',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const Icon(Icons.trending_up, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              Text(formatCurrency(labaBersih), style: totalStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Omzet', style: labelStyle)),
                  valueText(formatCurrency(omzet)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('HPP', style: labelStyle)),
                  valueText(formatCurrency(hpp)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('Pengeluaran', style: labelStyle)),
                  valueText(formatCurrency(pengeluaran)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Parse trend data for the chart
  // Data structure: [{date: 'YYYY-MM-DD', sales: 123.0, expenses: 50.0}, ...]
  Widget _buildSalesChart(List<Map<String, dynamic>> trendData) {
    if (trendData.isEmpty)
      return const Center(child: Text('Tidak ada data grafik'));

    // Map dates to 0..N indices for X axis
    List<FlSpot> salesSpots = [];
    List<FlSpot> expenseSpots = [];

    for (int i = 0; i < trendData.length; i++) {
      salesSpots.add(FlSpot(
          i.toDouble(), (trendData[i]['sales'] as num? ?? 0).toDouble()));
      expenseSpots.add(FlSpot(
          i.toDouble(), (trendData[i]['expenses'] as num? ?? 0).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100000,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < trendData.length) {
                    String dateStr = trendData[idx]['date'] ?? '';
                    // Format YYYY-MM-DD to dd/MM
                    try {
                      final date = DateTime.parse(dateStr);
                      // Only show some labels to avoid crowding if many points
                      if (trendData.length > 10 && idx % 2 != 0)
                        return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('dd/MM').format(date),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      );
                    } catch (_) {}
                  }
                  return const SizedBox();
                },
                interval: 1),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                  showTitles:
                      false)), // Hide Y axis numbers for cleaner look, use TouchTooltip
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Sales Line
          LineChartBarData(
            spots: salesSpots,
            isCurved: true,
            color: const Color(0xFF4F46E5),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4F46E5).withOpacity(0.1),
                  const Color(0xFF4F46E5).withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Expense Line
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: const Color(0xFFEF4444),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final isSales = touchedSpot.barIndex == 0;
                return LineTooltipItem(
                  '${isSales ? "Jual" : "Keluar"}: ${formatCurrency(touchedSpot.y)}',
                  TextStyle(
                      color: isSales
                          ? const Color(0xFFC7D2FE)
                          : const Color(0xFFFECaca),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
