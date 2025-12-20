import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_pos/providers/cart_provider.dart';
import 'package:rana_pos/providers/auth_provider.dart';
import 'package:rana_pos/screens/login_screen.dart';
import 'package:rana_pos/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'Rana Merchant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Soft Indigo
            primary: const Color(0xFF4F46E5),
            secondary: const Color(0xFFEC4899), // Soft Pink accent
            surface: const Color(0xFFF9FAFB), // Very light gray background
            surfaceContainerHighest: const Color(0xFFFFFFFF), // White cards
          ),
          scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Soft gray bg
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF374151), // Soft Dark Gray
            elevation: 0,
            shape: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.5)), // Soft Stroke Breakdown
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF374151), 
              fontSize: 18, 
              fontWeight: FontWeight.w600,
            )
          ),
          cardTheme: CardTheme(
            elevation: 0, // Flat
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Softer corners
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5) // Soft Stroke (Gray-200)
            ),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0)
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Cool Gray 50
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5), // Soft Stroke
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2), // Soft Indigo Focus
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide.none // Filled doesn't need stroke usually, or maybe a subtle inner one? Keep clean.
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
            )
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
             style: OutlinedButton.styleFrom(
               side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               padding: const EdgeInsets.symmetric(vertical: 18),
             )
          ),
          textTheme: GoogleFonts.interTextTheme(),
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
