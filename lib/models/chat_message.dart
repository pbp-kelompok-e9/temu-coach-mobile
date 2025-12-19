class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isMine;
  final bool canEdit;
  final bool canDelete;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.isMine,
    required this.canEdit,
    required this.canDelete,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      isMine: json['is_mine'] ?? false,
      canEdit: json['can_edit'] ?? false,
      canDelete: json['can_delete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_mine': isMine,
      'can_edit': canEdit,
      'can_delete': canDelete,
    };
  }

  ChatMessage copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    bool? isMine,
    bool? canEdit,
    bool? canDelete,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isMine: isMine ?? this.isMine,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

class Conversation {
  final int partnerId;
  final String partnerName;
  final String partnerUsername;
  final String partnerType;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.partnerId,
    required this.partnerName,
    required this.partnerUsername,
    required this.partnerType,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partnerId: json['partner_id'],
      partnerName: json['partner_name'],
      partnerUsername: json['partner_username'],
      partnerType: json['partner_type'] ?? 'unknown',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatContact {
  final int id;
  final String name;
  final String username;
  final String userType;

  ChatContact({
    required this.id,
    required this.name,
    required this.username,
    required this.userType,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      userType: json['user_type'] ?? 'unknown',
    );
  }
}
