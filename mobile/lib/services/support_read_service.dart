import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class SupportReadService {
  static final SupportReadService _instance = SupportReadService._internal();
  factory SupportReadService() => _instance;
  SupportReadService._internal();

  String _key(String ticketId) => 'support_ticket_last_opened_$ticketId';

  Future<void> markOpened(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(ticketId), DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastOpened(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key(ticketId));
    if (v == null || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  bool _isAdminMessage(Map msg) {
    final sender = msg['senderType']?.toString()?.toUpperCase() ?? '';
    final isAdmin = msg['isAdmin'] == true;
    return isAdmin || sender == 'ADMIN';
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return DateTime.tryParse(s);
  }

  Future<int> getUnreadCount() async {
    final tickets = await ApiService().getTickets();
    int unread = 0;
    for (final t in tickets) {
      if (t is! Map) continue;
      final id = t['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final detail = await ApiService().getTicketDetail(id);
      final List<dynamic> msgs = detail['messages'] is List ? detail['messages'] : const [];
      DateTime? lastAdmin;
      for (final m in msgs) {
        if (m is! Map) continue;
        if (_isAdminMessage(m)) {
          final dt = _parseDate(m['createdAt']);
          if (dt != null && (lastAdmin == null || dt.isAfter(lastAdmin!))) {
            lastAdmin = dt;
          }
        }
      }
      if (lastAdmin == null) continue;
      final lastOpened = await getLastOpened(id);
      if (lastOpened == null || lastAdmin.isAfter(lastOpened)) {
        unread++;
      }
    }
    return unread;
  }
}
