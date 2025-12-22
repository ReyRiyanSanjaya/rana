import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';
import 'package:rana_merchant/screens/subscription_screen.dart';
import 'dart:ui';

class PremiumLock extends StatelessWidget {
  final Widget child;
  final bool isBlur; // If true, shows blurred content. If false, hides/replaces.

  const PremiumLock({super.key, required this.child, this.isBlur = true});

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    
    // If has access, return child directly
    if (sub.canAccessFeature('generic')) {
      return child;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
      },
      child: Stack(
        children: [
          // Content (Blurred or Hidden)
          isBlur 
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: AbsorbPointer(child: child),
              )
            : Container(
                height: 150, 
                color: Colors.grey.shade100,
                child: Center(child: Icon(Icons.lock, size: 48, color: Colors.grey.shade400)),
              ),
              
          // Lock Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('Fitur Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
