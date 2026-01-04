import 'package:flutter/material.dart';
import 'package:rana_merchant/config/app_config.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/screens/ticket_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;

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
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createTicket() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Tiket Bantuan Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                          labelText: 'Judul keluhan/pertanyaan')),
                  TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                          labelText: 'Ceritakan kendalamu di sini'),
                      maxLines: 3),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty &&
                          messageController.text.isNotEmpty) {
                        Navigator.pop(context);
                        setState(() => isLoading = true);
                        try {
                          await ApiService().createTicket(
                              titleController.text, messageController.text);
                          await _fetch();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Gagal membuat tiket: $e')));
                          }
                          setState(() => isLoading = false);
                        }
                      }
                    },
                    child: const Text('Kirim'))
              ],
            ));
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
      appBar: AppBar(title: const Text('Bantuan & Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        label: const Text('Buat Tiket Bantuan'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE07A5F),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // WhatsApp Card
                  Card(
                    color: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () => _launchUrl(
                          '${AppConfig.supportWhatsAppUrl}?text=Halo%20Admin%20Rana%20POS,%20saya%20butuh%20bantuan'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.chat,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Chat WhatsApp Admin',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  SizedBox(height: 4),
                                  Text('Respon cepat dalam 5 menit',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white70)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tiket Bantuan Saya',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.confirmation_number,
                                        color: Colors.blue)),
                                title: Text(ticket['subject'] ?? 'No Subject',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text('$status • $date',
                                    style: TextStyle(
                                        color: status == 'OPEN'
                                            ? Colors.green
                                            : Colors.grey)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => TicketDetailScreen(
                                              ticketId: ticket['id'])));
                                },
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
