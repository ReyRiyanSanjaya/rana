import 'package:flutter/material.dart';
import 'package:rana_pos/data/remote/api_service.dart';

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
      final response = await _api.login(email, password);
      // Backend returns { token, user: {...} }
      // We also now expect user to have storeId
      if (response['success'] == true) { // check success flag if wrapper used, or direct data
         // Check authController.js structure: 
         // return successResponse(res, { token, user: ... }, "Login Successful");
         // successResponse -> { success: true, data: { token, user }, message: ... }
         // Wait, api_service.dart returns "response.data".
         // The structure from server is:
         // { success: true, data: { token: "...", user: {...} }, message: "..." }
         // So in api_service: return response.data; -> returns the WHOLE object.
         
         // careful here. Let's verify what api_service actually returns.
         // api_service: return response.data;
         // So here response['data'] contains the token.
         
         final data = response['data'];
         _token = data['token'];
         _currentUser = data['user'];
      } else {
         // Fallback if successResponse wrapper is not used or different
         // In authController I saw: return successResponse(...)
         // Let's assume standard response structure.
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
