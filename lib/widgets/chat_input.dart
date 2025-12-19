import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final String? editingMessage;
  final VoidCallback? onCancelEdit;

  const ChatInput({
    super.key,
    required this.onSend,
    this.editingMessage,
    this.onCancelEdit,
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
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
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
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Container(
                color: Colors.amber[50],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mengedit pesan',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onCancelEdit?.call();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: isEditing ? 'Edit pesan...' : 'Ketik pesan...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _canSend 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.send,
                        color: _canSend ? Colors.white : Colors.grey[500],
                      ),
                      onPressed: _canSend ? _handleSend : null,
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
