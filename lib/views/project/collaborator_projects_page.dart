import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project.dart';
import 'package:gestiontaches/views/profile/user_profile_page.dart';
import 'package:gestiontaches/views/project/project_detail_page2.dart';
import 'package:gestiontaches/views/notifications/notifications_page.dart';
import 'package:gestiontaches/services/task_service.dart';

class CollaboratorProjectsPage extends StatefulWidget {
  const CollaboratorProjectsPage({super.key});

  @override
  State<CollaboratorProjectsPage> createState() => _CollaboratorProjectsPageState();
}

class _CollaboratorProjectsPageState extends State<CollaboratorProjectsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;

  // Cache des photos de profil : Map<userId, photoURL>
  final Map<String, String?> _membersPhotos = {};
  // Cache de progression par projectId : valeur entre 0.0 et 1.0
  final Map<String, double> _projectProgress = {};

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppAuthProvider>().user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Utilisateur non authentifié'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mes Projets',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              // 🔥 BADGE ROUGE : compte les notifs non lues
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('notifications')
                    .where('userId', isEqualTo: userId)
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                  if (count == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: count > 9 ? 18 : 14,
                      height: 14,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('projects')
            .where('members', arrayContains: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B5BD6)),
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
                    Icons.folder_open_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun projet assigné',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'êtes pas encore assigné à un projet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          final List<ProjectModel> projects = snapshot.data!.docs.map((doc) {
            return ProjectModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
          }).toList();

          // Charge les photos des membres
          _loadMembersPhotos(projects);
          // Charge la progression réelle pour ces projets
          _loadProjectsProgress(projects);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(project);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/team');
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: const Color(0xFF5B5BD6),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Projets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Equipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  /// 🔄 Charge les photos de profil des membres
  Future<void> _loadMembersPhotos(List<ProjectModel> projects) async {
    final Set<String> allMemberIds = {};
    for (final project in projects) {
      for (final memberId in project.members) {
        allMemberIds.add(memberId);
      }
    }

    for (final memberId in allMemberIds) {
      if (_membersPhotos.containsKey(memberId)) continue;

      try {
        final doc = await _firestore.collection('users').doc(memberId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          _membersPhotos[memberId] = data?['photoURL'] as String?;
        } else {
          _membersPhotos[memberId] = null;
        }
      } catch (e) {
        print('Erreur chargement photo membre $memberId: $e');
        _membersPhotos[memberId] = null;
      }
    }
  }

  /// 🔄 Charge la progression réelle (depuis les tâches) pour chaque projet
  Future<void> _loadProjectsProgress(List<ProjectModel> projects) async {
    final taskService = TaskService();

    final toLoad = <String>[];
    for (final p in projects) {
      if (p.id.isNotEmpty && !_projectProgress.containsKey(p.id)) {
        toLoad.add(p.id);
      }
    }

    for (final projectId in toLoad) {
      try {
        final stats = await taskService.getTaskStats(projectId);
        final total = stats['total'] ?? 0;
        final done = stats['done'] ?? 0;
        final progress = total > 0 ? (done / total) : 0.0;
        setState(() {
          _projectProgress[projectId] = progress.clamp(0.0, 1.0);
        });
      } catch (e) {
        print('Erreur chargement progress project $projectId: $e');
        setState(() {
          _projectProgress[projectId] = 0.0;
        });
      }
    }
  }

  /// 🖼️ Widget avatar avec photo de profil locale
  Widget _buildAvatar(String? photoURL, {double size = 32}) {
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

  /// 🎨 Parse la couleur du projet depuis Firestore
  Color? _parseProjectColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      String cleaned = colorString.trim().toUpperCase();
      if (cleaned.startsWith('0X')) cleaned = cleaned.substring(2);
      else if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
      if (cleaned.length == 6) cleaned = 'FF' + cleaned;
      if (cleaned.length != 8) return const Color(0xFF5B5BD6);
      return Color(int.parse(cleaned, radix: 16));
    } catch (e) {
      print('Erreur parsing couleur "$colorString": $e');
      return const Color(0xFF5B5BD6);
    }
  }

  Widget _buildProjectCard(ProjectModel project) {
    final Color projectColor = _parseProjectColor(project.color) ?? const Color(0xFF5B5BD6);
    final double progress = _projectProgress[project.id] ?? (project.progress ?? 0.0);
    final int progressPercent = (progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailPage2(project: project),
            ),
          );
        },
        child: Column(
          children: [
            // ✅ Barre de couleur du projet en haut
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: projectColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Suppression des 3 points — espace réservé
                      const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description ?? 'Aucune description',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ✅ Avatars des membres avec vraies photos
                      _buildMemberAvatars(project.members),

                      // ✅ Date d'échéance au lieu de date de création
                      Row(
                        children: [
                          Icon(
                            project.dueDate != null
                                ? Icons.event_available_outlined
                                : Icons.event_busy_outlined,
                            size: 14,
                            color: project.dueDate != null
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.dueDate != null
                                ? _formatDate(project.dueDate!)
                                : 'Sans échéance',
                            style: TextStyle(
                              fontSize: 12,
                              color: project.dueDate != null
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontStyle: project.dueDate != null
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ Barre de progression avec VRAIE valeur
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: projectColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ VRAI pourcentage de progression
                  Text(
                    '$progressPercent% complété',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🖼️ Avatars des membres avec photos réelles (stackés)
  Widget _buildMemberAvatars(List<String>? members) {
    if (members == null || members.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayMembers = members.take(3).toList();
    const double avatarSize = 32;
    const double overlap = 12;

    return SizedBox(
      height: avatarSize,
      width: avatarSize + (displayMembers.length - 1) * overlap,
      child: Stack(
        children: displayMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final memberId = entry.value;
          final photoURL = _membersPhotos[memberId];

          return Positioned(
            left: index * overlap,
            child: _buildAvatar(photoURL, size: avatarSize),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}