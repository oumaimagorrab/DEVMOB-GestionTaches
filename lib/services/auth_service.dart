import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';  // Contient UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream de l'utilisateur courant (pour le provider)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Récupérer l'utilisateur courant
  User? get currentUser => _auth.currentUser;

  // Connexion Email/Mot de passe
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user != null) {
        // Récupérer les données Firestore
        final userModel = await _getUserFromFirestore(result.user!.uid);
        return userModel ?? _userToUserModel(result.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Inscription Email/Mot de passe
  Future<UserModel?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? imageUrl,
  }) async {
    try {
      // 1. Créer l'utilisateur Firebase
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) throw Exception('Échec création utilisateur');

      // 2. Mettre à jour le profil
      await result.user!.updateDisplayName(name.trim());

      // 3. Créer le UserModel
      final userModel = UserModel(
        id: result.user!.uid,
        name: name.trim(),
        email: email.trim(),
        photoURL: imageUrl,
        createdAt: DateTime.now(),
        isActive: true,
        role: 'user',  // Rôle par défaut
      );

      // 4. Sauvegarder dans Firestore avec serverTimestamp
      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoURL': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),  // Timestamp Firestore
        'isActive': true,
        'role': 'user',  // Rôle par défaut
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Connexion Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Déclencher le flux Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Annulé par l'utilisateur

      // Obtenir les credentials
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Vérifier si nouvel utilisateur
        if (result.additionalUserInfo?.isNewUser ?? false) {
          // Créer le profil dans Firestore
          final userModel = UserModel(
            id: result.user!.uid,
            name: result.user!.displayName ?? googleUser.displayName ?? '',
            email: result.user!.email ?? googleUser.email,
            photoURL: result.user!.photoURL,
            createdAt: DateTime.now(),
            isActive: true,
            role: 'user',  // Rôle par défaut
          );
          
          await _firestore.collection('users').doc(result.user!.uid).set({
            'id': result.user!.uid,
            'name': userModel.name,
            'email': userModel.email,
            'photoURL': userModel.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'role': 'user',  // Rôle par défaut
          });
          
          return userModel;
        } else {
          // Utilisateur existant
          final userModel = await _getUserFromFirestore(result.user!.uid);
          return userModel ?? _userToUserModel(result.user!);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Récupérer UserModel depuis Firestore
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Gérer le timestamp Firestore
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
          role: data['role'] ?? 'user',  // Valeur par défaut si non définie
        );
      }
      return null;
    } catch (e) {
      print('Erreur récupération user Firestore: $e');
      return null;
    }
  }
  // Dans class AuthService, ajoutez :

// ✅ NOUVEAU : Récupérer un utilisateur par ID (rendre publique la méthode existante)
Future<UserModel?> getUserFromFirestore(String uid) async {
  return _getUserFromFirestore(uid); // Appelle votre méthode privée existante
}

// ✅ NOUVEAU : Mettre à jour le rôle d'un utilisateur
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

// ✅ NOUVEAU : Créer un utilisateur admin (pour setup initial)
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
      role: 'admin', // ✅ Rôle admin
    );

    await _firestore.collection('users').doc(result.user!.uid).set({
      'id': result.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'role': 'admin', // ✅ Rôle admin
    });

    return userModel;
  } on FirebaseAuthException catch (e) {
    throw _handleAuthException(e);
  }
}

  // Convertir Firebase User en UserModel
  UserModel _userToUserModel(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      isActive: true,
      role: 'user',  // Rôle par défaut
    );
  }

  // Gestion centralisée des erreurs
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