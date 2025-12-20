import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rana_pos/data/remote/api_service.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      // Reusing the Dashboard API we built for Web
      // In a real app, we might want a dedicated mobile endpoint
      // Mocking for now as the exact structure of "dashboard" endpoint might need adjustment for mobile chart
      
      // Simulate API call to GET /reports/dashboard
      await Future.delayed(const Duration(seconds: 1)); 
      
      setState(() {
        _data = {
           'grossSales': 1500000,
           'netSales': 1450000,
           'profit': 650000,
           'chartData': [5, 10, 8, 15, 12, 20, 18] // Last 7 days sales count mock
        };
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Statistik')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
           // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Omzet', 'Rp 1.5jt', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Laba Bersih', 'Rp 450rb', Colors.green)), // [UPDATED] Net Profit Label
              ],
            ),
          ),
          // Add Explanation Text
          const Padding(
             padding: EdgeInsets.symmetric(horizontal: 16),
             child: Text('*Laba Bersih = Omzet - HPP - Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 16),
               
               // Chart Section
               const Text('Tren Penjualan (7 Hari)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               const SizedBox(height: 16),
               SizedBox(
                 height: 250,
                 child: BarChart(
                   BarChartData(
                     gridData: const FlGridData(show: false),
                     titlesData: const FlTitlesData(
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     ),
                     borderData: FlBorderData(show: false),
                     barGroups: (_data!['chartData'] as List<int>).asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.indigo, width: 16)]
                        );
                     }).toList(),
                   )
                 ),
               )
            ],
          ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color.withOpacity(0.8), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
