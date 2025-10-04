import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class TestFirestoreScreen extends StatefulWidget {
  const TestFirestoreScreen({super.key});

  @override
  State<TestFirestoreScreen> createState() => _TestFirestoreScreenState();
}

class _TestFirestoreScreenState extends State<TestFirestoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Press button to test Firestore';
  bool _isLoading = false;

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firestore...';
    });

    try {
      // Add timeout and better error handling
      print('Starting Firestore test...');
      
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }
      
      print('Firebase apps: ${Firebase.apps.length}');
      
      // Test with timeout
      final docRef = await _firestore.collection('test').add({
        'message': 'Hello from Fin Co-Pilot!',
        'timestamp': FieldValue.serverTimestamp(),
        'device': 'flutter',
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore write timeout after 10 seconds'),
      );

      print('Document created with ID: ${docRef.id}');

      // Read it back
      final docSnapshot = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore read timeout after 10 seconds'),
      );
      
      final data = docSnapshot.data();
      print('Document data: $data');

      setState(() {
        _status = '✅ SUCCESS!\n\n'
            'Write: Document created with ID ${docRef.id}\n'
            'Read: ${data?['message']}\n'
            'Firestore is working!';
        _isLoading = false;
      });

      // Clean up (optional)
      await docRef.delete();
      print('Test document deleted');
      
    } catch (e) {
      print('Firestore test error: $e');
      setState(() {
        _status = '❌ ERROR: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Fin Co-Pilot',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Testing Firestore connection...'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _testFirestore,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Test Firestore Write/Read'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}