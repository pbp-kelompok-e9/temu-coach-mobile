import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/app_drawer.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late ChatService _chatService;
  
  List<Conversation> _conversations = [];
  List<ChatContact> _contacts = [];
  bool _isLoadingConversations = true;
  bool _isLoadingContacts = true;
  String? _errorMessage;
  String _searchQuery = '';
  Timer? _refreshTimer;
  
  // Connectivity
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Register lifecycle observer for app switch handling
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
          // Reconnected - refresh data
          _showSnackBar('Terhubung kembali', Colors.green);
          _loadData();
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
        // App came back to foreground - refresh data
        _loadData();
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
    _loadData();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isOnline) {
        _loadConversations(silent: true);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _errorMessage = null);
    await Future.wait([
      _loadConversations(),
      _loadContacts(),
    ]);
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!_isOnline && !silent) {
      setState(() {
        _errorMessage = 'Tidak ada koneksi internet';
        _isLoadingConversations = false;
      });
      return;
    }

    if (!silent && mounted) {
      setState(() => _isLoadingConversations = true);
    }
    
    try {
      final conversations = await _chatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoadingConversations = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConversations = false;
          if (!silent) _errorMessage = 'Gagal memuat percakapan';
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    if (!_isOnline) {
      setState(() => _isLoadingContacts = false);
      return;
    }

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
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E85),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_whistle.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sports_soccer,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF003E85),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFDE3400),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Percakapan'),
                Tab(text: 'Kontak'),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
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
                    'Mode Offline - Data mungkin tidak terbaru',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // Header section like website
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Percakapan Anda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003E85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih untuk melanjutkan chat.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama pengguna...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF003E85)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB0B0B0), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB0B0B0), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDE3400), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          
          // Tab content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB0B0B0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConversationsTab(),
                    _buildContactsTab(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsTab() {
    if (_isLoadingConversations) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDE3400),
        ),
      );
    }
    
    final conversations = _filteredConversations;
    
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5DD),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Color(0xFFDE3400),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada percakapan yang cocok'
                  : 'Belum ada percakapan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003E85),
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mulai chat dari tab Kontak',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: const Color(0xFFDE3400),
      child: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
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
    
    return InkWell(
      onTap: () => _openChatRoom(
        conversation.partnerId,
        conversation.partnerName,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: conversation.unreadCount > 0 
            ? const Color(0xFFFFF5F2) 
            : Colors.white,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: conversation.partnerType.toLowerCase() == 'coach'
                          ? [const Color(0xFFDE3400), const Color(0xFFFF6B3D)]
                          : [const Color(0xFF003E85), const Color(0xFF0066CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (conversation.partnerType.toLowerCase() == 'coach'
                                ? const Color(0xFFDE3400)
                                : const Color(0xFF003E85))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      conversation.partnerName.isNotEmpty
                          ? conversation.partnerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
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
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.partnerName,
                          style: TextStyle(
                            fontWeight: conversation.unreadCount > 0 
                                ? FontWeight.bold 
                                : FontWeight.w600,
                            fontSize: 16,
                            color: const Color(0xFF003E85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0 
                              ? const Color(0xFFDE3400) 
                              : Colors.grey[500],
                          fontWeight: conversation.unreadCount > 0 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
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
                                : Colors.grey[600],
                            fontWeight: conversation.unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsTab() {
    if (_isLoadingContacts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDE3400),
        ),
      );
    }
    
    final contacts = _filteredContacts;
    
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FF),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 48,
                color: Color(0xFF003E85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada kontak yang cocok'
                  : 'Belum ada kontak',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003E85),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: const Color(0xFFDE3400),
      child: ListView.separated(
        itemCount: contacts.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactTile(contact);
        },
      ),
    );
  }

  Widget _buildContactTile(ChatContact contact) {
    return InkWell(
      onTap: () => _openChatRoom(contact.id, contact.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: contact.userType.toLowerCase() == 'coach'
                      ? [const Color(0xFFDE3400), const Color(0xFFFF6B3D)]
                      : [const Color(0xFF003E85), const Color(0xFF0066CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF003E85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildUserTypeChip(contact.userType),
                      const SizedBox(width: 8),
                      Text(
                        '@${contact.username}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow (match Percakapan list)
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    String label;
    Color bgColor;
    Color textColor;
    
    switch (userType.toLowerCase()) {
      case 'coach':
        label = 'Coach';
        bgColor = const Color(0xFFFFE5DD);
        textColor = const Color(0xFFDE3400);
        break;
      case 'customer':
        label = 'Customer';
        bgColor = const Color(0xFFE8F4FF);
        textColor = const Color(0xFF003E85);
        break;
      default:
        label = userType;
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
      final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[time.weekday - 1];
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}
