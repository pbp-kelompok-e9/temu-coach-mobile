import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final String? editingMessage;
  final VoidCallback? onCancelEdit;
  final bool isEnabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.editingMessage,
    this.onCancelEdit,
    this.isEnabled = true,
  });

  @override
  State<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    if (widget.editingMessage != null) {
      _controller.text = widget.editingMessage!;
    }
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null && 
        widget.editingMessage != oldWidget.editingMessage) {
      _controller.text = widget.editingMessage!;
      _focusNode.requestFocus();
    }
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty && widget.isEnabled;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  void clearText() {
    _controller.clear();
  }

  void setText(String text) {
    _controller.text = text;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingMessage != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB0B0B0), width: 2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Editing indicator
            if (isEditing)
              Container(
                color: const Color(0xFFFFF8E1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengedit pesan',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Tekan ✓ untuk menyimpan perubahan',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          _controller.clear();
                          widget.onCancelEdit?.call();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Offline indicator
            if (!widget.isEnabled)
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Tidak dapat mengirim - Offline',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            // Input area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: widget.isEnabled 
                            ? Colors.grey[50] 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFB0B0B0),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.isEnabled,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: widget.isEnabled ? Colors.black87 : Colors.grey,
                        ),
                        decoration: InputDecoration(
                          hintText: isEditing 
                              ? 'Edit pesan Anda...' 
                              : 'Ketik pesan Anda...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      gradient: _canSend
                          ? const LinearGradient(
                              colors: [Color(0xFFDE3400), Color(0xFFFF6B3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _canSend ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB0B0B0),
                        width: 2,
                      ),
                      boxShadow: _canSend
                          ? [
                              BoxShadow(
                                color: const Color(0xFFDE3400).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _canSend ? _handleSend : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEditing ? Icons.check : Icons.send,
                                color: _canSend ? Colors.white : Colors.grey[500],
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isEditing ? 'Simpan' : 'Kirim',
                                style: TextStyle(
                                  color: _canSend ? Colors.white : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
