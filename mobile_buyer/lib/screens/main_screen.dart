import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_market/screens/market_home_screen.dart';
import 'package:rana_market/screens/orders_screen.dart';
import 'package:rana_market/screens/notifications_screen.dart';
import 'package:rana_market/screens/profile_screen.dart';
import 'package:rana_market/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MarketHomeScreen(),
    const OrdersScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const kBrandColor = Color(0xFFE07A5F);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE07A5F).withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kBrandColor,
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: kBrandColor, size: 26);
              }
              return IconThemeData(color: Colors.grey.shade500, size: 24);
            }),
          ),
          child: NavigationBar(
            height: 75,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: kBrandColor.withOpacity(0.15),
            selectedIndex: _selectedIndex,
            animationDuration: const Duration(milliseconds: 600),
            onDestinationSelected: (int index) {
              // Reset badge if navigating to Notifications (index 2)
              if (index == 2) {
                NotificationService.badgeCount.value = 0;
              }
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded)
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOutBack),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded)
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOutBack),
                label: 'Pesanan',
              ),
              NavigationDestination(
                icon: ValueListenableBuilder<int>(
                  valueListenable: NotificationService.badgeCount,
                  builder: (context, count, child) {
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: kBrandColor,
                      child: const Icon(Icons.notifications_outlined),
                    );
                  },
                ),
                selectedIcon: const Icon(Icons.notifications_rounded)
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOutBack),
                label: 'Inbox',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person_rounded)
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOutBack),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
