import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final timeString = DateFormat('HH:mm').format(message.timestamp.toLocal());
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) const SizedBox(width: 40), // Space for avatar if needed
          
          Flexible(
            child: GestureDetector(
              onLongPress: (message.canEdit || message.canDelete) 
                  ? () => _showMessageOptions(context) 
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isMine 
                                ? Colors.white.withOpacity(0.7) 
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead 
                                ? Colors.lightBlueAccent 
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMine) const SizedBox(width: 40), // Space for balance
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.canEdit && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Pesan'),
                subtitle: const Text('Tersedia dalam 5 menit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            if (message.canDelete && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Pesan', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Tersedia dalam 5 menit'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
