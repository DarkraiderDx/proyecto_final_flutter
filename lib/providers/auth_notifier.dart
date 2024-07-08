import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLogin = true;
  User? _user;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isLogin => _isLogin;
  bool get isAuthenticated => _user != null;
  User? get user => _user;

  void toggleLogin() {
    _isLogin = !_isLogin;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await _authService.signUp(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Stream<User?> get authStateChanges => _authService.authStateChanges;
}
