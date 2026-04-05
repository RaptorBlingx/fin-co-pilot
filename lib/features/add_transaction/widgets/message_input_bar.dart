import 'dart:ui';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/haptic_utils.dart';

/// Type of pending attachment in the input bar.
enum AttachmentType { file, image }

/// Data for a pending attachment awaiting user send.
class PendingAttachment {
  final AttachmentType type;
  final String fileName;
  final int sizeBytes;
  final Uint8List? thumbnailBytes; // for images
  final PlatformFile? platformFile; // for file attachments
  final Uint8List? imageBytes; // for camera/gallery images
  final String? imagePath; // for camera/gallery images

  const PendingAttachment({
    required this.type,
    required this.fileName,
    required this.sizeBytes,
    this.thumbnailBytes,
    this.platformFile,
    this.imageBytes,
    this.imagePath,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class MessageInputBar extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String message, PendingAttachment attachment)? onSendWithAttachment;
  final VoidCallback onCameraPressed;
  final VoidCallback? onAttachPressed;
  final bool enabled;
  final String? hintText;

  const MessageInputBar({
    super.key,
    required this.onSendMessage,
    this.onSendWithAttachment,
    required this.onCameraPressed,
    this.onAttachPressed,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<MessageInputBar> createState() => MessageInputBarState();
}

class MessageInputBarState extends State<MessageInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  // Voice recording state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isRecording = false;
  String _partialTranscription = '';
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _cancelledBySwipe = false;
  double _swipeOffset = 0;
  static const _cancelSwipeThreshold = -80.0;

  // Pending attachment state
  PendingAttachment? _pendingAttachment;

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (_isRecording) _stopRecording();
        },
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _recordingTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }

  /// Set a pending attachment from the parent widget (e.g. after picking a file or taking a photo).
  void setPendingAttachment(PendingAttachment attachment) {
    setState(() {
      _pendingAttachment = attachment;
      _hasText = true; // enable send even without text
    });
    _focusNode.requestFocus();
  }

  /// Clear the pending attachment.
  void clearPendingAttachment() {
    setState(() {
      _pendingAttachment = null;
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (!widget.enabled) return;

    if (_pendingAttachment != null) {
      HapticUtils.light();
      widget.onSendWithAttachment?.call(text, _pendingAttachment!);
      _controller.clear();
      setState(() {
        _pendingAttachment = null;
        _hasText = false;
      });
      _focusNode.requestFocus();
      return;
    }

    if (text.isNotEmpty) {
      HapticUtils.light();
      widget.onSendMessage(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  bool get _canSend =>
      _hasText || _pendingAttachment != null;

  // ── Voice push-to-talk ──

  void _startRecording() async {
    if (!_speechInitialized) {
      await _initSpeech();
      if (!_speechInitialized) return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _partialTranscription = '';
      _recordingSeconds = 0;
      _cancelledBySwipe = false;
      _swipeOffset = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 60) _stopRecording();
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted || _cancelledBySwipe) return;
          setState(() {
            _partialTranscription = result.recognizedWords;
          });
          if (result.finalResult) {
            _finishRecording(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _stopRecording();
    }
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _speech.stop();

    if (_cancelledBySwipe) {
      HapticFeedback.lightImpact();
      setState(() {
        _isRecording = false;
        _partialTranscription = '';
      });
      return;
    }

    if (_partialTranscription.isNotEmpty) {
      _finishRecording(_partialTranscription);
    } else {
      setState(() => _isRecording = false);
    }
  }

  void _finishRecording(String text) {
    HapticFeedback.lightImpact();
    setState(() {
      _isRecording = false;
      _partialTranscription = '';
    });
    if (text.trim().isNotEmpty) {
      _controller.text = text.trim();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _focusNode.requestFocus();
    }
  }

  String get _recordingDuration {
    final m = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Recording overlay replaces the normal input bar
    if (_isRecording) return _buildRecordingOverlay(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface.withOpacity(
              context.isDark ? 0.8 : 0.9,
            ),
            border: Border(
              top: BorderSide(
                color: context.colors.onSurface.withOpacity(0.06),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            DesignTokens.space12,
            0,
            DesignTokens.space12,
            DesignTokens.space12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Attachment preview (if any)
              if (_pendingAttachment != null) _buildAttachmentPreview(context),

              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space12),
                child: Row(
                  children: [
                    // Text input (left side — full width)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white.withOpacity(0.06)
                              : AppTheme.slate100,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusXL),
                          border: Border.all(
                            color:
                                context.colors.onSurface.withOpacity(0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          decoration: InputDecoration(
                            hintText: _pendingAttachment != null
                                ? 'Add a message (optional)…'
                                : (widget.hintText ?? 'What did you spend today?'),
                            hintStyle: TextStyle(
                              color: context.colors.onSurface.withOpacity(0.4),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space16,
                              vertical: DesignTokens.space12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          maxLines: 4,
                          minLines: 1,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ),

                    const SizedBox(width: DesignTokens.space8),

                    // Right-side action cluster
                    // Camera
                    _ActionIcon(
                      icon: PhosphorIcons.camera(),
                      onPressed:
                          widget.enabled ? widget.onCameraPressed : null,
                      tooltip: 'Scan receipt',
                    ),

                    // Attach
                    if (widget.onAttachPressed != null)
                      Padding(
                        padding: const EdgeInsets.only(left: DesignTokens.space4),
                        child: _ActionIcon(
                          icon: PhosphorIcons.paperclip(),
                          onPressed:
                              widget.enabled ? widget.onAttachPressed : null,
                          tooltip: 'Attach file',
                        ),
                      ),

                    const SizedBox(width: DesignTokens.space4),

                    // Voice or Send button
                    if (_canSend)
                      _SendButton(
                        onPressed: widget.enabled ? _handleSend : null,
                      )
                    else
                      _VoicePushToTalkButton(
                        enabled: widget.enabled,
                        onLongPressStart: _startRecording,
                        onLongPressEnd: _stopRecording,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recording overlay (WhatsApp-style) ──

  Widget _buildRecordingOverlay(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface.withOpacity(
              context.isDark ? 0.85 : 0.95,
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.primaryIndigo.withOpacity(0.2),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            DesignTokens.space16,
            DesignTokens.space16,
            DesignTokens.space16,
            DesignTokens.space16 + MediaQuery.of(context).padding.bottom,
          ),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _swipeOffset += details.delta.dx;
                if (_swipeOffset < _cancelSwipeThreshold) {
                  _cancelledBySwipe = true;
                }
              });
            },
            onHorizontalDragEnd: (_) {
              if (_cancelledBySwipe) _stopRecording();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live transcription preview
                if (_partialTranscription.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                    padding: const EdgeInsets.all(DesignTokens.space12),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white.withOpacity(0.06)
                          : AppTheme.slate100,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    ),
                    child: Text(
                      _partialTranscription,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                Row(
                  children: [
                    // Recording indicator
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cancelledBySwipe
                                ? context.colors.onSurface.withOpacity(0.3)
                                : Color.lerp(
                                    AppTheme.rose500,
                                    AppTheme.rose500.withOpacity(0.4),
                                    _pulseController.value,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: DesignTokens.space8),

                    // Duration
                    Text(
                      _recordingDuration,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: _cancelledBySwipe
                            ? context.colors.onSurface.withOpacity(0.3)
                            : AppTheme.rose500,
                      ),
                    ),

                    const Spacer(),

                    // Slide to cancel hint
                    if (!_cancelledBySwipe) ...[
                      Icon(
                        PhosphorIcons.arrowLeft(),
                        size: 14,
                        color: context.colors.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: DesignTokens.space4),
                      Text(
                        'Slide to cancel',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ] else
                      Text(
                        'Recording cancelled',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.4),
                        ),
                      ),

                    const SizedBox(width: DesignTokens.space16),

                    // Mic icon (release to stop)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _cancelledBySwipe
                            ? null
                            : AppTheme.primaryGradient,
                        color: _cancelledBySwipe
                            ? context.colors.onSurface.withOpacity(0.1)
                            : null,
                      ),
                      child: Icon(
                        PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                        size: DesignTokens.iconSM,
                        color: _cancelledBySwipe
                            ? context.colors.onSurface.withOpacity(0.3)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Attachment preview card ──

  Widget _buildAttachmentPreview(BuildContext context) {
    final attachment = _pendingAttachment!;
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.06)
            : AppTheme.slate100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(
          color: AppTheme.primaryIndigo.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail or icon
          if (attachment.type == AttachmentType.image &&
              attachment.imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              child: Image.memory(
                attachment.imageBytes!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              ),
              child: Icon(
                _fileIcon(attachment.fileName),
                size: 24,
                color: AppTheme.primaryIndigo,
              ),
            ),

          const SizedBox(width: DesignTokens.space12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.formattedSize,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          GestureDetector(
            onTap: () {
              HapticUtils.light();
              clearPendingAttachment();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.onSurface.withOpacity(0.06),
              ),
              child: Icon(
                PhosphorIcons.x(),
                size: 16,
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return PhosphorIcons.filePdf();
      case 'csv':
      case 'xls':
      case 'xlsx':
        return PhosphorIcons.fileXls();
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return PhosphorIcons.fileImage();
      case 'txt':
        return PhosphorIcons.fileText();
      default:
        return PhosphorIcons.file();
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.onSurface.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSM,
            color: onPressed != null
                ? AppTheme.primaryIndigo
                : context.colors.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(
          PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
          size: DesignTokens.iconSM,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Push-to-talk mic button — hold to record, release to stop.
class _VoicePushToTalkButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _VoicePushToTalkButton({
    required this.enabled,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hold to speak',
      child: GestureDetector(
        onLongPressStart: enabled ? (_) => onLongPressStart() : null,
        onLongPressEnd: enabled ? (_) => onLongPressEnd() : null,
        // Also support single tap for discoverability — start recording
        onTap: null, // long press only
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.onSurface.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.microphone(),
            size: DesignTokens.iconSM,
            color: enabled
                ? AppTheme.primaryIndigo
                : context.colors.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}