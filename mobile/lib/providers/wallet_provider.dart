import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class WalletProvider extends ChangeNotifier {
  bool _isLoading = false;
  double _balance = 0;
  List<dynamic> _history = [];
  List<dynamic> _pendingTopUps = [];
  List<dynamic> _pendingWithdrawals = [];

  bool get isLoading => _isLoading;
  double get balance => _balance;
  List<dynamic> get history => _history;
  List<dynamic> get pendingTopUps => _pendingTopUps;
  List<dynamic> get pendingWithdrawals => _pendingWithdrawals;

  final ApiService _api = ApiService();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getWalletData();
      _balance = (data['balance'] as num).toDouble();
      _history = data['history'] ?? [];
      _pendingTopUps = data['pendingTopUps'] ?? [];
      _pendingWithdrawals = data['pendingWithdrawals'] ?? [];
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> topUp(double amount, dynamic proofImage) async { // Changed to dynamic to accept XFile or File, or strictly XFile
    _isLoading = true;
    notifyListeners();
    try {
      // Encode Image to Base64
      final bytes = await proofImage.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      await _api.topUp(amount: amount, proofPath: base64String); // proofPath param expects Base64 now
      await loadData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> transfer(String targetStoreId, double amount, String note) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.transfer(targetStoreId: targetStoreId, amount: amount, note: note);
      await loadData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> withdraw(double amount, String bank, String account) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.requestWithdrawal(amount: amount, bankName: bank, accountNumber: account);
      await loadData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> payTransaction(double amount, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.payTransaction(amount: amount, description: description, category: 'PPOB');
      await loadData(); // Refresh balance
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
