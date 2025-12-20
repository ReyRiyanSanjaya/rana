import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec

class DigitalReceiptService {
  
  static Future<void> sendViaWhatsApp(String phone, Map<String, dynamic> txn, List<Map<String, dynamic>> items) async {
    // 1. Format Message
    final sb = StringBuffer();
    sb.writeln('*RANA POS RECEIPT*');
    sb.writeln('----------------');
    sb.writeln('Date: ${txn['occurredAt']}');
    sb.writeln('ID: ${txn['offlineId'].toString().substring(0,8)}');
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

    final url = Uri.parse("whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(sb.toString())}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch WhatsApp');
      // Fallback: try https link
      final webUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(sb.toString())}");
      if(await canLaunchUrl(webUrl)) await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}
