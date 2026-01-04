import 'package:flutter/material.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/screens/main_screen.dart'; // [NEW]
import 'package:rana_market/services/notification_service.dart';

import 'package:provider/provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/providers/search_history_provider.dart';
import 'package:rana_market/providers/reviews_provider.dart';
import 'package:rana_market/providers/notifications_provider.dart';
import 'package:rana_market/services/socket_service.dart';

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
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: MaterialApp(
        title: 'Rana Market',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return const SocketManager(child: MainScreen());
          },
        ),
      ),
    );
  }
}

class SocketManager extends StatefulWidget {
  final Widget child;
  const SocketManager({super.key, required this.child});

  @override
  State<SocketManager> createState() => _SocketManagerState();
}

class _SocketManagerState extends State<SocketManager> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final socket = Provider.of<SocketService>(context, listen: false);

    if (auth.isAuthenticated && auth.token != null) {
      if (!socket.isConnected) {
        socket.init(auth.token!);
      }
    } else {
      if (socket.isConnected) {
        socket.disconnect();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
