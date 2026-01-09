import 'package:flutter/material.dart';
import 'package:rana_merchant/config/app_config.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/screens/ticket_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_merchant/services/support_read_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;
  Map<String, bool> _unreadMap = {};
  final List<Map<String, String>> _templates = const [
    {
      'subject': 'Printer tidak terhubung',
      'message':
          'Halo Admin, saya mengalami kendala printer Bluetooth tidak terhubung saat mencetak struk. Mohon bantuannya.'
    },
    {
      'subject': 'Transaksi gagal tersimpan',
      'message':
          'Halo Admin, ada transaksi di kasir yang tidak tersimpan. Mohon dibantu pengecekan.'
    },
    {
      'subject': 'Stok tidak sinkron',
      'message':
          'Halo Admin, stok produk di aplikasi dan server tidak sama setelah sinkronisasi. Mohon dibantu.'
    },
    {
      'subject': 'Tidak bisa login',
      'message':
          'Halo Admin, saya tidak bisa login ke aplikasi merchant. Mohon dibantu reset akses.'
    },
    {
      'subject': 'Bug tampilan laporan',
      'message':
          'Halo Admin, tampilan laporan harian tidak sesuai. Mohon dibantu perbaikan.'
    },
  ];
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getTickets();
      setState(() {
        tickets = data;
        isLoading = false;
      });
      await _computeUnread();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _computeUnread() async {
    final map = <String, bool>{};
    for (final t in tickets) {
      if (t is! Map) continue;
      final id = t['id']?.toString();
      if (id == null || id.isEmpty) continue;
      try {
        final detail = await ApiService().getTicketDetail(id);
        final List<dynamic> msgs =
            detail['messages'] is List ? detail['messages'] : const [];
        DateTime? lastAdmin;
        for (final m in msgs) {
          if (m is! Map) continue;
          final sender = m['senderType']?.toString()?.toUpperCase() ?? '';
          final isAdmin = m['isAdmin'] == true || sender == 'ADMIN';
          if (!isAdmin) continue;
          final dtStr = m['createdAt']?.toString();
          final dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
          if (dt != null && (lastAdmin == null || dt.isAfter(lastAdmin))) {
            lastAdmin = dt;
          }
        }
        if (lastAdmin == null) {
          map[id] = false;
        } else {
          final lastOpened = await SupportReadService().getLastOpened(id);
          map[id] = lastOpened == null || lastAdmin.isAfter(lastOpened);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _unreadMap = map);
  }

  Future<void> _createTicket() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final media = MediaQuery.of(ctx);
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding:
                EdgeInsets.fromLTRB(16, 16, 16, 16 + media.viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tiket Bantuan Baru',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                            labelText: 'Judul keluhan/pertanyaan')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                            labelText: 'Ceritakan kendalamu di sini'),
                        maxLines: 4),
                    const SizedBox(height: 12),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Gunakan Template',
                            style: TextStyle(
                                color: Color(0xFFE07A5F),
                                fontSize: 14,
                                fontWeight: FontWeight.w600))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: _templates.length,
                        itemBuilder: (c, i) {
                          final t = _templates[i];
                          return InkWell(
                            onTap: () {
                              titleController.text = t['subject'] ?? '';
                              messageController.text = t['message'] ?? '';
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 240,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['subject'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(t['message'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: FilledButton(
                                onPressed: () async {
                                  if (titleController.text.isEmpty ||
                                      messageController.text.isEmpty) return;
                                  Navigator.pop(ctx);
                                  setState(() => isLoading = true);
                                  try {
                                    await ApiService().createTicket(
                                        titleController.text,
                                        messageController.text);
                                    await _fetch();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Gagal membuat tiket: $e')));
                                    }
                                    setState(() => isLoading = false);
                                  }
                                },
                                child: const Text('Kirim')))
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    final str = dateStr.toString();
    if (str.length >= 10) return str.substring(0, 10);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        centerTitle: true,
        title: Text('Bantuan & Support',
            style: GoogleFonts.poppins(
                color: const Color(0xFFE07A5F),
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [Color(0xFFE07A5F), Color(0xFFD8654F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFE07A5F).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        child: AnimatedScale(
          scale: _fabPressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() => _fabPressed = false);
                _createTicket();
              },
              onTapDown: (_) => setState(() => _fabPressed = true),
              onTapCancel: () => setState(() => _fabPressed = false),
              onTapUp: (_) => setState(() => _fabPressed = false),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.white24, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Buat Tiket Bantuan',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // WhatsApp Card
                  InkWell(
                      onTap: () => _launchUrl(
                          '${AppConfig.supportWhatsAppUrl}?text=Halo%20Admin%20Rana%20POS,%20saya%20butuh%20bantuan'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFFE07A5F),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    const Color(0xFFE07A5F).withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.chat,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chat WhatsApp Admin',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Respon cepat dalam 5 menit',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                            )
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  Text('Tiket Bantuan Saya',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 16),

                  tickets.isEmpty
                      ? const Center(
                          child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('Belum ada tiket bantuan.')))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            final status = ticket['status'] ?? 'OPEN';
                            final date = _formatDate(ticket['createdAt']);
                            final id = ticket['id']?.toString() ?? '';
                            final unread = _unreadMap[id] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  TicketDetailScreen(
                                                      ticketId: ticket['id'])))
                                      .then((_) => _computeUnread());
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE07A5F)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle),
                                      child: const Icon(
                                          Icons.confirmation_number,
                                          color: Color(0xFFE07A5F)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket['subject'] ?? 'No Subject',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: const Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: status == 'OPEN'
                                                        ? const Color(
                                                                0xFFE07A5F)
                                                            .withOpacity(0.1)
                                                        : status ==
                                                                'IN_PROGRESS'
                                                            ? const Color(
                                                                    0xFFE07A5F)
                                                                .withOpacity(
                                                                    0.1)
                                                            : Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999)),
                                                child: Text(
                                                  status.toString(),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: status == 'OPEN'
                                                          ? const Color(
                                                              0xFFE07A5F)
                                                          : status ==
                                                                  'IN_PROGRESS'
                                                              ? const Color(
                                                                  0xFFE07A5F)
                                                              : Colors.grey),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(date,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    unread
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFE07A5F),
                                                shape: BoxShape.circle),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                shape: BoxShape.circle),
                                            child: const Icon(
                                                Icons.chevron_right,
                                                color: Color(0xFF94A3B8)),
                                          )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
      ),
    );
  }
}
