import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  Future<String?> startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
    VoidCallback? onComplete,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    _isListening = true;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
            onComplete?.call();
          } else {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return null; // Success
    } catch (e) {
      _isListening = false;
      return 'Error: $e';
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      HapticFeedback.lightImpact();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}

/// Voice input bottom sheet
class VoiceInputBottomSheet extends StatefulWidget {
  final Function(String) onComplete;

  const VoiceInputBottomSheet({
    super.key,
    required this.onComplete,
  });

  @override
  State<VoiceInputBottomSheet> createState() => _VoiceInputBottomSheetState();
}

class _VoiceInputBottomSheetState extends State<VoiceInputBottomSheet>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  String _recognizedText = '';
  String _partialText = '';
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startListening();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });

    final error = await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
          _isListening = false;
        });
        
        // Auto-close and return result after brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(text);
          Navigator.pop(context);
        });
      },
      onPartialResult: (text) {
        setState(() {
          _partialText = text;
        });
      },
      onComplete: () {
        setState(() {
          _isListening = false;
        });
      },
    );

    if (error != null) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _stopListening() {
    _voiceService.stopListening();
    if (_recognizedText.isNotEmpty) {
      widget.onComplete(_recognizedText);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: 32 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Animated microphone icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(
                        _isListening ? 0.3 * _animationController.value : 0,
                      ),
                      blurRadius: 40 * _animationController.value,
                      spreadRadius: 10 * _animationController.value,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  size: 60,
                  color: Colors.white,
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Status text
          Text(
            _isListening ? 'Listening...' : 'Processing...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          const SizedBox(height: 8),
          
          // Recognized text
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _partialText.isNotEmpty ? _partialText : _recognizedText.isNotEmpty ? _recognizedText : 'Say something like "Coffee 5 dollars"',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stop button
          OutlinedButton(
            onPressed: _stopListening,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}