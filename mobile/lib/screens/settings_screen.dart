import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/edit_profile_screen.dart';
import 'package:rana_merchant/screens/printer_settings_screen.dart';
import 'package:rana_merchant/screens/receipt_settings_screen.dart';
import 'package:rana_merchant/screens/privacy_policy_screen.dart';
import 'package:rana_merchant/screens/support_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rana_merchant/services/support_read_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '1.0.0';
  int _unreadSupportCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    Future.microtask(_refreshSupportBadge);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  Future<void> _refreshSupportBadge() async {
    try {
      final unread = await SupportReadService().getUnreadCount();
      if (!mounted) return;
      setState(() {
        _unreadSupportCount = unread;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Soft Beige Background
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          final businessName = user?['businessName'] ?? 'Nama Toko';
          final ownerName = user?['name'] ?? 'Pemilik Toko';
          final initial =
              businessName.isNotEmpty ? businessName[0].toUpperCase() : 'T';

          return CustomScrollView(
            slivers: [
              // 1. Professional App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFFFFF8F0),
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'Pengaturan',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFFE07A5F),
                      fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFE07A5F)),
                    tooltip: 'Keluar',
                    onPressed: () => _confirmLogout(context),
                  )
                ],
              ),

              // 2. Profile Header Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A5F).withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: (user?['storeImage'] != null &&
                                  user!['storeImage'].toString().isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(ApiService()
                                      .resolveFileUrl(user['storeImage'])),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: (user?['storeImage'] == null ||
                                user!['storeImage'].toString().isEmpty)
                            ? Text(
                                initial,
                                style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE07A5F)),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ownerName,
                              style: GoogleFonts.outfit(
                                  fontSize: 14, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(
                                            initialData: user ?? {})));
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'Edit Profil',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFE07A5F)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 12, color: Color(0xFFE07A5F))
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // 3. Settings Groups
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('Toko & Perangkat'),
                  _buildReferralCard(),
                  _buildSettingsGroup([
                    _buildSettingsItem(
                      icon: Icons.print_rounded,
                      title: 'Printer Bluetooth',
                      subtitle: 'Atur koneksi printer struk',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrinterSettingsScreen())),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Pengaturan Struk',
                      subtitle: 'Ukuran kertas, footer, dll',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReceiptSettingsScreen())),
                    ),
                  ]),
                  _buildSectionHeader('Informasi & Bantuan'),
                  _buildSettingsGroup([
                    _buildSettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Kebijakan Privasi',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Hubungi Bantuan',
                      subtitle: 'Pusat Bantuan & Chat Admin',
                      badgeCount: _unreadSupportCount,
                      onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SupportScreen()))
                          .then((_) => _refreshSupportBadge()),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Versi Aplikasi',
                      trailing: Text('v$_version',
                          style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Rana Merchant App\nMade with ❤️ for UMKM',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: const Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildReferralCard() {
    final currency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getReferralInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Memuat informasi referral...',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data ?? {};
        final code = (data['code'] ?? '').toString();
        final program = data['program'] is Map<String, dynamic>
            ? data['program'] as Map<String, dynamic>
            : <String, dynamic>{};
        final stats = data['stats'] is Map<String, dynamic>
            ? data['stats'] as Map<String, dynamic>
            : <String, dynamic>{};

        if (code.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Program Referral',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum ada kode referral aktif untuk toko ini.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        final totalReferrals = (stats['totalReferrals'] ?? 0).toString();
        final totalReleased =
            double.tryParse((stats['totalRewardReleased'] ?? 0).toString()) ??
                0;
        final programName = program['name']?.toString() ?? '';
        final shareText =
            'Daftar Rana POS pakai kode referral $code untuk dapat saldo wallet.';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Program Referral',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B)),
                ),
                if (programName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    programName,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Referral',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          code,
                          style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: const Color(0xFFE07A5F)),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A5F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Share.share(shareText);
                      },
                      child: const Text('Bagikan'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Referral',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalReferrals,
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward Cair',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(totalReleased),
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A5F),
                borderRadius: BorderRadius.circular(999),
              ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(title,
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B))),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: const Color(0xFF94A3B8)))
          : null,
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100]);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
