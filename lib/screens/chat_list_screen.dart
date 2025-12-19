import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/app_drawer.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  
  List<Conversation> _conversations = [];
  List<ChatContact> _contacts = [];
  bool _isLoadingConversations = true;
  bool _isLoadingContacts = true;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initChat();
  }

  void _initChat() {
    final request = context.read<CookieRequest>();
    _chatService = ChatService(request);
    _loadData();
    
    // Auto-refresh conversations every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadConversations(silent: true);
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadConversations(),
      _loadContacts(),
    ]);
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingConversations = true);
    }
    
    try {
      final conversations = await _chatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoadingConversations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingConversations = false);
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    
    try {
      final contacts = await _chatService.getContacts();
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingContacts = false);
      }
    }
  }

  void _openChatRoom(int partnerId, String partnerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          receiverId: partnerId,
          receiverName: partnerName,
        ),
      ),
    ).then((_) {
      // Refresh conversations when returning
      _loadConversations();
    });
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) {
      return c.partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.partnerUsername.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ChatContact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Percakapan'),
            Tab(text: 'Kontak'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Conversations tab
                _buildConversationsTab(),
                
                // Contacts tab
                _buildContactsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsTab() {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final conversations = _filteredConversations;
    
    if (conversations.isEmpty) {
      return Center(
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
              _searchQuery.isNotEmpty
                  ? 'Tidak ada percakapan yang cocok'
                  : 'Belum ada percakapan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mulai chat dari tab Kontak',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final timeString = conversation.lastMessageTime != null
        ? _formatMessageTime(conversation.lastMessageTime!)
        : '';
    
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: _getAvatarColor(conversation.partnerType),
            child: Text(
              conversation.partnerName.isNotEmpty
                  ? conversation.partnerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  conversation.unreadCount > 9 
                      ? '9+' 
                      : conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.partnerName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          _buildUserTypeChip(conversation.partnerType),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0 
                    ? Colors.black87 
                    : Colors.grey,
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      onTap: () => _openChatRoom(
        conversation.partnerId,
        conversation.partnerName,
      ),
    );
  }

  Widget _buildContactsTab() {
    if (_isLoadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final contacts = _filteredContacts;
    
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada kontak yang cocok'
                  : 'Belum ada kontak',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactTile(contact);
        },
      ),
    );
  }

  Widget _buildContactTile(ChatContact contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getAvatarColor(contact.userType),
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(contact.name),
      subtitle: Row(
        children: [
          _buildUserTypeChip(contact.userType),
          const SizedBox(width: 8),
          Text(
            '@${contact.username}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.chat,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => _openChatRoom(contact.id, contact.name),
      ),
      onTap: () => _openChatRoom(contact.id, contact.name),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    String label;
    Color color;
    
    switch (userType.toLowerCase()) {
      case 'coach':
        label = 'Coach';
        color = Colors.blue;
        break;
      case 'customer':
        label = 'Customer';
        color = Colors.green;
        break;
      default:
        label = userType;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getAvatarColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'coach':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Kemarin';
    } else if (now.difference(time).inDays < 7) {
      // Within a week, show day name
      final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[time.weekday - 1];
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}
