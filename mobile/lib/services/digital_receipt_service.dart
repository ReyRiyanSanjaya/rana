import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rana_merchant/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec

class DigitalReceiptService {
  static const String _promoContactsKey = 'promo_contacts_v1';

  static String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return digits;
  }

  static Future<void> _upsertPromoContact({
    required String phone,
    String? name,
  }) async {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_promoContactsKey);
    List<Map<String, dynamic>> contacts = [];

    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        contacts =
            decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }

    final idx = contacts.indexWhere((c) {
      final p = (c['phone'] ?? '').toString();
      return _normalizePhone(p) == normalized;
    });

    final newName = (name ?? '').toString().trim();
    if (idx >= 0) {
      final existingName = (contacts[idx]['name'] ?? '').toString().trim();
      if (existingName.isEmpty && newName.isNotEmpty) {
        contacts[idx]['name'] = newName;
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch % 2000000000;
      contacts.add({
        'id': id,
        'name': newName,
        'phone': normalized,
      });
    }

    await prefs.setString(_promoContactsKey, jsonEncode(contacts));
  }

  static Future<void> sendViaWhatsApp(String phone, Map<String, dynamic> txn,
      List<Map<String, dynamic>> items) async {
    // 1. Format Message
    final sb = StringBuffer();
    sb.writeln('*RANA POS RECEIPT*');
    sb.writeln('----------------');
    sb.writeln('Date: ${txn['occurredAt']}');
    sb.writeln('ID: ${txn['offlineId'].toString().substring(0, 8)}');
    sb.writeln('----------------');

    for (var item in items) {
      // Logic to find Item Name needed (usually passed or looked up)
      // Since history items might just have ID, ideally we pass name too.
      // For MVP, assuming item map has 'name' or we just show 'Item'
      final name = item['name'] ?? 'Item';
      final qty = item['quantity'];
      final price = item['price'];
      final sub = qty * price;

      sb.writeln('${qty}x $name');
      sb.writeln('   Rp $sub');
    }

    sb.writeln('----------------');
    if (txn['discount'] != null && txn['discount'] > 0) {
      sb.writeln('Disc: -Rp ${txn['discount']}');
    }
    if (txn['tax'] != null && txn['tax'] > 0) {
      sb.writeln('Tax: Rp ${txn['tax']}');
    }
    sb.writeln('*TOTAL: Rp ${txn['total']}*');
    sb.writeln('----------------');
    sb.writeln('Terima Kasih!');

    // 2. Launch URL
    // Format phone: if 08.., replace with 628..
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final url = Uri.parse(
        "${AppConfig.whatsappAppUrl}?phone=$cleanPhone&text=${Uri.encodeComponent(sb.toString())}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      await _upsertPromoContact(
          phone: cleanPhone, name: txn['customerName']?.toString());
    } else {
      debugPrint('Could not launch WhatsApp');
      // Fallback: try https link
      final webUrl = Uri.parse(
          "${AppConfig.whatsappWebUrl}/$cleanPhone?text=${Uri.encodeComponent(sb.toString())}");
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        await _upsertPromoContact(
            phone: cleanPhone, name: txn['customerName']?.toString());
      }
    }
  }
}
