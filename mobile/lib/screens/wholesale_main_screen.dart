import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/screens/wholesale_cart_screen.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/purchase_screen.dart';
import 'package:rana_merchant/screens/settings_screen.dart';

class WholesaleMainScreen extends StatefulWidget {
  const WholesaleMainScreen({super.key});

  @override
  State<WholesaleMainScreen> createState() => _WholesaleMainScreenState();
}

class _WholesaleMainScreenState extends State<WholesaleMainScreen> {
  int _currentIndex = 0;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _loadTenantId();
  }

  Future<void> _loadTenantId() async {
    final auth = context.read<AuthProvider>();
    final userTenantId = auth.currentUser?['tenantId']?.toString();
    if (userTenantId != null && userTenantId.isNotEmpty) {
      setState(() {
        _tenantId = userTenantId;
      });
      return;
    }

    final db = DatabaseHelper.instance;
    final tenant = await db.getTenantInfo();
    final dbTenantId = tenant?['id']?.toString();
    setState(() {
      _tenantId = (dbTenantId != null && dbTenantId.isNotEmpty) ? dbTenantId : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Rana Grosir', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFFD70677),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            'Akun belum siap. Silakan login ulang atau sinkronisasi.',
            style: GoogleFonts.poppins(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<Widget> screens = [
      const PurchaseScreen(),
      const WholesaleCartScreen(),
      WholesaleOrderListScreen(tenantId: _tenantId!),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.store, 'Beranda'),
            _buildNavItem(1, Icons.shopping_cart, 'Keranjang'),
            _buildNavItem(2, Icons.receipt_long, 'Pesanan'),
            _buildNavItem(3, Icons.person, 'Akun'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFD70677) : const Color(0xFFD70677).withOpacity(0.5);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26)
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .shimmer(duration: 1200.ms, delay: 2000.ms), // Subtle shimmer loop if active? No, just once.
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}
