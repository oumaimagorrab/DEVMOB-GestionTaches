// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';  // UserModel
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;  // ✅ Changé de Member à UserModel
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;  // ✅ Renommé de member à user
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isLoggedIn => _authService.currentUser != null;

  // Stream d'authentification
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Connexion Email
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result != null) {
        _user = result;  // ✅ UserModel
        _setLoading(false);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Inscription
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        imageUrl: imageUrl,
      );
      if (result != null) {
        _user = result;  // ✅ UserModel
        _setLoading(false);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Connexion Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = result;  // ✅ UserModel
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Réinitialisation mot de passe
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Charger le profil utilisateur courant
  Future<void> loadCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = UserModel(  // ✅ UserModel
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        isActive: true,
      );
      notifyListeners();
    }
  }

  // Helpers privés
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}