import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_merchant/config/app_config.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/flash_sales_screen.dart';
import 'package:rana_merchant/screens/marketing_screen.dart';
import 'package:rana_merchant/services/order_service.dart';
import 'package:rana_merchant/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class PromoHubScreen extends StatefulWidget {
  const PromoHubScreen({super.key});

  @override
  State<PromoHubScreen> createState() => _PromoHubScreenState();
}

class _PromoHubScreenState extends State<PromoHubScreen> {
  static const _shareDateKey = 'promo_share_date';
  static const _shareCountKey = 'promo_share_count';
  static const _shareStreakKey = 'promo_share_streak';
  static const _shareReminderEnabledKey = 'promo_share_reminder_enabled';
  static const _shareReminderHourKey = 'promo_share_reminder_hour';
  static const _shareReminderMinuteKey = 'promo_share_reminder_minute';

  int _shareToday = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _shareReminderEnabled = false;
  int _shareReminderHour = 9;
  int _shareReminderMinute = 0;

  String _formatDay(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDay(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDay(now);
    final yesterdayStr = _formatDay(now.subtract(const Duration(days: 1)));

    final lastShareDate = prefs.getString(_shareDateKey);
    final savedCount = prefs.getInt(_shareCountKey) ?? 0;
    final savedStreak = prefs.getInt(_shareStreakKey) ?? 0;

    int shareToday = 0;
    int streak = 0;

    if (lastShareDate == todayStr) {
      shareToday = savedCount;
      streak = savedStreak;
    } else if (lastShareDate == yesterdayStr) {
      shareToday = 0;
      streak = savedStreak;
    } else {
      shareToday = 0;
      streak = 0;
    }

    if (!mounted) return;
    setState(() {
      _shareToday = shareToday;
      _streak = streak;
      _shareReminderEnabled = prefs.getBool(_shareReminderEnabledKey) ?? false;
      _shareReminderHour = prefs.getInt(_shareReminderHourKey) ?? 9;
      _shareReminderMinute = prefs.getInt(_shareReminderMinuteKey) ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _recordShare() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDay(now);
    final yesterdayStr = _formatDay(now.subtract(const Duration(days: 1)));

    final lastShareDate = prefs.getString(_shareDateKey);
    final savedCount = prefs.getInt(_shareCountKey) ?? 0;
    final savedStreak = prefs.getInt(_shareStreakKey) ?? 0;

    int newCount = 1;
    int newStreak = 1;

    if (lastShareDate == todayStr) {
      newCount = savedCount + 1;
      newStreak = savedStreak == 0 ? 1 : savedStreak;
    } else if (lastShareDate == yesterdayStr) {
      newCount = 1;
      newStreak = savedStreak + 1;
    } else {
      newCount = 1;
      newStreak = 1;
    }

    await prefs.setString(_shareDateKey, todayStr);
    await prefs.setInt(_shareCountKey, newCount);
    await prefs.setInt(_shareStreakKey, newStreak);

    if (!mounted) return;
    setState(() {
      _shareToday = newCount;
      _streak = newStreak;
    });
  }

  Future<void> _shareText(String text) async {
    if (text.trim().isEmpty) return;
    await Share.share(text);
    await _recordShare();
  }

  Future<void> _shareViaWhatsApp(String text) async {
    if (text.trim().isEmpty) return;
    final ok = await _launchWhatsApp(text: text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka WhatsApp. Pastikan WhatsApp terpasang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _recordShare();
  }

  String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return digits;
  }

  Future<bool> _launchWhatsApp({String? phone, required String text}) async {
    final message = text.trim();
    if (message.isEmpty) return false;

    final normalizedPhone = phone == null
        ? null
        : _normalizePhone(phone).trim().isEmpty
            ? null
            : _normalizePhone(phone);

    final whatsappUri = Uri.parse(
      normalizedPhone == null
          ? '${AppConfig.whatsappAppUrl}?text=${Uri.encodeComponent(message)}'
          : '${AppConfig.whatsappAppUrl}?phone=$normalizedPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        return await launchUrl(whatsappUri,
            mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    final webUri = Uri.parse(
      normalizedPhone == null
          ? '${AppConfig.whatsappWebUrl}/?text=${Uri.encodeComponent(message)}'
          : '${AppConfig.whatsappWebUrl}/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return false;
  }

  Future<void> _setShareReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareReminderEnabledKey, enabled);

    if (enabled) {
      await NotificationService().scheduleDailyAtTime(
        id: 9001,
        title: 'Target promosi hari ini',
        body: 'Bagikan promo minimal 3x untuk dorong penjualan.',
        hour: _shareReminderHour,
        minute: _shareReminderMinute,
      );
    } else {
      await NotificationService().cancel(9001);
    }

    if (!mounted) return;
    setState(() => _shareReminderEnabled = enabled);
  }

  Future<void> _pickShareReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _shareReminderHour, minute: _shareReminderMinute),
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shareReminderHourKey, picked.hour);
    await prefs.setInt(_shareReminderMinuteKey, picked.minute);

    if (!mounted) return;
    setState(() {
      _shareReminderHour = picked.hour;
      _shareReminderMinute = picked.minute;
    });

    if (_shareReminderEnabled) {
      await NotificationService().scheduleDailyAtTime(
        id: 9001,
        title: 'Target promosi hari ini',
        body: 'Bagikan promo minimal 3x untuk dorong penjualan.',
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16);
    final subtitleStyle =
        GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promosi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pusat Promosi',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
              'Jalankan promo, bagikan ke pelanggan, dan hitung untungnya dari satu tempat.',
              style: GoogleFonts.poppins(color: Colors.grey[700])),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator()))
              : _PromoStatsCard(
                  shareToday: _shareToday,
                  streak: _streak,
                  reminderEnabled: _shareReminderEnabled,
                  reminderHour: _shareReminderHour,
                  reminderMinute: _shareReminderMinute,
                  onToggleReminder: _setShareReminderEnabled,
                  onPickTime: _pickShareReminderTime,
                ),
          const SizedBox(height: 16),
          Text('Aksi cepat',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          _PromoQuickActions(
            onOpenFlashSale: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FlashSalesScreen())),
            onOpenMarketing: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketingScreen())),
            onOpenBroadcast: () {
              _openBroadcastSheet(context);
            },
            onOpenCalculator: () {
              _openCalculatorSheet(context);
            },
            onOpenIdeas: () {
              _openIdeasSheet(context);
            },
            onOpenRecommendations: () {
              _openRecommendationsSheet(context);
            },
            onOpenCalendar: () {
              _openCalendarSheet(context);
            },
            onOpenCustomers: () {
              _openCustomersSheet(context);
            },
          ),
          const SizedBox(height: 18),
          Text('Kelola promosi',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          _PromoCard(
            icon: Icons.flash_on,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            title: 'Flash Sale',
            subtitle: 'Naikkan urgency dengan promo waktu terbatas',
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FlashSalesScreen())),
          ),
          _PromoCard(
            icon: Icons.campaign,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Iklan (Marketing Studio)',
            subtitle: 'Buat poster, caption, dan terapkan diskon ke produk',
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketingScreen())),
          ),
          const SizedBox(height: 6),
          _PromoCard(
            icon: Icons.lightbulb_outline,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            title: 'Ide promosi siap pakai',
            subtitle: 'Template konten + CTA untuk tingkatkan order',
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            onTap: () {
              _openIdeasSheet(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openBroadcastSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BroadcastSheet(
        onShare: _shareText,
        onWhatsApp: _shareViaWhatsApp,
      ),
    );
  }

  Future<void> _openCalculatorSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PromoCalculatorSheet(),
    );
  }

  Future<void> _openIdeasSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _IdeasSheet(
        onShare: _shareText,
      ),
    );
  }

  Future<void> _openRecommendationsSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PromoRecommendationsSheet(),
    );
  }

  Future<void> _openCalendarSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PromoCalendarSheet(),
    );
  }

  Future<void> _openCustomersSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PromoCustomersSheet(),
    );
  }
}

class _PromoStatsCard extends StatelessWidget {
  final int shareToday;
  final int streak;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final Future<void> Function(bool enabled) onToggleReminder;
  final Future<void> Function() onPickTime;

  const _PromoStatsCard({
    required this.shareToday,
    required this.streak,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onToggleReminder,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    const dailyTarget = 3;
    final progress = (shareToday / dailyTarget).clamp(0, 1).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Share hari ini',
                    value: '$shareToday',
                    icon: Icons.share_outlined,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Streak',
                    value: '$streak hari',
                    icon: Icons.local_fire_department_outlined,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPickTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminder target share',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: reminderEnabled,
                      onChanged: (v) => onToggleReminder(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target harian: ${dailyTarget}x share',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[700])),
                Text('${(progress * 100).round()}%',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[700])),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoQuickActions extends StatelessWidget {
  final VoidCallback onOpenFlashSale;
  final VoidCallback onOpenMarketing;
  final VoidCallback onOpenBroadcast;
  final VoidCallback onOpenCalculator;
  final VoidCallback onOpenIdeas;
  final VoidCallback onOpenRecommendations;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenCustomers;

  const _PromoQuickActions({
    required this.onOpenFlashSale,
    required this.onOpenMarketing,
    required this.onOpenBroadcast,
    required this.onOpenCalculator,
    required this.onOpenIdeas,
    required this.onOpenRecommendations,
    required this.onOpenCalendar,
    required this.onOpenCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionChip(
          icon: Icons.flash_on,
          label: 'Flash Sale',
          color: const Color(0xFFF97316),
          onTap: onOpenFlashSale,
        ),
        _QuickActionChip(
          icon: Icons.campaign,
          label: 'Poster & Diskon',
          color: const Color(0xFF3B82F6),
          onTap: onOpenMarketing,
        ),
        _QuickActionChip(
          icon: Icons.chat_bubble_outline,
          label: 'Broadcast WA',
          color: const Color(0xFF10B981),
          onTap: onOpenBroadcast,
        ),
        _QuickActionChip(
          icon: Icons.people_outline,
          label: 'Pelanggan',
          color: const Color(0xFF0EA5E9),
          onTap: onOpenCustomers,
        ),
        _QuickActionChip(
          icon: Icons.insights_outlined,
          label: 'Rekomendasi',
          color: const Color(0xFF8B5CF6),
          onTap: onOpenRecommendations,
        ),
        _QuickActionChip(
          icon: Icons.event_note_outlined,
          label: 'Kalender',
          color: const Color(0xFF64748B),
          onTap: onOpenCalendar,
        ),
        _QuickActionChip(
          icon: Icons.calculate_outlined,
          label: 'Kalkulator',
          color: const Color(0xFF6366F1),
          onTap: onOpenCalculator,
        ),
        _QuickActionChip(
          icon: Icons.auto_awesome,
          label: 'Ide Konten',
          color: const Color(0xFF7C3AED),
          onTap: onOpenIdeas,
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final VoidCallback onTap;

  const _PromoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: subtitleStyle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadcastSheet extends StatefulWidget {
  final Future<void> Function(String text) onShare;
  final Future<void> Function(String text) onWhatsApp;

  const _BroadcastSheet({
    required this.onShare,
    required this.onWhatsApp,
  });

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _productCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _benefitCtrl = TextEditingController(
      text: 'Gratis ongkir / bonus kecil / stok terbatas');
  final _ctaCtrl =
      TextEditingController(text: 'Balas chat ini ya kak, nanti aku proses 🙏');
  final _captionCtrl = TextEditingController();
  String _tone = 'Cepat & Urgent';
  bool _loadingProducts = true;
  String? _selectedProductId;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final top = await DatabaseHelper.instance.getTopSellingProductsDetailed(
        limit: 10,
        start: start,
        end: end,
      );
      final unsold = await DatabaseHelper.instance.getUnsoldProducts(
        limit: 10,
        start: start,
        end: end,
        minStock: 1,
      );

      final combined = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final p in [...top, ...unsold]) {
        final id = (p['productId'] ?? '').toString();
        final name = (p['name'] ?? '').toString().trim();
        if (id.isEmpty || name.isEmpty) continue;
        if (seen.contains(id)) continue;
        seen.add(id);
        combined.add(Map<String, dynamic>.from(p));
      }

      if (combined.isEmpty) {
        final all = await DatabaseHelper.instance.getAllProducts();
        for (final p in all.take(15)) {
          final id = (p['id'] ?? '').toString();
          final name = (p['name'] ?? '').toString().trim();
          if (id.isEmpty || name.isEmpty) continue;
          combined.add({
            'productId': id,
            'name': name,
            'sellingPrice': p['sellingPrice'],
            'stock': p['stock'],
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _products = combined;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products = const [];
        _loadingProducts = false;
      });
    }
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    _priceCtrl.dispose();
    _benefitCtrl.dispose();
    _ctaCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  String _formatRupiah(int value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  int? _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  void _applySelectedProduct(String? productId) {
    if (productId == null) return;
    final p = _products.firstWhere(
      (e) => (e['productId'] ?? '').toString() == productId,
      orElse: () => const {},
    );
    final name = (p['name'] ?? '').toString();
    final price = (p['sellingPrice'] as num?)?.toDouble();
    setState(() => _selectedProductId = productId);
    if (name.trim().isNotEmpty) _productCtrl.text = name;
    if (price != null && price > 0) {
      _priceCtrl.text = price.round().toString();
    }
  }

  String _buildCaption() {
    final name = _productCtrl.text.trim().isEmpty
        ? 'produk pilihan'
        : _productCtrl.text.trim();
    final priceInt = _parseInt(_priceCtrl.text);
    final price = priceInt == null ? '' : _formatRupiah(priceInt);
    final benefit = _benefitCtrl.text.trim();
    final cta = _ctaCtrl.text.trim();

    final lines = <String>[];

    if (_tone == 'Cepat & Urgent') {
      lines.add('⚡ PROMO HARI INI ⚡');
      lines.add('');
      lines.add('$name ${price.isEmpty ? '' : 'cuma $price'}');
      if (benefit.isNotEmpty) lines.add('Bonus: $benefit');
      lines.add('');
      lines.add('Stok terbatas ya kak, siapa cepat dia dapat.');
      if (cta.isNotEmpty) {
        lines.add('');
        lines.add(cta);
      }
    } else if (_tone == 'Friendly') {
      lines.add('Halo kak 👋');
      lines.add('');
      lines.add(
          'Mau info promo nih: $name ${price.isEmpty ? '' : 'lagi promo jadi $price'}');
      if (benefit.isNotEmpty) lines.add('Benefit: $benefit');
      if (cta.isNotEmpty) {
        lines.add('');
        lines.add(cta);
      }
    } else {
      lines.add('🔥 Promo Spesial 🔥');
      lines.add('');
      lines.add('$name ${price.isEmpty ? '' : '| $price'}');
      if (benefit.isNotEmpty) lines.add('Keterangan: $benefit');
      lines.add('');
      lines.add('Klik/Chat untuk order sekarang.');
      if (cta.isNotEmpty) {
        lines.add('');
        lines.add(cta);
      }
    }

    return lines
        .where((e) => e.trim().isNotEmpty || lines.length <= 2)
        .join('\n');
  }

  void _generate() {
    setState(() {
      _captionCtrl.text = _buildCaption();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.40,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + bottomInset,
            ),
            children: [
              Text(
                'Broadcast WhatsApp',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Bikin caption cepat lalu share/WA ke pelanggan.',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _tone,
                items: const [
                  DropdownMenuItem(
                      value: 'Cepat & Urgent', child: Text('Cepat & Urgent')),
                  DropdownMenuItem(value: 'Friendly', child: Text('Friendly')),
                  DropdownMenuItem(value: 'Simple', child: Text('Simple')),
                ],
                onChanged: (v) => setState(() => _tone = v ?? _tone),
                decoration: const InputDecoration(labelText: 'Gaya caption'),
              ),
              const SizedBox(height: 10),
              if (_loadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  items: _products.map((p) {
                    final id = (p['productId'] ?? '').toString();
                    final name = (p['name'] ?? '').toString();
                    final stock = (p['stock'] as num?)?.toInt();
                    final price = (p['sellingPrice'] as num?)?.toDouble();
                    final meta = <String>[];
                    if (price != null) {
                      meta.add(_formatRupiah(price.round()));
                    }
                    if (stock != null) meta.add('Stok $stock');
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                          meta.isEmpty ? name : '$name • ${meta.join(' • ')}'),
                    );
                  }).toList(),
                  onChanged: (v) => _applySelectedProduct(v),
                  decoration: const InputDecoration(
                      labelText: 'Pilih produk (data nyata)'),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _productCtrl,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                    labelText: 'Harga promo (angka saja)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _benefitCtrl,
                decoration:
                    const InputDecoration(labelText: 'Benefit (opsional)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ctaCtrl,
                decoration: const InputDecoration(labelText: 'CTA (opsional)'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Generate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (_captionCtrl.text.trim().isEmpty) _generate();
                        await widget.onShare(_captionCtrl.text);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (_captionCtrl.text.trim().isEmpty) _generate();
                    await widget.onWhatsApp(_captionCtrl.text);
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Kirim via WhatsApp'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _captionCtrl,
                maxLines: 6,
                decoration:
                    const InputDecoration(labelText: 'Caption (boleh diedit)'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PromoCalculatorSheet extends StatefulWidget {
  const _PromoCalculatorSheet();

  @override
  State<_PromoCalculatorSheet> createState() => _PromoCalculatorSheetState();
}

class _PromoCalculatorSheetState extends State<_PromoCalculatorSheet> {
  final _originalCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  int? _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  String _formatRupiah(int value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  @override
  void dispose() {
    _originalCtrl.dispose();
    _promoCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final original = _parseInt(_originalCtrl.text);
    final promo = _parseInt(_promoCtrl.text);
    final cost = _parseInt(_costCtrl.text);

    double? discountPct;
    int? profitNormal;
    int? profitPromo;
    double? marginPromo;

    if (original != null && original > 0 && promo != null && promo > 0) {
      discountPct = ((original - promo) / original) * 100.0;
    }

    if (cost != null && cost >= 0) {
      if (original != null) profitNormal = original - cost;
      if (promo != null) profitPromo = promo - cost;
      if (promo != null && promo > 0 && profitPromo != null) {
        marginPromo = (profitPromo / promo) * 100.0;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kalkulator Promo',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Cek diskon dan untung biar promo tetap cuan.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 14),
          TextField(
            controller: _originalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Harga normal'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Harga promo'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _costCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'HPP/Modal (opsional)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE07A5F).withOpacity(0.15),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultRow(
                    label: 'Diskon',
                    value: discountPct == null
                        ? '-'
                        : '${discountPct.clamp(0, 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 8),
                _ResultRow(
                    label: 'Harga promo',
                    value: promo == null ? '-' : _formatRupiah(promo)),
                const SizedBox(height: 8),
                _ResultRow(
                    label: 'Untung normal',
                    value: profitNormal == null
                        ? '-'
                        : _formatRupiah(profitNormal)),
                const SizedBox(height: 8),
                _ResultRow(
                    label: 'Untung promo',
                    value:
                        profitPromo == null ? '-' : _formatRupiah(profitPromo)),
                const SizedBox(height: 8),
                _ResultRow(
                    label: 'Margin promo',
                    value: marginPromo == null
                        ? '-'
                        : '${marginPromo.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        Text(value,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _IdeasSheet extends StatefulWidget {
  final Future<void> Function(String text) onShare;

  const _IdeasSheet({required this.onShare});

  @override
  State<_IdeasSheet> createState() => _IdeasSheetState();
}

class _IdeasSheetState extends State<_IdeasSheet> {
  bool _loading = true;
  List<String> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatRupiah(num value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final top = await DatabaseHelper.instance.getTopSellingProductsDetailed(
        limit: 5,
        start: start,
        end: end,
      );
      final unsold = await DatabaseHelper.instance.getUnsoldProducts(
        limit: 5,
        start: start,
        end: end,
        minStock: 3,
      );
      final low =
          await DatabaseHelper.instance.getLowStockProducts(threshold: 5);

      final ideas = <String>[];

      if (top.isNotEmpty) {
        final p = top.first;
        final name = (p['name'] ?? '').toString();
        final qty = (p['totalQty'] as num?)?.toInt() ?? 0;
        final price = (p['sellingPrice'] as num?)?.toDouble();
        ideas.add(
          'Flash Sale 2 jam: $name ${price == null ? '' : '(${_formatRupiah(price.round())}) '}| terjual $qty bulan ini. Batasi stok biar urgent.',
        );
      }

      for (final p in unsold.take(3)) {
        final name = (p['name'] ?? '').toString();
        final stock = (p['stock'] as num?)?.toInt() ?? 0;
        final price = (p['sellingPrice'] as num?)?.toDouble();
        ideas.add(
          'Diskon/bundling untuk $name ${price == null ? '' : '(${_formatRupiah(price.round())}) '}| stok $stock. Pasang label “Clear Stock”.',
        );
      }

      if (low.isNotEmpty) {
        final names = low
            .take(4)
            .map((p) => (p['name'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          ideas.add(
              'Produk hampir habis: ${names.join(', ')}. Buat konten “Last Stock” untuk dorong FOMO.');
        }
      }

      ideas.add(
        'Broadcast pelanggan lama: “Halo {nama}, hari ini ada promo khusus pelanggan lama. Mau aku proseskan?” (ganti {nama} otomatis).',
      );
      ideas.add(
        'A/B test: buat 2 versi caption (urgent vs friendly), lihat mana yang paling banyak chat masuk.',
      );

      if (ideas.isEmpty) {
        final all = await DatabaseHelper.instance.getAllProducts();
        final names = all
            .take(6)
            .map((p) => (p['name'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          ideas.add(
              'Pilih 3 produk: ${names.take(3).join(', ')}. Buat promo “Beli 2 Gratis 1” untuk naikkan jumlah item per order.');
        } else {
          ideas.add(
              'Tambahkan produk dulu supaya ide bisa dibuat dari data toko kamu.');
        }
      }

      if (!mounted) return;
      setState(() {
        _items = ideas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const ['Gagal memuat ide dari data. Coba lagi.'];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ide promosi siap pakai',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Otomatis dibuat dari data produk/penjualan toko kamu.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final text = items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onShare(text),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Bagikan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoRecommendationsSheet extends StatefulWidget {
  const _PromoRecommendationsSheet();

  @override
  State<_PromoRecommendationsSheet> createState() =>
      _PromoRecommendationsSheetState();
}

class _PromoRecommendationsSheetState
    extends State<_PromoRecommendationsSheet> {
  late final Future<List<Map<String, dynamic>>> _topFuture;
  late final Future<List<Map<String, dynamic>>> _unsoldFuture;

  @override
  void initState() {
    super.initState();
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    _topFuture = DatabaseHelper.instance.getTopSellingProductsDetailed(
      limit: 8,
      start: start,
      end: end,
    );
    _unsoldFuture = DatabaseHelper.instance.getUnsoldProducts(
      limit: 8,
      start: start,
      end: end,
      minStock: 3,
    );
  }

  String _formatRupiah(num value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disalin: $text')),
    );
  }

  void _openMarketing() {
    Navigator.pop(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MarketingScreen()));
  }

  void _openFlashSale() {
    Navigator.pop(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FlashSalesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekomendasi produk untuk promo',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Berdasarkan transaksi 30 hari terakhir (data lokal).',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 14),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('Paling laris (cocok untuk Flash Sale)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _topFuture,
                  builder: (context, snap) {
                    final items = snap.data ?? const <Map<String, dynamic>>[];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (items.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE07A5F).withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Belum ada data penjualan untuk rekomendasi.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: items.map((p) {
                        final name = (p['name'] ?? '').toString();
                        final qty = (p['totalQty'] as num?)?.toInt() ?? 0;
                        final revenue =
                            (p['totalRevenue'] as num?)?.toDouble() ?? 0.0;
                        final profit =
                            (p['totalProfit'] as num?)?.toDouble() ?? 0.0;
                        final margin =
                            (p['profitMargin'] as num?)?.toDouble() ?? 0.0;
                        final marginPct = (margin * 100).round();
                        final stock = (p['stock'] as num?)?.toInt();
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE07A5F).withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                'Terjual: $qty | Omzet: ${_formatRupiah(revenue)} | Profit: ${_formatRupiah(profit)} | Margin: $marginPct%${stock == null ? '' : ' | Stok: $stock'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _copy(name),
                                      child: const Text('Copy Nama'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _openFlashSale,
                                      child: const Text('Buat Flash Sale'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                    'Stok banyak tapi belum laku (cocok untuk diskon/bundling)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _unsoldFuture,
                  builder: (context, snap) {
                    final items = snap.data ?? const <Map<String, dynamic>>[];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (items.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE07A5F).withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Tidak ada produk unsold yang memenuhi kriteria.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: items.map((p) {
                        final name = (p['name'] ?? '').toString();
                        final stock = (p['stock'] as num?)?.toInt();
                        final price = (p['sellingPrice'] as num?)?.toDouble();
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE07A5F).withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(
                                '${stock == null ? '' : 'Stok: $stock'}${price == null ? '' : ' | Harga: ${_formatRupiah(price)}'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _copy(name),
                                      child: const Text('Copy Nama'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _openMarketing,
                                      child: const Text('Buat Diskon'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCalendarSheet extends StatefulWidget {
  const _PromoCalendarSheet();

  @override
  State<_PromoCalendarSheet> createState() => _PromoCalendarSheetState();
}

class _PromoCalendarSheetState extends State<_PromoCalendarSheet> {
  static const _plansKey = 'promo_plans_v1';
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    List<Map<String, dynamic>> plans = [];
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        plans =
            decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    plans.sort((a, b) {
      final da =
          DateTime.tryParse((a['startAt'] ?? '').toString()) ?? DateTime(1970);
      final db =
          DateTime.tryParse((b['startAt'] ?? '').toString()) ?? DateTime(1970);
      return da.compareTo(db);
    });
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plansKey, jsonEncode(_plans));
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, d MMM • HH:mm', 'id_ID').format(dt);
  }

  Future<void> _addPlan() async {
    final created = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddPromoPlanSheet(),
    );
    if (created == null) return;

    setState(() {
      _plans.add(created);
      _plans.sort((a, b) {
        final da = DateTime.tryParse((a['startAt'] ?? '').toString()) ??
            DateTime(1970);
        final db = DateTime.tryParse((b['startAt'] ?? '').toString()) ??
            DateTime(1970);
        return da.compareTo(db);
      });
    });
    await _persist();

    final remind = created['remind'] == true;
    final id = (created['id'] as num).toInt();
    final title = (created['title'] ?? 'Promo').toString();
    final startAt = DateTime.parse((created['startAt'] ?? '').toString());
    if (remind) {
      await NotificationService().scheduleOneTime(
        id: id,
        title: 'Mulai promo: $title',
        body: 'Saatnya jalankan promosi dan bagikan ke pelanggan.',
        scheduledAt: startAt,
      );
    } else {
      await NotificationService().cancel(id);
    }
  }

  Future<void> _deletePlan(int id) async {
    setState(() {
      _plans.removeWhere((p) => (p['id'] as num).toInt() == id);
    });
    await _persist();
    await NotificationService().cancel(id);
  }

  Future<void> _toggleRemind(int id, bool enabled) async {
    final idx = _plans.indexWhere((p) => (p['id'] as num).toInt() == id);
    if (idx < 0) return;
    setState(() {
      _plans[idx]['remind'] = enabled;
    });
    await _persist();

    final plan = _plans[idx];
    final title = (plan['title'] ?? 'Promo').toString();
    final startAt = DateTime.parse((plan['startAt'] ?? '').toString());

    if (enabled) {
      await NotificationService().scheduleOneTime(
        id: id,
        title: 'Mulai promo: $title',
        body: 'Saatnya jalankan promosi dan bagikan ke pelanggan.',
        scheduledAt: startAt,
      );
    } else {
      await NotificationService().cancel(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Kalender promosi',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              FilledButton.icon(
                onPressed: _addPlan,
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Simpan jadwal kampanye dan set reminder otomatis.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_plans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Belum ada jadwal promosi.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[700])),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = _plans[index];
                  final id = (p['id'] as num).toInt();
                  final title = (p['title'] ?? 'Promo').toString();
                  final startAt =
                      DateTime.parse((p['startAt'] ?? '').toString());
                  final remind = p['remind'] == true;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(title,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ),
                              IconButton(
                                onPressed: () => _deletePlan(id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          Text(_formatDateTime(startAt),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[700])),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Reminder',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ),
                              Switch(
                                value: remind,
                                onChanged: (v) => _toggleRemind(id, v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPromoPlanSheet extends StatefulWidget {
  const _AddPromoPlanSheet();

  @override
  State<_AddPromoPlanSheet> createState() => _AddPromoPlanSheetState();
}

class _AddPromoPlanSheetState extends State<_AddPromoPlanSheet> {
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _remind = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
  }

  void _save() {
    final title =
        _titleCtrl.text.trim().isEmpty ? 'Promo' : _titleCtrl.text.trim();
    final startAt =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final id = DateTime.now().millisecondsSinceEpoch % 2000000000;
    Navigator.pop<Map<String, dynamic>>(context, {
      'id': id,
      'title': title,
      'startAt': startAt.toIso8601String(),
      'remind': _remind,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateText = DateFormat('EEE, d MMM yyyy', 'id_ID').format(_date);
    final timeText =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah jadwal promosi',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Judul promo'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(dateText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(timeText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Aktifkan reminder',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              Switch(
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCustomersSheet extends StatefulWidget {
  const _PromoCustomersSheet();

  @override
  State<_PromoCustomersSheet> createState() => _PromoCustomersSheetState();
}

class _PromoCustomersSheetState extends State<_PromoCustomersSheet> {
  static const _contactsKey = 'promo_contacts_v1';
  final _messageCtrl = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  bool _importing = false;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contactsKey);
    List<Map<String, dynamic>> contacts = [];
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        contacts =
            decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contactsKey, jsonEncode(_contacts));
  }

  String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return digits;
  }

  String _applyTemplate(String template, {required String name}) {
    final safeName = name.trim().isEmpty ? 'kak' : name.trim();
    return template.replaceAll('{nama}', safeName);
  }

  Future<void> _openChat({required String phone, required String text}) async {
    final p = _normalizePhone(phone);
    final msg = text.trim();
    if (p.isEmpty || msg.isEmpty) return;

    final whatsappUri =
        Uri.parse('whatsapp://send?phone=$p&text=${Uri.encodeComponent(msg)}');
    final webUri =
        Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(msg)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        final ok =
            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        final ok =
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal membuka WhatsApp.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _importFromPickupOrders() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token != null && token.trim().isNotEmpty) {
        ApiService().setToken(token);
      }
      final orders = await _orderService.getIncomingOrders();
      final imported = <Map<String, dynamic>>[];
      for (final o in orders) {
        if (o is! Map) continue;
        final order = Map<String, dynamic>.from(o);
        final phone = (order['customerPhone'] ?? '').toString().trim();
        if (phone.isEmpty) continue;
        imported.add({
          'id': DateTime.now().microsecondsSinceEpoch % 2000000000,
          'name': (order['customerName'] ?? '').toString().trim(),
          'phone': phone,
        });
      }

      final existingPhones = _contacts
          .map((c) => _normalizePhone((c['phone'] ?? '').toString()))
          .toSet();
      int added = 0;
      for (final c in imported) {
        final p = _normalizePhone((c['phone'] ?? '').toString());
        if (p.isEmpty) continue;
        if (existingPhones.contains(p)) continue;
        existingPhones.add(p);
        _contacts.add({'id': c['id'], 'name': c['name'], 'phone': p});
        added += 1;
      }

      setState(() {});
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(added == 0
                  ? 'Tidak ada pelanggan baru.'
                  : 'Berhasil import $added pelanggan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal import: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _addContact() async {
    final created = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddCustomerSheet(),
    );
    if (created == null) return;
    setState(() => _contacts.add(created));
    await _persist();
  }

  Future<void> _deleteContact(int id) async {
    setState(
        () => _contacts.removeWhere((c) => (c['id'] as num).toInt() == id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pelanggan (daftar broadcast)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              IconButton(
                onPressed: _importing ? null : _importFromPickupOrders,
                icon: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
              ),
              FilledButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Simpan kontak pelanggan, lalu kirim promo cepat via WhatsApp.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(labelText: 'Pesan promo (opsional)'),
          ),
          const SizedBox(height: 6),
          Text('Tip: pakai {nama} untuk personalisasi.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_contacts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                    'Belum ada pelanggan. Tambahkan kontak untuk mulai broadcast.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[700])),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final c = _contacts[index];
                  final id = (c['id'] as num).toInt();
                  final name = (c['name'] ?? '').toString();
                  final phone = (c['phone'] ?? '').toString();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(name.isEmpty ? phone : name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800)),
                              ),
                              IconButton(
                                onPressed: () => _deleteContact(id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          if (name.isNotEmpty)
                            Text(phone,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[700])),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    final text = _applyTemplate(
                                        _messageCtrl.text,
                                        name: name);
                                    _openChat(phone: phone, text: text);
                                  },
                                  child: const Text('Kirim WA'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    final text = _messageCtrl.text
                                            .trim()
                                            .isEmpty
                                        ? 'Halo kak, ada promo terbaru nih 🙏'
                                        : _messageCtrl.text.trim();
                                    await _openChat(
                                        phone: phone,
                                        text: _applyTemplate(text, name: name));
                                  },
                                  child: const Text('Kirim Promo'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch % 2000000000;
    Navigator.pop<Map<String, dynamic>>(context, {
      'id': id,
      'name': name,
      'phone': phone,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah pelanggan',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama (opsional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'No. WhatsApp'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
