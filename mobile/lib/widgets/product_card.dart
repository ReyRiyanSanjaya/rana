import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // [NEW]
import 'package:rana_merchant/constants.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final rawImageUrl = product['imageUrl']?.toString();
    final hasImage = rawImageUrl != null && rawImageUrl.isNotEmpty;
    final imageUrl = !hasImage
        ? null
        : (rawImageUrl.startsWith('http')
            ? rawImageUrl
            : '${AppConstants.baseUrl}$rawImageUrl');
    final productName = (product['name'] ?? '').toString();
    final initial = productName.isNotEmpty
        ? productName.substring(0, 1).toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20), // Slightly reduced for stroke look
          border: Border.all(
            color: quantity > 0
                ? const Color(0xFF4F46E5) // Primary Indigo
                : Colors.grey.shade200, // Soft Grey Stroke
            width: quantity > 0 ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(
                              18)), // Match outer - border width
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                            child: Image.network(imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                    child: Text(initial,
                                        style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade300)))),
                          )
                        : Center(
                            child: Text(initial,
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade300))),
                  ),
                  if (quantity > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A5F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${quantity}x",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ).animate().scale(duration: 200.ms),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(product['sellingPrice'] ?? 0),
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFE07A5F),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
