import 'package:flutter/material.dart';
import '../../../../services/gemini_orchestrator_service.dart';

class AITestScreen extends StatefulWidget {
  const AITestScreen({super.key});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  final _controller = TextEditingController();
  final _orchestrator = GeminiOrchestratorService();
  String _response = 'Ask me anything!';
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = 'Thinking...';
    });

    try {
      final result = await _orchestrator.processUserInput(_controller.text);
      
      setState(() {
        _response = '''
✅ Success: ${result['success']}
🤖 Agent: ${result['agent'] ?? 'unknown'}
💬 Message: ${result['message'] ?? 'No message'}

📋 Full Response:
${result.toString()}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = '❌ Error: ${e.toString()}';
        _isLoading = false;
      });
    }

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Orchestrator Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Response area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller.text = 'I spent \$50 on groceries at Costco';
                  },
                  child: const Text('Test: Add Transaction'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.text = 'How much did I spend this month?';
                  },
                  child: const Text('Test: Get Insights'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.text = 'Find best price for iPhone 16';
                  },
                  child: const Text('Test: Price Search'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.text = 'What is a budget?';
                  },
                  child: const Text('Test: General Query'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}