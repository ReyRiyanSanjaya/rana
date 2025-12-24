import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class NoConnectionScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoConnectionScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation for No Connection
              // Using a network URL as placeholder. If offline, it might fail, so we wrap.
              // Ideally this involves a local asset like 'assets/lottie/no_internet.json'
              SizedBox(
                height: 200,
                child: Lottie.network(
                  'https://lottie.host/99037c86-1383-42e7-9c60-8f96e8d25d1e/8xZ8X9X9.json', // Example placeholder URL
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.wifi_off, size: 100, color: Colors.indigo);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Koneksi Terputus',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              Text(
                'Fitur ini memerlukan koneksi internet stabil. Periksa wifi atau data seluler Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF4F46E5)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
