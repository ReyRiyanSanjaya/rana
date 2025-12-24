import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/screens/ticket_detail_screen.dart';

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
        title: const Text('New Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Subject')),
            TextField(controller: messageController, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => isLoading = true);
                try {
                  await ApiService().createTicket(titleController.text, messageController.text);
                  await _fetch();
                } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                   setState(() => isLoading = false);
                }
              }
            }, 
            child: const Text('Submit')
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket, 
        label: const Text('New Ticket'),
        icon: const Icon(Icons.add),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // WhatsApp Card
                Card(
                  color: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka WhatsApp Admin...'))); 
                       // In real app: launchUrl(Uri.parse('https://wa.me/6281234567890'));
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                           const Icon(Icons.chat, color: Colors.white, size: 32),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: const [
                                 Text('Chat WhatsApp Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                 SizedBox(height: 4),
                                 Text('Respon cepat dalam 5 menit', style: TextStyle(color: Colors.white70, fontSize: 12)),
                               ],
                             ),
                           ),
                           const Icon(Icons.arrow_forward, color: Colors.white70)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Tiket Bantuan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),

                tickets.isEmpty 
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada tiket bantuan.')))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.confirmation_number, color: Colors.blue)),
                            title: Text(ticket['subject'] ?? 'No Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${ticket['status']} • ${ticket['createdAt'].toString().substring(0, 10)}', style: TextStyle(color: ticket['status'] == 'OPEN' ? Colors.green : Colors.grey)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket['id'])));
                            },
                          ),
                        );
                      },
                    ),
              ],
            ),
    );
  }
}
