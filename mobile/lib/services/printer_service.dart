import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // -- STATE --
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // -- 1. SCAN DEVICES --
  Future<List<BluetoothDevice>> getBondedDevices() async {
    // Check Permissions first
    if (await _checkPermissions()) {
      try {
        return await bluetooth.getBondedDevices();
      } catch (e) {
        debugPrint("Printer Scan Error: $e");
        return [];
      }
    }
    return [];
  }

  // -- 2. CONNECT TO DEVICE --
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnected && _connectedDevice?.address == device.address) return true; // Already connected
    
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        _isConnected = true;
        // Check if it's the same device
        return true;
      }
      
      await bluetooth.connect(device).timeout(const Duration(seconds: 5));
      _isConnected = true;
      _connectedDevice = device;
      
      // Save last connected device address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_printer_address', device.address ?? '');
      
      return true;
    } catch (e) {
      debugPrint("Printer Connection Error: $e");
      _isConnected = false;
      return false;
    }
  }
  
  // -- AUTO CONNECT --
  Future<void> autoConnect() async {
    try {
      if (!await _checkPermissions()) return;
      
      final devices = await bluetooth.getBondedDevices();
      final prefs = await SharedPreferences.getInstance();
      final lastAddress = prefs.getString('last_printer_address');
      
      if (lastAddress != null && lastAddress.isNotEmpty) {
        final device = devices.firstWhere((d) => d.address == lastAddress, orElse: () => devices.first);
        await connect(device);
      } else if (devices.isNotEmpty) {
        // Connect to first available if no preference
        await connect(devices.first);
      }
    } catch (e) {
      debugPrint("Auto Connect Failed: $e");
    }
  }

  // -- 3. DISCONNECT --
  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      _isConnected = false;
      _connectedDevice = null;
    } catch (e) {
      debugPrint("Disconnect Error: $e");
    }
  }

  // -- 4. PRINT TEST --
  Future<void> printTest() async {
    if (!_isConnected) {
       await autoConnect();
       if (!_isConnected) return;
    }

    try {
      bluetooth.printNewLine();
      bluetooth.printCustom("RANA POS", 3, 1);
      bluetooth.printCustom("Test Print Successful", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Bluetooth Printer OK", 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    } catch (e) {
      debugPrint("Print Test Error: $e");
    }
  }

  // -- 5. PRINT RECEIPT (Professional Invoice) --
  Future<void> printReceipt(Map<String, dynamic> transaction, List<Map<String, dynamic>> items, {String? storeName, String? storeAddress}) async {
    if (!_isConnected) {
        await autoConnect();
        if (!_isConnected) {
           debugPrint("Printer not connected");
           return; 
        }
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    try {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          // HEADER
          bluetooth.printNewLine();
          bluetooth.printCustom(storeName ?? "RANA MERCHANT", 3, 1); // Bold, Centered, Large
          if (storeAddress != null && storeAddress.isNotEmpty) {
             bluetooth.printCustom(storeAddress, 0, 1);
          }
          bluetooth.printNewLine();
          
          // INFO
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printLeftRight("Tgl", dateFormat.format(DateTime.now()), 0);
          bluetooth.printLeftRight("No. Ref", transaction['offlineId']?.toString().substring(0, 8) ?? "-", 0);
          bluetooth.printLeftRight("Kasir", transaction['cashierName'] ?? "Admin", 0);
          if (transaction['customerName'] != null) {
             bluetooth.printLeftRight("Pelanggan", transaction['customerName'], 0);
          }
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          
          // ITEMS
          for (var item in items) {
             String name = item['name'] ?? 'Produk';
             int qty = item['quantity'] ?? 1;
             double price = (item['price'] is int) ? (item['price'] as int).toDouble() : (item['price'] ?? 0.0);
             double totalItem = price * qty;
             
             // Format: 
             // Nama Produk
             // 2 x Rp 10.000         Rp 20.000
             
             bluetooth.printCustom(name, 1, 0); // Bold name
             bluetooth.printLeftRight("${qty}x @ ${currency.format(price)}", currency.format(totalItem), 0);
          }
          
          bluetooth.printNewLine();
          bluetooth.printCustom("--------------------------------", 1, 1);
          
          // TOTALS
          double total = (transaction['totalAmount'] is int) ? (transaction['totalAmount'] as int).toDouble() : (transaction['totalAmount'] ?? 0.0);
          double discount = (transaction['discount'] is int) ? (transaction['discount'] as int).toDouble() : (transaction['discount'] ?? 0.0);
          
          if (discount > 0) {
             bluetooth.printLeftRight("Subtotal", currency.format(total + discount), 0);
             bluetooth.printLeftRight("Diskon", "-${currency.format(discount)}", 0);
          }
          
          bluetooth.printLeftRight("TOTAL", currency.format(total), 1); // Bold Total
          
          if (transaction['payAmount'] != null) {
             double pay = (transaction['payAmount'] is int) ? (transaction['payAmount'] as int).toDouble() : (transaction['payAmount'] ?? 0.0);
             bluetooth.printLeftRight("Tunai/Bayar", currency.format(pay), 0);
             bluetooth.printLeftRight("Kembali", currency.format(pay - total), 0);
          }
          
          bluetooth.printNewLine();
          bluetooth.printCustom("Terima Kasih", 3, 1);
          bluetooth.printCustom("Simpan struk sebagai bukti pembayaran", 0, 1);
          bluetooth.printCustom("Powered by Rana POS", 0, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.paperCut();
        }
      });
    } catch (e) {
       debugPrint("Print Receipt Error: $e");
    }
  }

  // Helper
  Future<bool> _checkPermissions() async {
    // Android 12+ requires newer permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Singleton
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();
}
