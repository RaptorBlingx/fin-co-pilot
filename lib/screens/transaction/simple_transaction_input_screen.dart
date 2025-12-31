import 'package:flutter/material.dart';
import '../../services/ai/transaction_parser_service.dart';
import 'confirm_transaction_screen.dart';

/// Simple transaction input screen demonstrating the new flow
/// Parse → Confirm → Save
class SimpleTransactionInputScreen extends StatefulWidget {
  const SimpleTransactionInputScreen({super.key});

  @override
  State<SimpleTransactionInputScreen> createState() => _SimpleTransactionInputScreenState();
}

class _SimpleTransactionInputScreenState extends State<SimpleTransactionInputScreen> {
  final _controller = TextEditingController();
  final _parser = TransactionParserService();
  bool _isParsing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() => _isParsing = true);

    try {
      // Step 1: Parse natural language input
      final result = await _parser.parseNaturalLanguage(input);

      if (!mounted) return;

      if (result.success) {
        // Step 2: Show confirmation screen
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmTransactionScreen(parseResult: result),
          ),
        );

        if (saved == true && mounted) {
          // Step 3: Success - clear input and show message
          _controller.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Parse failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not parse: ${result.error}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 Tell me about your transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Examples:\n'
                      '• "Coffee from Starbucks 4.50"\n'
                      '• "Spent \$50 on groceries"\n'
                      '• "Got paid \$2000"',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Input field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Describe your transaction',
                hintText: 'e.g., Lunch at McDonald\'s \$12.50',
                border: const OutlineInputBorder(),
                suffixIcon: _isParsing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              enabled: !_isParsing,
              onSubmitted: (_) => _handleSubmit(),
              textInputAction: TextInputAction.done,
            ),
            
            const SizedBox(height: 16),
            
            // Submit button
            ElevatedButton(
              onPressed: _isParsing ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isParsing
                  ? const Text('Parsing...')
                  : const Text('Parse & Continue'),
            ),
            
            const Spacer(),
            
            // Flow diagram
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '📝 New Flow',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Type natural language\n'
                      '2. AI parses instantly\n'
                      '3. Confirm & edit\n'
                      '4. Save to Firestore',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
