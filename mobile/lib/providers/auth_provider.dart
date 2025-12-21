import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

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
      } else {
         throw Exception(response['message'] ?? 'Login Failed');
      }
      
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
