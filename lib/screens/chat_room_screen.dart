import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

class ChatRoomScreen extends StatefulWidget {
  final int receiverId;
  final String? receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late ChatService _chatService;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatInputState> _inputKey = GlobalKey();
  
  List<ChatMessage> _messages = [];
  String _receiverName = '';
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;
  
  // For editing
  int? _editingMessageId;
  String? _editingContent;

  @override
  void initState() {
    super.initState();
    _receiverName = widget.receiverName ?? '';
    _initChat();
  }

  void _initChat() {
    final request = context.read<CookieRequest>();
    _chatService = ChatService(request);
    _loadMessages();
    
    // Auto-fetch every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final result = await _chatService.getMessages(widget.receiverId);
      if (mounted) {
        setState(() {
          _messages = result['messages'] as List<ChatMessage>;
          _receiverName = result['receiver_name'] ?? _receiverName;
          _isLoading = false;
        });
        
        // Scroll to bottom on first load
        if (!silent) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (_isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      if (_editingMessageId != null) {
        // Edit existing message
        final success = await _chatService.editMessage(_editingMessageId!, content);
        if (success) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == _editingMessageId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(content: content);
            }
            _editingMessageId = null;
            _editingContent = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesan berhasil diedit'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mengedit pesan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Send new message
        final newMessage = await _chatService.sendMessage(widget.receiverId, content);
        if (newMessage != null) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mengirim pesan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startEditMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editingContent = message.content;
    });
    _inputKey.currentState?.setText(message.content);
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editingContent = null;
    });
    _inputKey.currentState?.clearText();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesan'),
        content: const Text('Apakah Anda yakin ingin menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _chatService.deleteMessage(message.id);
      if (success) {
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus pesan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                _receiverName.isNotEmpty ? _receiverName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _receiverName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMessages(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mulai percakapan dengan mengirim pesan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          
                          // Show date separator
                          Widget? dateSeparator;
                          if (index == 0 ||
                              !_isSameDay(
                                _messages[index - 1].timestamp,
                                message.timestamp,
                              )) {
                            dateSeparator = _buildDateSeparator(message.timestamp);
                          }
                          
                          return Column(
                            children: [
                              if (dateSeparator != null) dateSeparator,
                              ChatBubble(
                                message: message,
                                onEdit: message.canEdit
                                    ? () => _startEditMessage(message)
                                    : null,
                                onDelete: message.canDelete
                                    ? () => _deleteMessage(message)
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          ChatInput(
            key: _inputKey,
            onSend: _sendMessage,
            editingMessage: _editingContent,
            onCancelEdit: _cancelEdit,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Hari ini';
    } else if (messageDate == yesterday) {
      dateText = 'Kemarin';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
