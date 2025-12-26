import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

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
        print("Printer Scan Error: $e");
        return [];
      }
    }
    return [];
  }

  // -- 2. CONNECT TO DEVICE --
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnected) return true; // Already connected
    
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        _isConnected = true;
        _connectedDevice = device; // Assume it's the right one or re-connect?
        return true;
      }
      
      await bluetooth.connect(device).timeout(const Duration(seconds: 5));
      _isConnected = true;
      _connectedDevice = device;
      return true;
    } catch (e) {
      print("Printer Connection Error: $e");
      _isConnected = false;
      return false;
    }
  }

  // -- 3. DISCONNECT --
  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      _isConnected = false;
      _connectedDevice = null;
    } catch (e) {
      print("Disconnect Error: $e");
    }
  }

  // -- 4. PRINT TEST --
  Future<void> printTest() async {
    if (!_isConnected) return;

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
      print("Print Test Error: $e");
    }
  }

  // -- 5. PRINT RECEIPT --
  Future<void> printReceipt(Map<String, dynamic> transaction, List<Map<String, dynamic>> items) async {
    if (!_isConnected) {
        print("Printer not connected");
        return; 
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    try {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          bluetooth.printNewLine();
          bluetooth.printCustom("RANA STORE", 3, 1);
          bluetooth.printCustom("Struk Belanja", 1, 1);
          bluetooth.printCustom(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), 0, 1);
          bluetooth.printNewLine();
          
          bluetooth.printCustom("Item:", 1, 0);
          for (var item in items) {
             String name = item['name'] ?? 'Produk';
             String qty = "x${item['quantity']}";
             String price = currency.format(item['price']);
             String total = currency.format((item['price'] ?? 0) * (item['quantity'] ?? 1));
             
             // Simple Line: 
             bluetooth.printLeftRight(name, "", 0);
             bluetooth.printLeftRight("$qty @ $price", total, 0);
          }
          
          bluetooth.printNewLine();
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printLeftRight("TOTAL", currency.format(transaction['totalAmount'] ?? 0), 1);
          if (transaction['payAmount'] != null) {
             bluetooth.printLeftRight("Bayar", currency.format(transaction['payAmount']), 0);
          }
           if (transaction['changeAmount'] != null) {
             bluetooth.printLeftRight("Kembali", currency.format(transaction['changeAmount']), 0);
          }
          bluetooth.printNewLine();
          bluetooth.printCustom("Terima Kasih", 1, 1);
          bluetooth.printCustom("Powered by Rana POS", 0, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.paperCut();
        }
      });
    } catch (e) {
       print("Print Receipt Error: $e");
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
