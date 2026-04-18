import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Connexion Email/Mot de passe
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        final userModel = await _getUserFromFirestore(result.user!.uid);
        return userModel ?? _userToUserModel(result.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ✅ CORRIGÉ: Inscription avec role='collaborateur'
  Future<UserModel?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? imageUrl,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) throw Exception('Échec création utilisateur');

      await result.user!.updateDisplayName(name.trim());

      // ✅ CORRIGÉ: role='collaborateur' au lieu de 'user'
      final userModel = UserModel(
        id: result.user!.uid,
        name: name.trim(),
        email: email.trim(),
        photoURL: imageUrl,
        createdAt: DateTime.now(),
        isActive: true,
        role: 'collaborateur',  // ✅ CHANGÉ de 'user' à 'collaborateur'
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoURL': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'role': 'collaborateur',  // ✅ CHANGÉ de 'user' à 'collaborateur'
        'isAdmin': false,         // ✅ AJOUTÉ
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ✅ CORRIGÉ: Connexion Google avec role='collaborateur'
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        if (result.additionalUserInfo?.isNewUser ?? false) {
          // ✅ CORRIGÉ: role='collaborateur'
          final userModel = UserModel(
            id: result.user!.uid,
            name: result.user!.displayName ?? googleUser.displayName ?? '',
            email: result.user!.email ?? googleUser.email,
            photoURL: result.user!.photoURL,
            createdAt: DateTime.now(),
            isActive: true,
            role: 'collaborateur',  // ✅ CHANGÉ
          );

          await _firestore.collection('users').doc(result.user!.uid).set({
            'id': result.user!.uid,
            'name': userModel.name,
            'email': userModel.email,
            'photoURL': userModel.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'role': 'collaborateur',  // ✅ CHANGÉ
            'isAdmin': false,         // ✅ AJOUTÉ
          });

          return userModel;
        } else {
          final userModel = await _getUserFromFirestore(result.user!.uid);
          return userModel ?? _userToUserModel(result.user!);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ✅ CORRIGÉ: Récupération avec role par défaut 'collaborateur'
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.parse(data['createdAt']);
        } else {
          createdAt = DateTime.now();
        }

        return UserModel(
          id: data['id'] ?? data['uid'] ?? uid,
          name: data['name'] ?? data['nomComplet'] ?? '',
          email: data['email'] ?? '',
          photoURL: data['photoURL'] ?? data['avatar'],
          createdAt: createdAt,
          isActive: data['isActive'] ?? true,
          role: data['role'] ?? 'collaborateur',  // ✅ CHANGÉ
        );
      }
      return null;
    } catch (e) {
      print('Erreur récupération user Firestore: $e');
      return null;
    }
  }

  Future<UserModel?> getUserFromFirestore(String uid) async {
    return _getUserFromFirestore(uid);
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour rôle: $e');
    }
  }

  Future<UserModel?> createAdminUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) throw Exception('Échec création utilisateur');

      await result.user!.updateDisplayName(name.trim());

      final userModel = UserModel(
        id: result.user!.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        isActive: true,
        role: 'admin',
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'role': 'admin',
        'isAdmin': true,
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  UserModel _userToUserModel(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      isActive: true,
      role: 'collaborateur',  // ✅ CHANGÉ
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'weak-password':
        return 'Le mot de passe est trop faible (min 6 caractères)';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'operation-not-allowed':
        return 'Inscription par email désactivée dans Firebase Console';
      case 'network-request-failed':
        return 'Problème de connexion internet';
      case 'invalid-credential':
        return 'Identifiants invalides';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return e.message ?? 'Erreur d\'authentification';
    }
  }
}