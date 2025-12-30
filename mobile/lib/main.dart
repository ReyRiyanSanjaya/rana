import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/login_screen.dart';
import 'package:rana_merchant/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:rana_merchant/services/notification_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:rana_merchant/providers/wholesale_cart_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/wallet_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/subscription_provider.dart'; // [FIX] Added missing import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize for Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
    // Initialize FFI for Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await NotificationService().init();

  runApp(const RanaApp());
}



class RanaApp extends StatelessWidget {
  const RanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WholesaleCartProvider()), // [NEW]
        ChangeNotifierProvider(create: (_) => WalletProvider()), // [NEW]
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()), // [FIX] Added missing provider
      ],
      child: MaterialApp(
        title: 'Rana Merchant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFBF092F), // [FIX] New Brand Red
            primary: const Color(0xFFBF092F),
            onPrimary: Colors.white, // [FIX] Ensure text on primary is white
            secondary: const Color(0xFFE11D48), // Lighter red accent
            surface: const Color(0xFFFFFFFF), 
            surfaceContainerHighest: const Color(0xFFF8FAFC), 
          ),
          scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Soft slate gray bg
          splashFactory: InkSparkle.splashFactory, // Sparkle splash for M3
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFBF092F), // [FIX] Global Red Brand
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white), // [FIX] Ensure icons are white
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            )
          ),
          cardTheme: CardThemeData(
            elevation: 2, // Soft shadow
            shadowColor: const Color(0xFF64748B).withOpacity(0.1), // Blue-gray shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // Even rounder
              side: BorderSide.none, // Remove border for cleaner look, rely on shadow
            ),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4)
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // Slate 50
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none, // Cleaner default state
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFBF092F), width: 2), // Red Ring
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              elevation: 4,
              shadowColor: const Color(0xFFBF092F).withOpacity(0.4), // Red shadow
              backgroundColor: const Color(0xFFBF092F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            )
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
             style: OutlinedButton.styleFrom(
               side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
               textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
             )
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
            },
          ),
          textTheme: GoogleFonts.outfitTextTheme().apply( // Switched to Outfit for a friendlier/softer look
             bodyColor: const Color(0xFF334155), // Slate 700
             displayColor: const Color(0xFF1E293B), // Slate 800
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, check shared_preferences for token
    final auth = Provider.of<AuthProvider>(context);
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
