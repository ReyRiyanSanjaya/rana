import 'package:flutter/material.dart'; // [NEW] - Fixed missing import
import 'package:rana_merchant/data/remote/api_service.dart'; // [NEW] - Fixed missing import
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:rana_merchant/data/local/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  String? _token;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    try {
      final response = await _api.login(email: email, password: password);
      // Backend returns { token, user: {...} }
      // We also now expect user to have storeId
      if (response['status'] == 'success') { 
         final data = response['data'];
         _token = data['token'];
         _currentUser = data['user'];
         
         // Set token in ApiService singleton
         _api.setToken(_token!);

         // Persist Token
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('auth_token', _token!);
         await prefs.setString('user_data', data['user'].toString()); // Simplified handling
      } else {
         throw Exception(response['message'] ?? 'Login Failed');
      }
      
      
      _isAuthenticated = true;
      notifyListeners();

      // [NEW] Trigger Initial Data Sync
      try {
         // Clear old data first to ensure isolation
         await DatabaseHelper.instance.clearAllData(); 
         await _api.syncAllData();
         notifyListeners(); // Refresh UI with new data
      } catch (e) {
         debugPrint('Initial Sync Warning: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkAuth() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
          _token = token;
          _api.setToken(token);
          // Ideally fetch profile here to be sure
          try {
             final profile = await _api.getProfile();
             _currentUser = profile;
             _isAuthenticated = true;
             notifyListeners();
             await _api.syncAllData(); // background sync
          } catch (e) {
             // Token likely expired
             logout();
          }
      }
  }

  void logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    // Clear Local DB
    await DatabaseHelper.instance.clearAllData();

    notifyListeners();
  }
}
