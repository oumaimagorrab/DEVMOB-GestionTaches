// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters existants
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isLoggedIn => _authService.currentUser != null;

  // ✅ NOUVEAUX : Getters pour les rôles
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCollaborator => _user?.isRegularUser ?? false; // ou isUser

  // Stream d'authentification
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Connexion Email - ✅ MODIFIÉ : Récupère le rôle depuis Firestore
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result != null) {
        _user = result;
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

  // Inscription - ✅ MODIFIÉ : Garde le rôle 'user' par défaut
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
        _user = result; // Rôle 'user' par défaut depuis AuthService
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

  // Connexion Google - ✅ DÉJÀ GÉRÉ (rôle récupéré depuis Firestore si existant)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = result;
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

  // ✅ MODIFIÉ : Charger l'utilisateur depuis Firestore (pas juste Firebase Auth)
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        // Récupérer les données complètes depuis Firestore pour avoir le rôle
        final userModel = await _authService.getUserFromFirestore(firebaseUser.uid);
        _user = userModel ?? UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          isActive: true,
          role: 'user',
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ✅ NOUVEAU : Mettre à jour le rôle (pour l'admin)
  Future<void> updateUserRole(String newRole) async {
    if (_user == null) return;
    
    try {
      await _authService.updateUserRole(_user!.id, newRole);
      _user = _user!.copyWith(role: newRole);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ✅ NOUVEAU : Vérifier l'accès à une fonctionnalité admin
  bool canAccessAdminFeature() => isAdmin;

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