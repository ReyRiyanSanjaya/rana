import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/screens/expense_screen.dart';

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
  int _touchedIndex = -1; // [NEW] For Pie Chart interaction

  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Align dates to start/end of day
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final summary = await DatabaseHelper.instance.getSalesReport(start: start, end: end);
      final top = await DatabaseHelper.instance.getTopSellingProducts(limit: 5);
      final categories = await DatabaseHelper.instance.getSalesByCategory(start: start, end: end);
      final payments = await DatabaseHelper.instance.getSalesByPaymentMethod(start: start, end: end);
      final lowStock = await DatabaseHelper.instance.getLowStockProducts(threshold: 5);
      final expenses = await DatabaseHelper.instance.getExpenses(start: start, end: end); // [NEW]

      if (mounted) {
        setState(() {
          _summary = Map<String, dynamic>.from(summary);
          // Ensure trend is strictly typed
          if (_summary['trend'] is List) {
             _summary['trend'] = List<Map<String, dynamic>>.from(_summary['trend']);
          }

          _topProducts = List<Map<String, dynamic>>.from(top);
          _categorySales = List<Map<String, dynamic>>.from(categories);
          _paymentMethods = List<Map<String, dynamic>>.from(payments);
          _lowStock = List<Map<String, dynamic>>.from(lowStock);
          _expenses = List<Map<String, dynamic>>.from(expenses); // [NEW]
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report: $e');
      if (mounted) {
         setState(() {
           _isLoading = false;
           // Provide fallback empty data to prevent UI crash
           _summary = {
             'totalTransactions': 0, 
             'grossSales': 0.0, 
             'netProfit': 0.0, 
             'totalExpenses': 0.0, // [FIX] Add fallback
             'averageOrderValue': 0.0, 
             'trend': <Map<String, dynamic>>[] // [FIX] Strictly typed empty list
           };
           _topProducts = [];
           _categorySales = [];
           _paymentMethods = [];
           _lowStock = [];
         });
      }
    }
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
            colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Cool Gray
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to Expense Screen
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()));
          if (result == true) _fetchData(); // Refresh if expense added
        },
        label: const Text('Catat Pengeluaran'),
        icon: const Icon(Icons.add_card),
        backgroundColor: const Color(0xFFEF4444),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView( // [FIX] Switch to CustomScrollView for SliverAppBar
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFFBF092F), // Red Brand
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: const Text('Laporan Bisnis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickDateRange,
                        tooltip: 'Pilih Tanggal',
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                          child: Text(
                            '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600), // White text
                          ),
                        ),
                      )
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                       background: Container(
                         decoration: const BoxDecoration(
                           gradient: LinearGradient(
                             colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter
                           )
                         ),
                       ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                   // 1. Executive Summary Cards
                   Row(
                     children: [
                       Expanded(child: _buildGradientCard('Omzet', _summary['grossSales'], const [Color(0xFF4F46E5), Color(0xFF818CF8)], Icons.attach_money)),
                       const SizedBox(width: 12),
                       Expanded(child: _buildGradientCard('Biaya', _summary['totalExpenses'] ?? 0.0, const [Color(0xFFEF4444), Color(0xFFF87171)], Icons.money_off)),
                       const SizedBox(width: 12),
                       Expanded(child: _buildGradientCard('Laba Bersih', _summary['netProfit'], const [Color(0xFF059669), Color(0xFF34D399)], Icons.trending_up)),
                     ],
                   ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                   
                   const SizedBox(height: 16),
                   
                   Row(
                     children: [
                       Expanded(child: _buildStatTile('Total Transaksi', '${_summary['totalTransactions']}', Icons.receipt_long)),
                       const SizedBox(width: 16),
                       Expanded(child: _buildStatTile('Rata-rata Order', currency.format(_summary['averageOrderValue']), Icons.shopping_basket_outlined)),
                     ],
                   ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                   const SizedBox(height: 32),
                   
                   // [NEW] Low Stock Alert
                   if (_lowStock.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text('Stok Menipis!', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._lowStock.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text('${e['stock']} tersisa', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).shake(),
                      const SizedBox(height: 32),
                   ],

                   // 2. Main Chart Section
                   const Text('Tren Penjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                   const SizedBox(height: 16),
                   Container(
                     height: 300,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                     ),
                     child: _buildSalesChart(_summary['trend'] as List<Map<String, dynamic>>),
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
                             const Text('Kategori Terlaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                             const SizedBox(height: 16),
                             Container(
                               height: 250,
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Colors.grey[200]!),
                               ),
                               child: _buildCategoryPieChart(),
                             ),
                           ],
                         ),
                       ),
                       if (MediaQuery.of(context).size.width > 600) const SizedBox(width: 24),
                       // 4. Payment Methods (Show on side for desktop, below for mobile?)
                       // For simplicity in this responsive view logic, we just stack them or use Expanded on wide
                       if (MediaQuery.of(context).size.width > 600) 
                         Expanded(
                           flex: 1,
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                               const SizedBox(height: 16),
                               _buildPaymentMethodsList(),
                             ],
                           ),
                         )
                     ],
                   ).animate().fadeIn(delay: 500.ms),
                   
                   if (MediaQuery.of(context).size.width <= 600) ...[
                      const SizedBox(height: 32),
                      const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      _buildPaymentMethodsList(),
                   ],

                   const SizedBox(height: 32),

                   const SizedBox(height: 32),
 
                   // [NEW] Expense List
                   if (_expenses.isNotEmpty) ...[
                      const Text('Riwayat Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                            final dateStr = date != null ? DateFormat('dd MMM HH:mm').format(date) : '-';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Icon(Icons.money_off, color: Colors.red.shade400, size: 20),
                              ),
                              title: Text(e['description'] ?? 'Pengeluaran', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: Text(
                                '- ${currency.format(e['amount'])}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            );
                          }).toList(),
                        ),
                      ).animate().fadeIn(delay: 550.ms),
                      const SizedBox(height: 32),
                   ],

                   // 5. Top Products Table
                   const Text('Produk Terlaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                   const SizedBox(height: 16),
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.grey[200]!),
                     ),
                     child: Column(
                       children: _topProducts.isEmpty 
                       ? [const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada data penjualan'))]
                       : _topProducts.asMap().entries.map((entry) {
                         final index = entry.key;
                         final item = entry.value;
                         return ListTile(
                           leading: CircleAvatar(
                             backgroundColor: index < 3 ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6),
                             child: Text('${index + 1}', style: TextStyle(color: index < 3 ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold)),
                           ),
                           title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                           subtitle: Text('${item['totalQty']} items terjual'),
                           trailing: Text(currency.format(item['totalRevenue']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                         );
                       }).toList(),
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
                  color: isCash ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle
                ),
                child: Icon(
                  isCash ? Icons.payments_outlined : Icons.qr_code_scanner, 
                  color: isCash ? Colors.green : Colors.blue
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pm['paymentMethod'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${pm['count']} Transaksi', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                currency.format(pm['totalAmount']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryPieChart() {
    if (_categorySales.isEmpty) return const Center(child: Text('Belum ada data'));

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
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _categorySales.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final value = (data['totalSales'] as num).toDouble();
              final isTouched = index == _touchedIndex;
              final radius = isTouched ? 60.0 : 50.0;
              
              final colors = [
                const Color(0xFF4F46E5),
                const Color(0xFFEC4899),
                const Color(0xFFF59E0B),
                const Color(0xFF10B981),
                const Color(0xFF6366F1),
              ];

              return PieChartSectionData(
                color: colors[index % colors.length],
                value: value,
                title: isTouched ? currency.format(value) : '${((value / _summary['grossSales']) * 100).toStringAsFixed(0)}%',
                radius: radius,
                titleStyle: TextStyle(
                  fontSize: isTouched ? 10 : 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
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
               Text(_categorySales[_touchedIndex]['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
               // Text(currency.format(_categorySales[_touchedIndex]['totalSales']), style: const TextStyle(fontSize: 10, color: Colors.indigo)),
            ],
          )
        else
          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );
  }

  Widget _buildGradientCard(String title, double value, List<Color> colors, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(icon, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(value),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
           Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
           const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
  
  // Parse trend data for the chart
  // Data structure: [{date: 'YYYY-MM-DD', dailyTotal: 123.0}, ...]
  Widget _buildSalesChart(List<Map<String, dynamic>> trendData) {
    if (trendData.isEmpty) return const Center(child: Text('Tidak ada data grafik'));
    
    // Map dates to 0..N indices for X axis
    List<FlSpot> spots = [];
    for (int i = 0; i < trendData.length; i++) {
      spots.add(FlSpot(i.toDouble(), (trendData[i]['dailyTotal'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false, 
          horizontalInterval: 100000,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                     );
                   } catch (_) {}
                }
                return const SizedBox();
              },
              interval: 1
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis numbers for cleaner look, use TouchTooltip
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4F46E5),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF4F46E5).withOpacity(0.2), const Color(0xFF4F46E5).withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: const Color(0xFF1F2937),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  currency.format(touchedSpot.y),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
