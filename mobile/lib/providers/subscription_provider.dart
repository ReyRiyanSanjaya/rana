import 'package:flutter/material.dart';

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

  // Simulate Check from Server
  Future<void> codeCheckSubscription() async {
    // In real app, call ApiService.getSubscriptionStatus()
    // For now, we keep the default (Trial) or load from prefs
    notifyListeners();
  }

  Future<void> requestUpgrade() async {
    // Simulate User Requesting Upgrade / Uploading Proof
    _status = SubscriptionStatus.pending;
    notifyListeners();
  }

  // For Admin simulation only
  void adminApprove() {
    _status = SubscriptionStatus.active;
    _expiryDate = DateTime.now().add(const Duration(days: 30));
    notifyListeners();
  }
}
