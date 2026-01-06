import 'package:flutter/material.dart';
import 'package:rana_merchant/config/api_config.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // [NEW]
import 'package:lottie/lottie.dart';
import 'package:rana_merchant/config/assets_config.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:rana_merchant/services/support_read_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  IO.Socket? socket; // [NEW]
  String? typingUser; // [NEW]
  final ScrollController _chatScrollController = ScrollController();
  bool _connected = false;
  final List<String> _emojis = [
    '😀','😁','😂','🤣','😊','😍','😘','😎','😇','😉',
    '🙌','👍','👏','🙏','💪','🔥','✨','🎉','✅','❌',
    '😢','😭','😤','😡','😱','🤔','🤨','😴','😅','🤝'
  ];
  final List<String> _quickReplies = [
    'Terima kasih',
    'Mohon detail kendala',
    'Sudah dicoba, masih error',
    'Kapan estimasi selesai?',
  ];
  bool _canSend = false;
  bool _isUploading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_chatScrollController.hasClients) {
        final max = _chatScrollController.position.maxScrollExtent;
        try {
          await _chatScrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } catch (_) {
          try {
            _chatScrollController.jumpTo(max);
          } catch (_) {}
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    _connectSocket(); // [NEW]
  }

  void _connectSocket() {
    socket = IO.io(
        ApiConfig.serverUrl,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).setAuth({
          'token': ApiService().token
        }) // Access token from ApiService (Need getter)
            .build());

    socket!.onConnect((_) {
      print('Connected to Socket');
      _connected = true;
      if (widget.ticketId.isNotEmpty) {
        socket!.emit('join_ticket', widget.ticketId);
      }
      _scrollToBottom();
    });
    socket!.onReconnect((_) {
      _connected = true;
      if (widget.ticketId.isNotEmpty) {
        socket!.emit('join_ticket', widget.ticketId);
      }
    });
    socket!.onConnectError((e) {
      _connected = false;
      print('Socket connect error: $e');
    });
    socket!.onError((e) {
      _connected = false;
      print('Socket error: $e');
    });

    socket!.on('new_message', (data) {
      if (mounted) {
        setState(() {
          if (ticket != null) {
            List msgs = ticket!['messages'];
            msgs.add(data);
            ticket!['messages'] = msgs;
          }
        });
        SupportReadService().markOpened(widget.ticketId);
        SoundService.playBeep();
        _scrollToBottom();
      }
    });

    socket!.on('typing', (data) {
      // data = { userId, role, isTyping }
      if (data['role'] == 'MERCHANT') return; // Ignore self
      if (mounted) {
        setState(() {
          typingUser = data['isTyping'] ? "Admin is typing..." : null;
        });
      }
    });
  }

  @override
  void dispose() {
    socket?.disconnect(); // [NEW]
    _connected = false;
    _msgController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getTicketDetail(widget.ticketId);
      setState(() {
        ticket = data;
        isLoading = false;
      });
      await SupportReadService().markOpened(widget.ticketId);
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _reply() async {
    if (_msgController.text.trim().isEmpty) return;
    final msg = _msgController.text;
    _msgController.clear();

    if (socket != null && socket!.connected) {
      try {
        socket!.emit('send_message',
            {'ticketId': widget.ticketId, 'message': msg.trim()});
        if (mounted) {
          setState(() {
            final now = DateTime.now().toIso8601String();
            final local = {
              'message': msg.trim(),
              'createdAt': now,
              'senderType': 'MERCHANT',
              'isAdmin': false
            };
            final msgs = List.from(ticket?['messages'] ?? []);
            msgs.add(local);
            ticket = {
              ...?ticket,
              'messages': msgs,
            };
          });
        }
        _scrollToBottom();
        return;
      } catch (_) {}
    }

    try {
      await ApiService().replyTicket(widget.ticketId, msg);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to send')));
      }
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        builder: (_) {
          return SizedBox(
            height: 260,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final e = _emojis[index];
                return InkWell(
                  onTap: () {
                    final text = _msgController.text;
                    _msgController.text = '$text$e';
                    _msgController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _msgController.text.length));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          );
        });
  }

  Future<void> _attachImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() => _isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mengunggah lampiran...'),
          duration: Duration(milliseconds: 800)));
      final bytes = await file.readAsBytes();
      final url =
          await ApiService()
          .uploadTransferProof(file.path, fileBytes: bytes, fileName: file.name);
      final resolved = ApiService().resolveFileUrl(url);
      if (resolved.isEmpty) {
        throw Exception('URL kosong dari server');
      } else {
        _msgController.text = resolved;
        _canSend = true;
        await _reply();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
                      controller: _chatScrollController,
                      itemCount: ticket?['messages']?.length ?? 0,
                      itemBuilder: (context, index) {
                        final msg = ticket!['messages'][index];
                        final isMe = msg['senderType'] == 'MERCHANT' ||
                            msg['isAdmin'] == false;
                        DateTime? dt;
                        String? created = msg['createdAt']?.toString();
                        if (created != null) {
                          dt = DateTime.tryParse(created);
                        }
                        final prev = index > 0 ? ticket!['messages'][index - 1] : null;
                        DateTime? prevDt;
                        if (prev != null && prev['createdAt'] != null) {
                          prevDt = DateTime.tryParse(prev['createdAt'].toString());
                        }
                        final showHeader = dt != null &&
                            (prevDt == null ||
                                dt!.year != prevDt!.year ||
                                dt!.month != prevDt!.month ||
                                dt!.day != prevDt!.day);
                        final headerText = dt != null
                            ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dt!)
                            : null;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (showHeader && headerText != null)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text(headerText,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white)),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: CircleAvatar(
                                        radius: 12,
                                        child: Icon(Icons.support_agent, size: 14),
                                      ),
                                    ),
                                  Flexible(
                                    child: GestureDetector(
                                      onLongPress: () {
                                        final txt = (msg['message'] ?? '').toString();
                                        if (txt.isEmpty) return;
                                        Clipboard.setData(ClipboardData(text: txt));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text('Teks disalin')));
                                      },
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(context).size.width * 0.78,
                                        ),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.symmetric(vertical: 4),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Colors.indigo
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildMessageContent(msg, isMe),
                                              const SizedBox(height: 4),
                                              Text(
                                                dt != null
                                                    ? '${dt!.hour.toString().padLeft(2, '0')}:${dt!.minute.toString().padLeft(2, '0')}'
                                                    : '',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMe
                                                        ? Colors.indigo[100]
                                                        : Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (typingUser != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Lottie.asset(AssetsConfig.lottieLivePulse, repeat: true),
                          ),
                          const SizedBox(width: 6),
                          Text(typingUser!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                          hintText: 'Type reply...',
                          border: OutlineInputBorder()),
                      onChanged: (val) {
                        setState(() {
                          _canSend = val.trim().isNotEmpty;
                        });
                        socket?.emit('typing', {
                          'ticketId': widget.ticketId,
                          'isTyping': val.isNotEmpty
                        });
                      },
                    )),
                    IconButton(
                        onPressed: _showEmojiPicker,
                        icon:
                            const Icon(Icons.emoji_emotions_outlined, color: Colors.indigo)),
                    IconButton(
                        onPressed: _isUploading ? null : _attachImage,
                        icon: Icon(Icons.attach_file,
                            color: _isUploading ? Colors.grey[400] : Colors.indigo)),
                    IconButton(
                        onPressed: _canSend ? _reply : null,
                        icon: Icon(Icons.send,
                            color:
                                _canSend ? Colors.indigo : Colors.grey[400]))
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _quickReplies.length,
                    itemBuilder: (context, index) {
                      final text = _quickReplies[index];
                      return ActionChip(
                        label: Text(text, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _msgController.text =
                              (_msgController.text.isEmpty ? text : '${_msgController.text} $text');
                          _msgController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _msgController.text.length));
                          setState(() {
                            _canSend = _msgController.text.trim().isNotEmpty;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map msg, bool isMe) {
    final text = (msg['message'] ?? '').toString();
    final isImage = _looksLikeImageUrl(text);
    if (!isImage) {
      return Text(
        text,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
      );
    }
    final displayUrl = _ensureAbsoluteUrl(text);
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(displayUrl, fit: BoxFit.contain),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          displayUrl,
          width: 220,
          height: 180,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  bool _looksLikeImageUrl(String s) {
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    final hasProto = lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('/');
    final hasExt = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
    return hasProto && hasExt;
  }

  String _ensureAbsoluteUrl(String s) {
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return ApiService().resolveFileUrl(s);
  }
}
