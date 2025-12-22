import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/constants.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for running SQLite tests on Desktop/Test Environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Category Logic Tests', () {
    test('AppConstants contains required categories', () {
      expect(AppConstants.productCategories, contains('Beverage'));
      expect(AppConstants.productCategories, contains('Food'));
      expect(AppConstants.productCategories, contains('All'));
    });

    test('DatabaseHelper stores and retrieves category', () async {
      final db = DatabaseHelper.instance;
      
      // 1. Insert Product with Category
      await db.insertProduct({
        'id': 'test-prod-1',
        'tenantId': 'tenant-A',
        'sku': 'SKU001',
        'name': 'Kopi Susu Tester',
        'sellingPrice': 15000.0,
        'costPrice': 10000.0,
        'trackStock': 1,
        'stock': 10,
        'category': 'Beverage'
      });

      // 2. Retrieve and Verify
      final products = await db.getAllProducts();
      final product = products.firstWhere((p) => p['id'] == 'test-prod-1');

      expect(product['name'], 'Kopi Susu Tester');
      expect(product['category'], 'Beverage');
    });

    test('DatabaseHelper defaults category to All if missing', () async {
       final db = DatabaseHelper.instance;
      
      // Insert without category (simulating old data or sync w/o category)
      await db.insertProduct({
        'id': 'test-prod-2',
        'tenantId': 'tenant-A',
        'sku': 'SKU002',
        'name': 'Old Item',
        'sellingPrice': 5000.0,
        'costPrice': 2000.0,
        'trackStock': 1,
        'stock': 5,
        // 'category': null 
      });

      final products = await db.getAllProducts();
      final product = products.firstWhere((p) => p['id'] == 'test-prod-2');

      // The DEFAULT 'All' in SQL schema only applies on INSERT if the column is omitted entirely in the SQL statement.
      // sqflite insert helper might send null if key is missing depending on implementation.
      // However, our existing code in ApiService fallback to 'All' BEFORE insertion.
      // Let's check if the DB schema default works when we use helper.
      
      // Actually checking raw SQL behavior via helper is tricky if helper inserts keys.
      // But standard expected behavior for existing rows (migration) is 'All'.
      expect(product['category'], 'All');
    });
  });
}
