import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  // 🔥 MARQUER TOUTES LES NOTIFS COMME LUES
  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;

    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUserId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // 🔥 MARQUER UNE NOTIF COMME LUE
  Future<void> _markAsRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'read': true,
    });
  }

  // 🔥 FORMATER LE TEMPS ÉCOULÉ
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return DateFormat('dd MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Non authentifié')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Tout marquer lu',
              style: TextStyle(
                color: Color(0xFF6B4EFF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4EFF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Séparer par date
          final List<Map<String, dynamic>> todayNotifs = [];
          final List<Map<String, dynamic>> olderNotifs = [];
          final now = DateTime.now();

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
            final notif = {'id': doc.id, ...data, 'createdAt': createdAt};

            if (createdAt.day == now.day &&
                createdAt.month == now.month &&
                createdAt.year == now.year) {
              todayNotifs.add(notif);
            } else {
              olderNotifs.add(notif);
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              if (todayNotifs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Aujourd\'hui',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                ...todayNotifs.map((n) => _buildNotificationCard(n)),
              ],
              if (olderNotifs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Plus tôt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                ...olderNotifs.map((n) => _buildNotificationCard(n)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final bool isRead = notif['read'] ?? false;
    final String type = notif['type'] ?? 'task_assigned';
    final String title = notif['title'] ?? 'Notification';
    final String message = notif['message'] ?? '';
    final DateTime createdAt = notif['createdAt'];

    // Icône selon le type
    IconData iconData;
    Color iconBgColor;
    Color iconColor;

    switch (type) {
      case 'task_assigned':
        iconData = Icons.assignment_outlined;
        iconBgColor = const Color(0xFF6B4EFF).withOpacity(0.1);
        iconColor = const Color(0xFF6B4EFF);
        break;
      case 'deadline':
        iconData = Icons.access_time;
        iconBgColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        break;
      case 'mention':
        iconData = Icons.alternate_email;
        iconBgColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconBgColor = Colors.grey.shade200;
        iconColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(notif['id']);
        // TODO: Navigation vers la tâche/projet concerné
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : const Color(0xFFE0E7FF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isRead ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRead ? Colors.grey.shade500 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Point bleu si non lu
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B4EFF),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}