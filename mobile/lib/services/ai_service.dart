import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rana_merchant/data/local/database_helper.dart';

class AiService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> generateDailyInsight() async {
    try {
      // 1. ANALYZE STOCK (Priority: CRITICAL)
      // Real data from local database
      final lowStockItems = await _db.getLowStockProducts(threshold: 5);

      if (lowStockItems.isNotEmpty) {
        final item = lowStockItems.first;
        return {
          'type': 'ALERT',
          'icon': 'alert',
          'short': 'Stok Menipis!',
          'title': 'Restock ${item['name']}',
          'message':
              'Stok ${item['name']} tersisa ${item['stock']}. Segera belanja agar tidak kehabisan.',
          'action': 'KULAKAN',
          'data': item
        };
      }

      // 2. DEAD STOCK ANALYSIS (Priority: HIGH)
      // Products not sold in last 7 days with stock > 5
      final deadStock = await _db.getUnsoldProducts(
        limit: 1,
        minStock: 5,
        start: DateTime.now().subtract(const Duration(days: 7)),
      );

      if (deadStock.isNotEmpty) {
        final item = deadStock.first;
        return {
          'type': 'TIP',
          'icon': 'percent',
          'short': 'Rekomendasi Promo',
          'title': 'Promo ${item['name']}',
          'message':
              '${item['name']} belum terjual minggu ini. Coba buat "Paket Hemat" atau diskon untuk menarik pembeli.',
          'action': 'PROMO', // We can navigate to product edit or marketing
          'data': item
        };
      }

      // 3. SALES TREND (Priority: MEDIUM)
      // Compare Yesterday vs Day Before
      final now = DateTime.now();
      final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
      final yesterdayEnd =
          DateTime(now.year, now.month, now.day - 1, 23, 59, 59);

      final dayBeforeStart = DateTime(now.year, now.month, now.day - 2);
      final dayBeforeEnd =
          DateTime(now.year, now.month, now.day - 2, 23, 59, 59);

      final yesterdayReport =
          await _db.getSalesReport(start: yesterdayStart, end: yesterdayEnd);
      final dayBeforeReport =
          await _db.getSalesReport(start: dayBeforeStart, end: dayBeforeEnd);

      final ySales = (yesterdayReport['grossSales'] as num).toDouble();
      final dbSales = (dayBeforeReport['grossSales'] as num).toDouble();

      if (ySales > dbSales && dbSales > 0) {
        final increase =
            ((ySales - dbSales) / dbSales * 100).toStringAsFixed(0);
        return {
          'type': 'POSITIVE',
          'icon': 'trending_up',
          'short': 'Tren Positif',
          'title': 'Omzet Naik $increase% 🚀',
          'message':
              'Penjualan kemarin lebih tinggi dari sebelumnya. Pertahankan performa ini!',
          'action': 'REPORT'
        };
      } else if (ySales < dbSales && ySales > 0) {
        return {
          'type': 'INFO',
          'icon': 'trending_down',
          'short': 'Analisa Bisnis',
          'title': 'Evaluasi Penjualan',
          'message':
              'Penjualan kemarin sedikit menurun. Coba broadcast promo ke pelanggan setia via WhatsApp.',
          'action': 'MARKETING'
        };
      }

      // 4. FETCH REAL WEATHER (Priority: LOW - Contextual)
      // Free API from Open-Meteo (No Key required) - Location: Jakarta (Default)
      try {
        final weatherResponse = await _dio.get(
            'https://api.open-meteo.com/v1/forecast?latitude=-6.2088&longitude=106.8456&current_weather=true');
        if (weatherResponse.statusCode == 200) {
          final weatherCode =
              weatherResponse.data['current_weather']['weathercode'];
          // Codes: 0=Clear, 1-3=Cloudy, 51-67=Rain, 71+=Snow/Heavier
          bool isRain = weatherCode >= 51;

          if (isRain) {
            return {
              'type': 'INFO',
              'icon': 'rain',
              'short': 'Hujan 🌧️',
              'title': 'Strategi Hujan',
              'message':
                  'Terdeteksi hujan di area Jakarta. Pelanggan cenderung memesan via online. Rekomendasi: Aktifkan promo "Ongkir Hemat".',
              'action': 'NONE'
            };
          } else {
            return {
              'type': 'INFO',
              'icon': 'sun',
              'short': 'Cerah ☀️',
              'title': 'Cuaca Cerah',
              'message':
                  'Cuaca cerah mendukung traffic offline. Optimalkan display produk dingin (Minuman) di etalase depan.',
              'action': 'NONE'
            };
          }
        }
      } catch (e) {
        debugPrint('Weather fetch failed: $e');
      }

      // 5. DEFAULT INSIGHT (Fallback)
      return {
        'type': 'INFO',
        'icon': 'chart',
        'short': 'Analisa Bisnis',
        'title': 'Tips Sukses',
        'message':
            'Ingin omzet naik? Coba pelajari laporan penjualan untuk mengetahui jam sibuk toko Anda.',
        'action': 'REPORT'
      };
    } catch (e) {
      return {
        'type': 'INFO',
        'icon': 'robot',
        'short': 'Rana AI',
        'title': 'Selamat Datang',
        'message':
            'Rana AI siap membantu menganalisa bisnis Anda secara otomatis.',
        'action': 'NONE'
      };
    }
  }
}
