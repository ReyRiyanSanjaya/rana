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
import 'package:intl/date_symbol_data_local.dart';

import 'package:rana_merchant/providers/wholesale_cart_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/wallet_provider.dart'; // [NEW]
import 'package:rana_merchant/providers/subscription_provider.dart'; // [FIX] Added missing import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_merchant/screens/onboarding_merchant_screen.dart';

import 'package:rana_merchant/config/theme_config.dart'; // [NEW] Config
import 'package:rana_merchant/config/app_config.dart';   // [NEW] Config

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

  await initializeDateFormatting(AppConfig.defaultLanguage, null);
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
        ChangeNotifierProvider(create: (_) => WholesaleCartProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
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
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await context.read<AuthProvider>().checkAuth();
        final prefs = await SharedPreferences.getInstance();
        final hasCompleted =
            prefs.getBool('has_completed_onboarding') ?? false;
        final auth = context.read<AuthProvider>();
        if (mounted) {
          setState(() {
            _showOnboarding = auth.isAuthenticated && !hasCompleted;
          });
        }
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
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    if (_showOnboarding) {
      return const MerchantOnboardingScreen();
    }
    return const HomeScreen();
  }
}
