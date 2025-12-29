import 'package:flutter/material.dart';
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
          borderRadius: BorderRadius.circular(24), // Softer corners
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B)
                  .withValues(alpha: 20), // Softer shadow color
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
              color: quantity > 0
                  ? const Color(0xFFBF092F)
                  : Colors.transparent, // Only show border if selected
              width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Placeholder Area
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                            ),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                        ),
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCBD5E1)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Optional: Simple pattern or noise could go here

                  // Stock Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 230),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 13),
                                blurRadius: 4)
                          ]),
                      child: Text(
                        'Stok: ${product['stock']}',
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Quantity Indicator (Animated)
                  if (quantity > 0)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            color: Color(0xFFBF092F), // Red Primary
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x66BF092F),
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ]),
                        child: Center(
                          child: Text('$quantity',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.easeOutBack),
                    )
                ],
              ),
            ),

            // Info Area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      product['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF0F172A), // Slate 900
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(product['sellingPrice']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFBF092F), // Red 500
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1, end: 0, curve: Curves.easeOutQuad), // Entrance Animation
    );
  }
}
