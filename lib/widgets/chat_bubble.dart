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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Action buttons for my messages (left side)
          if (isMine && (message.canEdit || message.canDelete)) ...[
            _buildActionButtons(context),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: (message.canEdit || message.canDelete) 
                  ? () => _showMessageOptions(context) 
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: isMine 
                      ? const LinearGradient(
                          colors: [Color(0xFFDE3400), Color(0xFFFF6B3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMine ? null : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMine 
                          ? const Color(0xFFDE3400).withOpacity(0.25)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isMine 
                      ? null 
                      : Border.all(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Message content
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMine ? Colors.white : const Color(0xFF1F2937),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Time and read status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isMine 
                                ? Colors.white.withOpacity(0.8) 
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: isMine 
                                  ? Colors.white.withOpacity(0.8) 
                                  : Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead 
                                  ? Colors.lightBlueAccent 
                                  : Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.canEdit && onEdit != null)
          _ActionButton(
            icon: Icons.edit,
            onTap: onEdit!,
            tooltip: 'Edit',
          ),
        if (message.canDelete && onDelete != null)
          _ActionButton(
            icon: Icons.delete,
            onTap: onDelete!,
            tooltip: 'Hapus',
            isDelete: true,
          ),
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5DD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.message,
                        color: Color(0xFFDE3400),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Opsi Pesan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003E85),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Edit option
              if (message.canEdit && onEdit != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF003E85),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Edit Pesan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Tersedia dalam 5 menit setelah dikirim',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),
              
              // Delete option
              if (message.canDelete && onDelete != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Hapus Pesan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                  subtitle: const Text(
                    'Tersedia dalam 5 menit setelah dikirim',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDelete;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: isDelete ? Colors.red[50] : const Color(0xFFFFE5DD),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 16,
                color: isDelete ? Colors.red[600] : const Color(0xFFDE3400),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
