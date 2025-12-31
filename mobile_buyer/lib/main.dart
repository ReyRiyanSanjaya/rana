import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_market/screens/main_screen.dart'; // [NEW]
import 'package:rana_market/services/notification_service.dart';

import 'package:provider/provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/providers/search_history_provider.dart';
import 'package:rana_market/providers/reviews_provider.dart';

const Color kBrandColor = Color(0xFFD70677);
const Color kBeigeBackground = Color(0xFFFFF5EC);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const RanaMarketApp());
}

class RanaMarketApp extends StatelessWidget {
  const RanaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MarketCartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
      ],
      child: MaterialApp(
        title: 'Rana Market',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kBrandColor,
            primary: kBrandColor,
            onPrimary: Colors.white,
            secondary: kBrandColor,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: kBeigeBackground,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: kBrandColor,
            elevation: 0,
            centerTitle: false,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: kBrandColor.withOpacity(0.1)),
            ),
            color: Colors.white,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: kBrandColor,
            iconTheme: WidgetStatePropertyAll(
              IconThemeData(color: kBrandColor),
            ),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(color: kBrandColor, fontWeight: FontWeight.w600),
            ),
          ),
          dividerColor: kBrandColor,
          dividerTheme: const DividerThemeData(
            color: kBrandColor,
            thickness: 1,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return const MainScreen();
          },
        ),
      ),
    );
  }
}
