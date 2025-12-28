import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

enum SubscriptionStatus {
  trial,    // 7 Days Free
  expired,  // Trial Ended, functionality locked
  pending,  // Payment sent, waiting admin
  active,   // Premium unlocked
  free      // Basic forever (if we want a free tier later)
}

class SubscriptionProvider with ChangeNotifier {
  SubscriptionStatus _status = SubscriptionStatus.trial;
  DateTime? _expiryDate;
  int? _daysRemaining;
  
  SubscriptionStatus get status => _status;
  bool get isPremium => _status == SubscriptionStatus.active;
  bool get isLocked => _status == SubscriptionStatus.expired;
  DateTime? get expiryDate => _expiryDate;
  int? get daysRemaining => _daysRemaining;
  
  // Use this to check specific feature access
  bool canAccessFeature(String featureId) {
    if (_status == SubscriptionStatus.active) return true;
    if (_status == SubscriptionStatus.trial) return true;
    
    // If expired or free, check limitations
    return false; 
  }

  List<dynamic> _packages = [];
  List<dynamic> get packages => _packages;
  
  // [NEW] Track selected package
  Map<String, dynamic>? _selectedPackage;
  Map<String, dynamic>? get selectedPackage => _selectedPackage;
  
  void selectPackage(Map<String, dynamic> package) {
    _selectedPackage = package;
    notifyListeners();
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchPackages() async {
    _isLoading = true;
    notifyListeners();
    try {
      _packages = await ApiService().getSubscriptionPackages();
    } catch (e) {
      print('Error fetching packages: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Check from Server
  Future<void> codeCheckSubscription() async {
    try {
      print('DEBUG: Checking subscription status...');
      final data = await ApiService().getSubscriptionStatus();
      print('DEBUG: Server Response: $data');
      // data: { subscriptionStatus, plan, trialEndsAt, subscriptionEndsAt, daysRemaining }
      
      final statusStr = data['subscriptionStatus'];
      if (statusStr == 'ACTIVE') _status = SubscriptionStatus.active;
      else if (statusStr == 'TRIAL') _status = SubscriptionStatus.trial;
      else if (statusStr == 'EXPIRED') _status = SubscriptionStatus.expired;
      
      // [NEW] Parse days remaining and expiry date
      _daysRemaining = data['daysRemaining'];
      if (data['subscriptionEndsAt'] != null) {
        _expiryDate = DateTime.parse(data['subscriptionEndsAt']);
      } else if (data['trialEndsAt'] != null) {
        _expiryDate = DateTime.parse(data['trialEndsAt']);
      }
      
      print('DEBUG: Updated Status to $_status, Days Remaining: $_daysRemaining');
      notifyListeners();
    } catch (e) {
      print('Check Sub Failed: $e');
      rethrow; // Allow UI to handle/show error
    }
  }

  // [UPDATED] Include packageId in request
  Future<void> requestUpgrade(dynamic proofImage) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Encode Image to Base64
      final bytes = await proofImage.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";

      // API now takes tenantId from token and includes packageId
      await ApiService().requestSubscription(
        base64String, 
        packageId: _selectedPackage?['id'] // [NEW] Pass selected package ID
      );
      _status = SubscriptionStatus.pending;
    } catch (e) {
       print('Error requesting upgrade: $e');
       rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  // For Admin simulation only
  void adminApprove() {
    _status = SubscriptionStatus.active;
    _expiryDate = DateTime.now().add(const Duration(days: 30));
    notifyListeners();
  }
}
