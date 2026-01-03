import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_market/screens/market_home_screen.dart';
import 'package:rana_market/screens/orders_screen.dart';
import 'package:rana_market/screens/notifications_screen.dart';
import 'package:rana_market/screens/profile_screen.dart';
import 'package:rana_market/services/notification_service.dart';
import 'package:rana_market/widgets/buyer_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    const MarketHomeScreen(),
    const OrdersScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    const kBrandColor = Color(0xFFE07A5F);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BuyerBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          if (index == 2) {
            NotificationService.badgeCount.value = 0;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
