import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Stream-based auth state notifier for GoRouter
/// Listens to Firebase Auth changes and notifies router to refresh
class AuthStateNotifier extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  
  AuthStateNotifier(this._authService) {
    _currentUser = _authService.currentUser;
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners(); // Notify router to refresh
    });
  }
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
}
