import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rana_merchant/providers/wallet_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_merchant/screens/scan_screen.dart'; // Ensure this exists
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rana_merchant/screens/support_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  final _currency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => context.read<WalletProvider>().loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Dompet Merchant',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, color: const Color(0xFFE07A5F))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          )
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            color: const Color(0xFFE07A5F),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Balance Card
                  _buildProfessionalCard(context, provider),

                  const SizedBox(height: 32),

                  // 2. Quick Actions
                  Text('Menu Cepat',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155))),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),

                  const SizedBox(height: 32),

                  // 3. Pending
                  if (provider.pendingTopUps.isNotEmpty ||
                      provider.pendingWithdrawals.isNotEmpty) ...[
                    _buildPendingSection(provider),
                    const SizedBox(height: 32),
                  ],

                  // 4. History Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Riwayat Transaksi',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155))),
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[400])
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryTabs(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widgets ---

  Widget _buildProfessionalCard(BuildContext context, WalletProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE07A5F), Color(0xFFE07A5F)], // Terra Cotta
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE07A5F).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
          const BoxShadow(
              color: Colors.white10,
              blurRadius: 0,
              offset: Offset(0, 0),
              spreadRadius: 1) // Inner stroke hint
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Saldo',
                      style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _currency.format(provider.balance),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
              // Logo or Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 24),
          // Divider
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 16),

          // Footer Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text('Merchant Pro',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Active',
                    style: GoogleFonts.outfit(
                        color: const Color(0xFFE07A5F),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.add,
        'label': 'Top Up',
        'color': const Color(0xFFE07A5F),
        'onTap': () => _showTopUpDialog(context)
      },
      {
        'icon': Icons.arrow_upward,
        'label': 'Tarik',
        'color': const Color(0xFFF2CC8F),
        'onTap': () => _showWithdrawDialog(context)
      },
      {
        'icon': Icons.swap_horiz,
        'label': 'Kirim',
        'color': const Color(0xFF3D405B),
        'onTap': () => _showTransferDialog(context)
      },
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scan',
        'color': const Color(0xFFE07A5F),
        'onTap': () => _scanQr(context)
      },
      {
        'icon': Icons.qr_code,
        'label': 'Minta',
        'color': const Color(0xFF81B29A),
        'onTap': () => _showReceiveDialog(context)
      },
      {
        'icon': Icons.more_horiz,
        'label': 'Lainnya',
        'color': Colors.grey,
        'onTap': () {}
      },
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.start,
      children: actions.map((a) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48 - 60) /
              4, // 4 cols approx
          child: Column(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                child: InkWell(
                  onTap: a['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: (a['color'] as Color).withOpacity(0.1),
                  highlightColor: (a['color'] as Color).withOpacity(0.05),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      // Color handled by Material
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Icon(a['icon'] as IconData,
                        color: a['color'] as Color, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(a['label'] as String,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center)
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTabs(WalletProvider provider) {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE07A5F).withOpacity(0.3))),
            labelColor: const Color(0xFFE07A5F),
            unselectedLabelColor: Colors.grey[500],
            labelStyle:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Masuk'),
              Tab(text: 'Keluar'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 400, // Fixed height for list or use shrink wrap carefully
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(provider.history),
              _buildHistoryList(provider.history
                  .where((i) => i['type'] == 'CASH_IN')
                  .toList()),
              _buildHistoryList(provider.history
                  .where((i) => i['type'] == 'CASH_OUT')
                  .toList()),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Tidak ada riwayat',
                style: GoogleFonts.outfit(color: Colors.grey[400])),
          ],
        ),
      );
    }

    // Group by Date
    // Simplified for now: just linear list but refined UI
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = history[i];
        final isIncome = item['type'] == 'CASH_IN';
        final color =
            isIncome ? const Color(0xFF81B29A) : const Color(0xFFE07A5F);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
              border: Border.all(color: Colors.grey[50]!)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['description'] ?? item['category'] ?? 'Transaksi',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                        DateFormat('dd MMM HH:mm')
                            .format(DateTime.parse(item['occurredAt'])),
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${_currency.format(double.parse(item['amount'].toString()))}',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
              )
            ],
          ),
        ).animate().fadeIn(delay: (50 * i).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildPendingSection(WalletProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menunggu Persetujuan',
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155))),
        const SizedBox(height: 12),
        ...provider.pendingTopUps.map(
            (e) => _buildPendingCard(e, 'Top Up', const Color(0xFFE07A5F))),
        ...provider.pendingWithdrawals.map(
            (e) => _buildPendingCard(e, 'Penarikan', const Color(0xFFE07A5F))),
      ],
    );
  }

  Widget _buildPendingCard(
      Map<String, dynamic> item, String type, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 8)
          ]),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$type Pending',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, color: color)),
                Text(_currency.format(item['amount']),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(DateFormat('dd MMM').format(DateTime.parse(item['createdAt'])),
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- Actions ---

  void _scanQr(BuildContext context) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (result == true) {
      context.read<WalletProvider>().loadData(); // Reload if success
    }
  }

  void _showReceiveDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FutureBuilder<Map<String, String>>(
                  future: ApiService().getSystemSettings(),
                  builder: (context, snapshot) {
                    final settings = snapshot.data ?? {};
                    final qrisUrl =
                        (settings['PLATFORM_QRIS_URL'] ?? '').trim();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Terima Pembayaran',
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (qrisUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              qrisUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.qr_code_2,
                                      size: 150, color: Colors.black),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.qr_code_2,
                                  size: 150, color: Color(0xFFE07A5F)),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          qrisUrl.isNotEmpty
                              ? 'Scan QRIS ini untuk membayar'
                              : 'QRIS belum tersedia. Hubungi admin.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            if (qrisUrl.isNotEmpty) {
                              await Share.share(qrisUrl);
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Bagikan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE07A5F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ));
  }

  // Reuse existing dialogs but styled better? To save space, assuming they are imported or redefined here.
  // For brevity, I will redefine them here with better styling matching the red theme.

  void _showTopUpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _TopUpSheet(),
    );
  }

  void _showTransferDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _TransferSheet(),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _WithdrawSheet(),
    );
  }
}

// ... Sheet Classes logic is mostly same but updated Colors ...
// I will keep the logic same but update Colors to Red basically.

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();
  @override
  State<_TopUpSheet> createState() => __TopUpSheetState();
}

class __TopUpSheetState extends State<_TopUpSheet> {
  final _amountCtrl = TextEditingController();
  XFile? _imageFile;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _imageFile == null) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<WalletProvider>(context, listen: false)
          .topUp(double.parse(_amountCtrl.text), _imageFile!);
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Up Saldo',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3))),
            child: Row(
              children: [
                const CircleAvatar(
                    backgroundColor: Color(0xFFE07A5F),
                    child: Icon(Icons.account_balance, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BCA Virtual Account',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF881337),
                              fontWeight: FontWeight.bold)),
                      Text('88012 081234567890',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFFE07A5F)),
                    onPressed: () {})
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Nominal Transfer', prefixText: 'Rp ')),
          const SizedBox(height: 16),
          Text('Bukti Transfer (Wajib)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[50]),
              alignment: Alignment.center,
              child: _imageFile == null
                  ? Column(children: [
                      const SizedBox(height: 50),
                      Icon(Icons.cloud_upload_outlined,
                          size: 40, color: Colors.grey[400]),
                      Text('Tap untuk upload',
                          style: GoogleFonts.outfit(color: Colors.grey[600]))
                    ])
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(_imageFile!.path,
                              fit: BoxFit.cover, width: double.infinity)
                          : Image.file(File(_imageFile!.path),
                              fit: BoxFit.cover, width: double.infinity)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE07A5F),
                      padding: const EdgeInsets.all(16)),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kirim Pengajuan'))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TransferSheet extends StatefulWidget {
  const _TransferSheet();
  @override
  State<_TransferSheet> createState() => __TransferSheetState();
}

class __TransferSheetState extends State<_TransferSheet> {
  final _amountCtrl = TextEditingController();
  final _storeIdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _storeIdCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<WalletProvider>(context, listen: false).transfer(
          _storeIdCtrl.text, double.parse(_amountCtrl.text), _noteCtrl.text);
      if (!context.mounted) return;
      Navigator.pop(context); // Close sheet on success
    } catch (e) {
      if (!context.mounted) return;
      // Show Modal Error as requested
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE07A5F)),
                    const SizedBox(width: 10),
                    Text('Transer Gagal',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 18))
                  ],
                ),
                content: Text(e.toString().replaceAll('Exception: ', ''),
                    style: GoogleFonts.outfit(color: const Color(0xFF334155))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE07A5F))))
                ],
              ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer ke Merchant Lain',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
              controller: _storeIdCtrl,
              decoration:
                  const InputDecoration(labelText: 'Store ID Penerima')),
          const SizedBox(height: 16),
          TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Nominal Transfer', prefixText: 'Rp ')),
          const SizedBox(height: 16),
          TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan')),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE07A5F),
                      padding: const EdgeInsets.all(16)),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Transfer Sekarang'))),
          const SizedBox(height: 24)
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();
  @override
  State<_WithdrawSheet> createState() => __WithdrawSheetState();
}

class __WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<WalletProvider>(context, listen: false).withdraw(
          double.parse(_amountCtrl.text), _bankCtrl.text, _accountCtrl.text);
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tarik Saldo',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Nominal Penarikan', prefixText: 'Rp ')),
          const SizedBox(height: 16),
          TextField(
              controller: _bankCtrl,
              decoration: const InputDecoration(labelText: 'Nama Bank')),
          const SizedBox(height: 16),
          TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nomor Rekening')),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE07A5F),
                      padding: const EdgeInsets.all(16)),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Ajukan Penarikan'))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
