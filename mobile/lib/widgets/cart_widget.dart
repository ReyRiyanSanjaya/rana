import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:rana_merchant/screens/payment_screen.dart';
import 'package:rana_merchant/config/theme_config.dart';

class CartWidget extends StatelessWidget {
  final bool isEmbedded;
  final VoidCallback? onClose;
  final Future<void> Function()? onCheckoutSuccess;
  final ScrollController? scrollController;

  const CartWidget({
    super.key,
    this.isEmbedded = false,
    this.onClose,
    this.onCheckoutSuccess,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: isEmbedded ? Colors.white : ThemeConfig.beigeBackground,
        // Only show top radius if not embedded (i.e., modal)
        borderRadius: isEmbedded
            ? null
            : const BorderRadius.vertical(top: Radius.circular(24)),
        border: isEmbedded
            ? Border(left: BorderSide(color: Colors.grey.shade200, width: 1))
            : null,
        boxShadow: isEmbedded
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(-4, 0))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5))
              ],
      ),
      child: Column(
        children: [
          // Handle Bar (only if modal)
          if (!isEmbedded)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.shopping_cart,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('Keranjang',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground)),
                  ],
                ),
                if (!isEmbedded && onClose != null)
                  IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 20)),
                if (isEmbedded)
                  IconButton(
                      onPressed: () {
                        // Option to clear cart or other actions
                        SoundService.playBeep(); // [FIX] Add sound
                        cart.clear();
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: Colors.grey, size: 20))
              ],
            ),
          ),

          const Divider(height: 1),

          // Customer Selector (Outlined)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () async {
                final controller =
                    TextEditingController(text: cart.customerName ?? '');
                final result = await showDialog<String?>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('Pelanggan'),
                          content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                  labelText: 'Nama',
                                  border: OutlineInputBorder())),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, null),
                                child: const Text('Umum')),
                            FilledButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, controller.text.trim()),
                                child: const Text('Simpan')),
                          ],
                        ));
                cart.setCustomerName(result);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isEmbedded ? ThemeConfig.beigeBackground : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(cart.customerName ?? 'Pelanggan Umum',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          // Items
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.itemCount == 0) {
                  return Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Keranjang Kosong',
                          style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ));
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = cart.items.values.toList()[i];
                    return Dismissible(
                      key: Key(item.productId),
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) => cart.removeItem(item.productId),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red[500],
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text('Hapus',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red[500],
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Hapus',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.delete_outline,
                                color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isEmbedded
                              ? ThemeConfig.beigeBackground
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: Colors.grey[300], size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                      NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0)
                                          .format(item.price),
                                      style: GoogleFonts.poppins(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          cart.removeSingleItem(item.productId),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove,
                                            size: 14, color: Colors.grey),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        final controller =
                                            TextEditingController(
                                                text: '${item.quantity}');
                                        final newQty = await showDialog<int>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Ubah Jumlah'),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Jumlah',
                                                border: OutlineInputBorder(),
                                              ),
                                              autofocus: true,
                                              onSubmitted: (val) {
                                                Navigator.pop(
                                                    context, int.tryParse(val));
                                              },
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Batal'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(
                                                    context,
                                                    int.tryParse(
                                                        controller.text)),
                                                child: const Text('Simpan'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (newQty != null) {
                                          cart.setItemQuantity(
                                              item.productId, newQty);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        child: Text('${item.quantity}',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cart.addItem(item.productId, item.name,
                                            item.price,
                                            maxStock: item.maxStock);
                                        SoundService.playBeep();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEmbedded ? Colors.white : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey[600])),
                      Consumer<CartProvider>(
                        builder: (_, cart, __) => Text(
                          NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0)
                              .format(cart.subtotal),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tax
                  if (cart.taxAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pajak',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey[600])),
                          Consumer<CartProvider>(
                            builder: (_, cart, __) => Text(
                              NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0)
                                  .format(cart.taxAmount),
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(),
                  const SizedBox(height: 12),

                  // Total Section with Template Color Background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeConfig.brandColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConfig.brandColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Tagihan',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9))),
                            Consumer<CartProvider>(
                              builder: (_, cart, __) => Text(
                                NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp ',
                                        decimalDigits: 0)
                                    .format(cart.totalAmount),
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Pay Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: cart.itemCount == 0
                                ? null
                                : () async {
                                    SoundService.playBeep();
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => PaymentScreen(cart: cart),
                                    );
                                    if (result == true) {
                                      if (onCheckoutSuccess != null) {
                                        await onCheckoutSuccess!();
                                      }
                                      if (!isEmbedded &&
                                          Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ThemeConfig.brandColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payment_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text('BAYAR SEKARANG',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
