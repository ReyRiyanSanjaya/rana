import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/login_screen.dart';
import 'package:rana_merchant/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:rana_merchant/services/notification_service.dart';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:rana_merchant/providers/wholesale_cart_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/wallet_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/subscription_provider.dart'; // [FIX] Added missing import

const Color kBrandColor = Color(0xFFE07A5F); // Soft Terra Cotta
const Color kBeigeBackground = Color(0xFFFFF8F0); // Soft Beige

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize for Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
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
        ChangeNotifierProvider(
            create: (_) =>
                SubscriptionProvider()), // [FIX] Added missing provider
      ],
      child: MaterialApp(
        title: 'Rana Merchant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kBrandColor, // [FIX] New Brand Red
            primary: kBrandColor,
            onPrimary: Colors.white, // [FIX] Ensure text on primary is white
            secondary: kBrandColor,
            surface: Colors.white,
            surfaceContainerHighest: kBeigeBackground,
          ),
          dividerColor: kBrandColor,
          dividerTheme: const DividerThemeData(
            color: kBrandColor,
            thickness: 1,
          ),
          scaffoldBackgroundColor: kBeigeBackground, // Soft beige bg
          splashFactory: InkSparkle.splashFactory, // Sparkle splash for M3
          appBarTheme: const AppBarTheme(
              backgroundColor: kBeigeBackground, // Soft Beige Header
              foregroundColor: kBrandColor,
              iconTheme: IconThemeData(color: kBrandColor),
              elevation: 0,
              scrolledUnderElevation: 0,
              shape: Border(
                  bottom: BorderSide(
                      color: Colors.transparent,
                      width: 0)), // Remove hard border
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: kBrandColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              )),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: kBrandColor,
            unselectedItemColor: kBrandColor,
          ),
          cardTheme: CardThemeData(
              elevation: 2, // Soft shadow
              shadowColor:
                  const Color(0xFF64748B).withOpacity(0.1), // Blue-gray shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // Even rounder
                side: BorderSide
                    .none, // Remove border for cleaner look, rely on shadow
              ),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none, // Cleaner default state
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  BorderSide(color: kBrandColor.withOpacity(0.3), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: kBrandColor, width: 2), // Red Ring
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
            elevation: 4,
            shadowColor: kBrandColor.withOpacity(0.4), // Red shadow
            backgroundColor: kBrandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          )),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kBrandColor, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          )),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
            },
          ),
          textTheme: GoogleFonts.outfitTextTheme().apply(
            // Switched to Outfit for a friendlier/softer look
            bodyColor: const Color(0xFF334155), // Slate 700
            displayColor: const Color(0xFF1E293B), // Slate 800
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await context.read<AuthProvider>().checkAuth();
      } finally {
        if (mounted) setState(() => _checked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
