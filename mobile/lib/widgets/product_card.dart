import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Soft shadow matching the design
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: quantity > 0 ? Theme.of(context).primaryColor : Colors.grey[200]!, 
            width: quantity > 0 ? 2 : 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Placeholder Area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Text(
                        product['name'].toString().substring(0, 1).toUpperCase(),
                         style: TextStyle(
                            fontSize: 48, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey[300]
                        ),
                      ),
                    ),
                  ),
                  // Stock Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stok: ${product['stock']}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Selection Badge (Green Checkmark or count)
                  if (quantity > 0)
                     Positioned(
                        top: 12,
                        left: 12,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            '$quantity', 
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                     ),
                ],
              ),
            ),
            
            // Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1F2937), // Gray 900
                        height: 1.2,
                      ),
                    ),
                    Text(
                      currency.format(product['sellingPrice']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
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
