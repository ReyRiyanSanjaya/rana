import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/config/assets_config.dart';

class MaintenanceScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? until;
  final String animationAsset;

  const MaintenanceScreen({
    super.key,
    required this.title,
    required this.message,
    this.until,
    this.animationAsset = AssetsConfig.lottieLoadingCreator,
  });

  @override
  Widget build(BuildContext context) {
    final untilText = until != null && until!.isNotEmpty
        ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.tryParse(until!) ?? DateTime.now())
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(animationAsset, repeat: true, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey[700])),
              if (untilText != null) ...[
                const SizedBox(height: 8),
                Text('Perkiraan selesai: $untilText',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali', style: GoogleFonts.poppins()))
            ],
          ),
        ),
      ),
    );
  }
}
