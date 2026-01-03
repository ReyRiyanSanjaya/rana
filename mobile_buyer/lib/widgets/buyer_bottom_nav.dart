import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_market/services/notification_service.dart';

class BuyerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BuyerBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const kBrandColor = Color(0xFFE07A5F);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07A5F).withValues(alpha: 0.1),
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
          indicatorColor: kBrandColor.withValues(alpha: 0.15),
          selectedIndex: selectedIndex,
          animationDuration: const Duration(milliseconds: 600),
          onDestinationSelected: onSelected,
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
    );
  }
}

