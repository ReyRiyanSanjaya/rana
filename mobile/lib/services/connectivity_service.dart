import 'dart:io';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Check connectivity. 
  /// In Debug Mode (Emulator), we might have issues with DNS lookup.
  /// We will try google.com, if fails, we check a known public IP 8.8.8.8 to avoid DNS issues.
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      // Fallback: Try pinging Google DNS directly
      try {
        final result = await InternetAddress.lookup('8.8.8.8');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }
}
