import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MessageInputBar extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onCameraPressed;
  final VoidCallback onVoicePressed;
  final bool enabled;

  const MessageInputBar({
    super.key,
    required this.onSendMessage,
    required this.onCameraPressed,
    required this.onVoicePressed,
    this.enabled = true,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSendMessage(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Camera button
          _buildIconButton(
            icon: Icons.camera_alt_outlined,
            onPressed: widget.enabled ? widget.onCameraPressed : null,
            tooltip: 'Take photo',
          ),
          
          const SizedBox(width: 8),
          
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.slate50
                    : AppTheme.slate800,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.primaryIndigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              maxLines: null,
              keyboardType: TextInputType.text,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Voice or Send button
          if (_hasText)
            _buildSendButton()
          else
            _buildIconButton(
              icon: Icons.mic_outlined,
              onPressed: widget.enabled ? widget.onVoicePressed : null,
              tooltip: 'Voice input',
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      color: AppTheme.primaryIndigo,
      iconSize: 24,
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward_rounded),
        onPressed: widget.enabled ? _handleSend : null,
        tooltip: 'Send',
        color: Colors.white,
        iconSize: 24,
      ),
    );
  }
}