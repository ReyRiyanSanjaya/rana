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
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  
  SubscriptionStatus get status => _status;
  bool get isPremium => _status == SubscriptionStatus.active;
  bool get isLocked => _status == SubscriptionStatus.expired;
  
  // Use this to check specific feature access
  bool canAccessFeature(String featureId) {
    if (_status == SubscriptionStatus.active) return true;
    if (_status == SubscriptionStatus.trial) return true;
    
    // If expired or free, check limitations
    return false; 
  }

  List<dynamic> _packages = [];
  List<dynamic> get packages => _packages;
  
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
      // data: { subscriptionStatus, plan, trialEndsAt }
      
      final statusStr = data['subscriptionStatus'];
      if (statusStr == 'ACTIVE') _status = SubscriptionStatus.active;
      else if (statusStr == 'TRIAL') _status = SubscriptionStatus.trial;
      else if (statusStr == 'EXPIRED') _status = SubscriptionStatus.expired;
      
      print('DEBUG: Updated Status to $_status');
      notifyListeners();
    } catch (e) {
      print('Check Sub Failed: $e');
      rethrow; // Allow UI to handle/show error
    }
  }

  Future<void> requestUpgrade(String proofUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      // API now takes tenantId from token
      await ApiService().requestSubscription(proofUrl);
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
