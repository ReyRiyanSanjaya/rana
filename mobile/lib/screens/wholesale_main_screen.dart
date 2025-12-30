import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/screens/wholesale_cart_screen.dart';
import 'package:rana_merchant/screens/wholesale_home_screen.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';

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
    final db = DatabaseHelper.instance;
    final tenant = await db.getTenantInfo();
    setState(() {
      _tenantId = tenant != null ? tenant['id'] : 'demo-tenant-id';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tenantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const WholesaleHomeScreen(),
      const WholesaleCartScreen(),
      WholesaleOrderListScreen(tenantId: _tenantId!),
      const Center(
          child: Text("Profile / Settings")), // Placeholder for Profile
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
