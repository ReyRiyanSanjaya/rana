import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_market/screens/market_home_screen.dart';

import 'package:provider/provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';

void main() {
  runApp(const RanaMarketApp());
}

class RanaMarketApp extends StatelessWidget {
  const RanaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarketCartProvider()),
      ],
      child: MaterialApp(
        title: 'Rana Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // Emerald Green (GoFood-like)
          primary: const Color(0xFF059669),
          secondary: const Color(0xFFF59E0B), // Orange Accent
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: GoogleFonts.poppinsTextTheme(), // Friendly consumer font
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200)
          ),
          color: Colors.white,
        )
      ),
      home: const MarketHomeScreen(),
    );
  }
}
