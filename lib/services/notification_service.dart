import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// ✅ CRÉER une notification
  Future<void> createNotification({
    required String userId,      // Destinataire (admin)
    required String senderId,    // Expéditeur (collaborateur)
    required String senderName,
    required String type,
    required String title,
    required String message,
    String? projectId,
    String? projectName,
    String? taskId,
    String? taskName,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        senderId: senderId,
        senderName: senderName,
        type: type,
        title: title,
        message: message,
        projectId: projectId,
        projectName: projectName,
        taskId: taskId,
        taskName: taskName,
        read: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toJson());
      print('✅ Notification créée: ${notification.title}');
    } catch (e) {
      print('❌ Erreur création notification: $e');
      throw Exception('Erreur création notification: $e');
    }
  }

  /// 🔔 Récupérer les notifications d'un utilisateur
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  /// 📊 Compter les notifications non lues
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ✅ Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
      throw Exception('Erreur markAsRead: $e');
    }
  }

  /// ✅ Marquer TOUTES les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
      throw Exception('Erreur markAllAsRead: $e');
    }
  }

  /// 🗑️ Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
      throw Exception('Erreur suppression notification: $e');
    }
  }

  /// 🔍 Trouver l'admin du système
  Future<String?> getAdminId() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('❌ Erreur recherche admin: $e');
      return null;
    }
  }
}