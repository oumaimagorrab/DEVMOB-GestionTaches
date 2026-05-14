import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_project_page.dart'; 
import 'package:gestiontaches/views/profile/user_profile_page.dart'; 
import 'package:gestiontaches/views/notifications/notifications_page.dart'; // ✅ AJOUTÉ
import 'package:gestiontaches/models/project.dart';

class AdminDashboardPage extends StatefulWidget {

  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  int _activeProjects = 0;
  int _completedTasks = 0;
  int _lateTasks = 0;
  int _activeMembers = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentMembers = [];
  List<Map<String, dynamic>> _recentProjects = []; // ✅ Projets récents avec couleur
  String? _currentUserId;

  String _displayName = "Utilisateur";
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserData();
    _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _isAdmin = userData['role'] == 'admin' || userData['isAdmin'] == true;

          if (_isAdmin) {
            _displayName = "Admin";
          } else {
            _displayName = userData['name'] ?? 
                          userData['displayName'] ?? 
                          currentUser.displayName ?? 
                          "Collaborateur";
          }
        });
      } else {
        setState(() {
          _displayName = currentUser.displayName ?? "Utilisateur";
        });
      }
    } catch (e) {
      print('Erreur chargement user data: $e');
      setState(() {
        _displayName = FirebaseAuth.instance.currentUser?.displayName ?? "Utilisateur";
      });
    }
  }

  // 🔥 CHARGEMENT DES DONNÉES — CORRECTION DATE
  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // ✅ CORRIGÉ : Date d'aujourd'hui à minuit (00:00:00) pour comparer proprement
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));

      print('📅 Aujourd\'hui (minuit): $today');

      // 1. Projets actifs avec couleur et progression
      final projectsSnapshot = await firestore
          .collection('projects')
          .where('status', whereIn: ['active', 'en_cours'])
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final recentProjects = projectsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'description': data['description'] ?? '',
          'color': data['color'] ?? 'FF6B4EFF',
          'progress': (data['progress'] as num?)?.toDouble() ?? 0.0,
          'dueDate': data['dueDate'] != null 
              ? (data['dueDate'] as Timestamp).toDate() 
              : null,
          'members': List<String>.from(data['members'] ?? []),
        };
      }).toList();

      // 2. Tâches terminées cette semaine
      final doneTasksSnapshot = await firestore
          .collection('tasks')
          .where('status', isEqualTo: 'done')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      final completedTasksSnapshot = await firestore
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      // 3. ✅ CORRIGÉ : Tâches en retard — filtre côté client
      final allActiveTasksSnapshot = await firestore
          .collection('tasks')
          .where('status', whereIn: ['todo', 'in_progress', 'pending'])
          .get();

      final lateTasks = allActiveTasksSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
        if (dueDate == null) return false;
        return dueDate.isBefore(today);
      }).toList();

      // 4. Membres actifs
      final membersSnapshot = await firestore.collection('users').get();

      final activeMembers = membersSnapshot.docs.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        final isAdmin = data['isAdmin'] as bool? ?? false;
        return role != 'admin' && !isAdmin;
      }).toList();

      // 5. ✅ Membres récents AVEC photoURL
      final recentMembersSnapshot = await firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final recentMembers = recentMembersSnapshot.docs.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        final isAdmin = data['isAdmin'] as bool? ?? false;
        return role != 'admin' && !isAdmin;
      }).map((doc) => {
        'id': doc.id,
        'name': doc.data()['displayName'] ?? doc.data()['name'] ?? 'Utilisateur',
        'email': doc.data()['email'] ?? '',
        'photoURL': doc.data()['photoURL'] ?? '', // ✅ AJOUTÉ
        'role': doc.data()['role'] ?? 'collaborateur',
      }).toList();

      setState(() {
        _activeProjects = projectsSnapshot.docs.length;
        _completedTasks = doneTasksSnapshot.docs.length + completedTasksSnapshot.docs.length;
        _lateTasks = lateTasks.length;
        _activeMembers = activeMembers.length;
        _recentMembers = recentMembers.take(5).toList();
        _recentProjects = recentProjects; // ✅ Projets avec couleur
        _isLoading = false;
      });

      // Debug
      print('📊 Stats: $_activeProjects projets, $_completedTasks tâches finies, $_lateTasks retard, $_activeMembers membres');
      print('🎨 Projets récents: ${_recentProjects.length}');
      for (var p in _recentProjects) {
        print('   📁 ${p['title']} | couleur: ${p['color']} | progress: ${p['progress']}');
      }

    } catch (e) {
      print('Erreur chargement dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 🖼️ Widget avatar avec photo de profil locale
  Widget _buildAvatar(String? photoURL, {double size = 40}) {
    final bool hasPhoto = photoURL != null && 
                          photoURL.isNotEmpty && 
                          File(photoURL).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.file(
                File(photoURL),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400);
                },
              ),
            )
          : Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400),
    );
  }

  /// 🎨 Parse la couleur du projet
  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return const Color(0xFF6B4EFF);
    try {
      String cleaned = colorString.trim().toUpperCase();
      if (cleaned.startsWith('0X')) cleaned = cleaned.substring(2);
      else if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
      if (cleaned.length == 6) cleaned = 'FF' + cleaned;
      if (cleaned.length != 8) return const Color(0xFF6B4EFF);
      return Color(int.parse(cleaned, radix: 16));
    } catch (e) {
      return const Color(0xFF6B4EFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ HEADER AVEC AVATAR + NOTIFICATION CLIQUABLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🖼️ Avatar de l'utilisateur connecté
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserId)
                        .get(),
                    builder: (context, snapshot) {
                      String? photoURL;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        photoURL = data?['photoURL'] as String?;
                      }
                      return _buildAvatar(photoURL, size: 44);
                    },
                  ),

                  // 🔔 NOTIFICATION CLIQUABLE AVEC BADGE
                  Stack(
                    children: [
                      // ✅ IconButton cliquable
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined, 
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),

                      // 🔥 BADGE ROUGE avec compteur de notifs non lues
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: _currentUserId)
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                          if (count == 0) return const SizedBox.shrink();

                          return Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: count > 9 ? 20 : 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadUserData();
                  await _loadDashboardData();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'Bonjour $_displayName !',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        dateFormat.format(now),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6B4EFF),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // ✅ STATS CARDS
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                  children: [
                                    _buildStatCard(
                                      icon: Icons.folder_outlined,
                                      iconColor: const Color(0xFF6B4EFF),
                                      iconBgColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                                      value: _activeProjects.toString(),
                                      label: 'Projets actifs',
                                      footer: '+2 ce mois',
                                      footerColor: Colors.green,
                                    ),

                                    _buildStatCard(
                                      icon: Icons.check_circle_outline,
                                      iconColor: Colors.green,
                                      iconBgColor: Colors.green.withOpacity(0.1),
                                      value: _completedTasks.toString(),
                                      label: 'Tâches terminées',
                                      footer: 'cette semaine',
                                      footerColor: Colors.grey.shade600,
                                      showProgressBar: true,
                                      progressColor: Colors.green,
                                    ),

                                    _buildStatCard(
                                      icon: Icons.error_outline,
                                      iconColor: Colors.red,
                                      iconBgColor: Colors.red.withOpacity(0.1),
                                      value: _lateTasks.toString(),
                                      label: 'Tâches en retard',
                                      showBadge: _lateTasks > 0,
                                    ),

                                    _buildStatCard(
                                      icon: Icons.people_outline,
                                      iconColor: Colors.orange,
                                      iconBgColor: Colors.orange.withOpacity(0.1),
                                      value: _activeMembers.toString(),
                                      label: 'Membres actifs',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProjectPage()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Accueil', 0),
                _buildNavItem(Icons.folder_outlined, 'Projets', 1),
                const SizedBox(width: 56),
                _buildNavItem(Icons.people_outline, 'Équipe', 2),
                _buildNavItem(Icons.person_outline, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🖼️ Avatars des membres d'un projet (stackés)
  Widget _buildProjectMemberAvatars(List<String> memberIds) {
    if (memberIds.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(
        memberIds.take(3).map((id) => 
          FirebaseFirestore.instance.collection('users').doc(id).get()
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(width: 24, height: 24);

        final photos = snapshot.data!
            .where((doc) => doc.exists)
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data?['photoURL'] as String?;
            })
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();

        return Row(
          children: [
            for (int i = 0; i < photos.length && i < 3; i++)
              Transform.translate(
                offset: Offset(i * -8.0, 0),
                child: _buildAvatar(photos[i], size: 24),
              ),
            if (memberIds.length > 3)
              Transform.translate(
                offset: Offset(photos.length * -8.0, 0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '+${memberIds.length - 3}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
    String? footer,
    Color? footerColor,
    bool showProgressBar = false,
    Color? progressColor,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (showBadge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),

          if (footer != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (footer.contains('+'))
                  const Icon(
                    Icons.trending_up,
                    size: 12,
                    color: Colors.green,
                  ),
                const SizedBox(width: 4),
                Text(
                  footer,
                  style: TextStyle(
                    fontSize: 12,
                    color: footerColor ?? Colors.grey.shade600,
                    fontWeight: footer.contains('+') ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],

          if (showProgressBar) ...[
            const SizedBox(height: 12),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, '/projects');
            break;
          case 2:
            Navigator.pushNamed(context, '/team');
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}