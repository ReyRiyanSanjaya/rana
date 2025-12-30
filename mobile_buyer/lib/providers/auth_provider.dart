import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_market/data/market_api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    
    if (userStr != null) {
      try {
        _user = jsonDecode(userStr);
      } catch (e) {
        debugPrint('Failed to decode user: $e');
      }
    }

    if (_token != null) {
      MarketApiService().setToken(_token);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final data = await MarketApiService().login(email, password);
      final token = data['token'];
      if (token is! String || token.trim().isEmpty) {
        throw Exception('Token tidak ditemukan');
      }
      _token = token;
      final user = data['user'];
      _user = user is Map<String, dynamic> ? user : (user is Map ? Map<String, dynamic>.from(user) : null);
      
      MarketApiService().setToken(_token);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user));
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> register(String name, String email, String phone, String password) async {
     try {
      final data = await MarketApiService().register(name, email, phone, password);
      final token = data['token'];
      if (token is String && token.trim().isNotEmpty) {
        _token = token;
        final user = data['user'];
        _user = user is Map<String, dynamic> ? user : (user is Map ? Map<String, dynamic>.from(user) : null);

        MarketApiService().setToken(_token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        if (_user != null) {
          await prefs.setString('user', jsonEncode(_user));
        }
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    MarketApiService().setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
