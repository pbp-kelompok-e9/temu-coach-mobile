import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/connectivity_service.dart';
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

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatInputState> _inputKey = GlobalKey();
  
  List<ChatMessage> _messages = [];
  String _receiverName = '';
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // For editing
  int? _editingMessageId;
  String? _editingContent;
  
  // Connectivity
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _receiverName = widget.receiverName ?? '';
    
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    _initChat();
    _initConnectivity();
  }

  void _initConnectivity() {
    final service = ConnectivityService();
    _isOnline = service.isConnected;
    
    _connectivitySubscription = service.connectivityStream.listen((isConnected) {
      if (mounted) {
        final wasOffline = !_isOnline;
        setState(() => _isOnline = isConnected);
        
        if (isConnected && wasOffline) {
          _showSnackBar('Terhubung kembali', Colors.green);
          _loadMessages();
        } else if (!isConnected) {
          _showSnackBar('Tidak ada koneksi internet', Colors.red);
        }
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.green ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: color == Colors.green ? 2 : 5),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - refresh messages
        _loadMessages();
        _startRefreshTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - stop timer
        _refreshTimer?.cancel();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _initChat() {
    final request = context.read<CookieRequest>();
    _chatService = ChatService(request);
    _loadMessages();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isOnline) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!_isOnline && !silent) {
      setState(() {
        _errorMessage = 'Tidak ada koneksi internet';
        _isLoading = false;
      });
      return;
    }

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
          _errorMessage = null;
        });
        
        // Scroll to bottom on first load
        if (!silent) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!silent) _errorMessage = 'Gagal memuat pesan';
        });
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
    if (_isSending || !_isOnline) {
      if (!_isOnline) {
        _showSnackBar('Tidak dapat mengirim - Tidak ada koneksi', Colors.red);
      }
      return;
    }
    
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
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mengedit pesan'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
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
                behavior: SnackBarBehavior.floating,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Pesan'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus pesan'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom app bar like website
          _buildAppBar(),
          
          // Offline banner
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red[700],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Mode Offline - Pesan mungkin tidak terkirim',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // Error banner with retry
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadMessages,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          
          // Messages area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[50]!, Colors.white],
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFDE3400),
                      ),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(),
            ),
          ),
          
          // Chat input
          ChatInput(
            key: _inputKey,
            onSend: _sendMessage,
            editingMessage: _editingContent,
            onCancelEdit: _cancelEdit,
            isEnabled: _isOnline,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003E85), Color(0xFF0052B3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDE3400), Color(0xFFFF6B3D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDE3400).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _receiverName.isNotEmpty ? _receiverName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name only (removed online status)
              Expanded(
                child: Text(
                  _receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isOnline ? _loadMessages : null,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5DD),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: Color(0xFFDE3400),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003E85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai percakapan dengan\nmengirim pesan pertama',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      dateText = DateFormat('d MMMM yyyy', 'id').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
