import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/register_screen.dart';
import 'package:rana_merchant/screens/home_screen.dart';
import 'package:rana_merchant/screens/onboarding_merchant_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_phoneCtrl.text, _passCtrl.text);

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasCompleted =
          prefs.getBool('has_completed_onboarding') ?? false;

      final next = hasCompleted
          ? const HomeScreen()
          : const MerchantOnboardingScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFE07A5F)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 64, color: Color(0xFFE07A5F))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text('Rana POS',
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Nomor HP / WhatsApp',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE07A5F))),
                    floatingLabelStyle: TextStyle(color: Color(0xFFE07A5F))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE07A5F))),
                    floatingLabelStyle: TextStyle(color: Color(0xFFE07A5F))),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()));
                },
                child: const Text('Belum punya akun? Daftar gratis'),
              )
            ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
          ),
        ),
      ),
    );
  }
}
