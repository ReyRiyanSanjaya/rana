import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChanged => _statusController.stream;
  Timer? _timer;
  bool? _lastStatus;

  /// Check connectivity. 
  /// In Debug Mode (Emulator), we might have issues with DNS lookup.
  /// We will try google.com, if fails, we check a known public IP 8.8.8.8 to avoid DNS issues.
  Future<bool> hasInternetConnection() async {
    if (kIsWeb) {
      // On web, assume online as networking uses browser stack
      return true;
    }
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Fallback: Try pinging Google DNS directly
      try {
        final result = await InternetAddress.lookup('8.8.8.8');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _timer?.cancel();
    unawaited(_emitCurrentStatus());
    _timer = Timer.periodic(interval, (_) => _emitCurrentStatus());
  }

  Future<void> _emitCurrentStatus() async {
    final status = await hasInternetConnection();
    if (_lastStatus == null || _lastStatus != status) {
      _lastStatus = status;
      _statusController.add(status);
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}
