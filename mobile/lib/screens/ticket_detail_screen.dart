import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? ticket;
  bool isLoading = true;
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getTicketDetail(widget.ticketId);
      setState(() {
        ticket = data;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _reply() async {
    if (_msgController.text.trim().isEmpty) return;
    final msg = _msgController.text;
    _msgController.clear();
    
    // Optimistic update? No, just reload for simplicity
    try {
      await ApiService().replyTicket(widget.ticketId, msg);
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ticket?['subject'] ?? 'Chat')),
      body: Column(
        children: [
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket?['messages']?.length ?? 0,
                  itemBuilder: (context, index) {
                    final msg = ticket!['messages'][index];
                    final isMe = msg['senderType'] == 'MERCHANT' || msg['isAdmin'] == false;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'] ?? '',
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['createdAt'] != null ? msg['createdAt'].toString().substring(11, 16) : '',
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.indigo[100] : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: 'Type reply...', border: OutlineInputBorder()))),
                IconButton(onPressed: _reply, icon: const Icon(Icons.send, color: Colors.indigo))
              ],
            ),
          )
        ],
      ),
    );
  }
}
