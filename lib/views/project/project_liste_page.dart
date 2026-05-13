import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/views/project/project_detail_page.dart';
import 'package:intl/intl.dart';
import 'create_project_page.dart';
import 'edit_project_page.dart'; // ← AJOUTÉ: Page d'édition
import 'package:gestiontaches/views/profile/user_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:gestiontaches/providers/project_provider.dart';
import 'package:gestiontaches/models/project.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  int _selectedIndex = 1;
  
  // Cache des photos de profil des membres : Map<userId, photoURL>
  final Map<String, String?> _membersPhotos = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<ProjectProvider>().initUserProjectsStream(userId);
      }
    });
  }

  /// 🔄 Charge les photos de profil des membres assignés aux projets
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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _membersPhotos[memberId] = data?['photoURL'] as String?;
          });
        } else {
          _membersPhotos[memberId] = null;
        }
      } catch (e) {
        print('Erreur chargement photo membre $memberId: $e');
        _membersPhotos[memberId] = null;
      }
    }
  }

  /// 🖼️ Widget avatar avec photo de profil
  Widget _buildMemberAvatar(String? photoURL, {double size = 28}) {
    final bool hasPhoto = photoURL != null && 
                          photoURL.isNotEmpty && 
                          File(photoURL).existsSync();

    if (!hasPhoto) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: ClipOval(
        child: Image.file(
          File(photoURL),
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM', 'fr_FR');
    final projectProvider = context.watch<ProjectProvider>();
    final List<ProjectModel> projects = projectProvider.projects;

    if (projects.isNotEmpty && _membersPhotos.isEmpty) {
      _loadMembersPhotos(projects);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes Projets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Liste des projets
            Expanded(
              child: projectProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : projectProvider.error != null
                      ? Center(
                          child: Text(
                            'Erreur: ${projectProvider.error}',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        )
                      : projects.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun projet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Créez votre premier projet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: projects.length,
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                final members = project.members;
                                final projectColor = _parseColor(project.color);
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProjectDetailPage(
                                          project: project,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
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
                                        // Barre de couleur en haut
                                        Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: projectColor,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
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
                                                  GestureDetector(
                                                    onTap: () {
                                                      _showProjectOptions(context, project);
                                                    },
                                                    child: Icon(
                                                      Icons.more_vert,
                                                      color: Colors.grey.shade400,
                                                      size: 20,
                                                    ),
                                                  ),
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
                                              ),
                                              
                                              const SizedBox(height: 16),
                                              
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  members.isEmpty
                                                      ? Text(
                                                          'Aucun membre',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey.shade500,
                                                          ),
                                                        )
                                                      : Row(
                                                          children: [
                                                            for (int i = 0; i < members.length && i < 3; i++)
                                                              _buildMemberAvatar(
                                                                _membersPhotos[members[i]],
                                                                size: 28,
                                                              ),
                                                            
                                                            if (members.length > 3)
                                                              Container(
                                                                width: 28,
                                                                height: 28,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey.shade200,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    '+${members.length - 3}',
                                                                    style: TextStyle(
                                                                      fontSize: 11,
                                                                      color: Colors.grey.shade600,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                  
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today_outlined,
                                                        size: 14,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        dateFormat.format(project.createdAt),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 16),
                                              
                                              // Barre de progression
                                              Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: FractionallySizedBox(
                                                  alignment: Alignment.centerLeft,
                                                  widthFactor: 0.0,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: projectColor ?? const Color(0xFF6B4EFF),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              
                                              const SizedBox(height: 10),
                                              
                                              Text(
                                                '0% complété',
                                                style: TextStyle(
                                                  fontSize: 13,
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
                              },
                            ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      
      floatingActionButton: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProjectPage()),
          );
          
          if (mounted && result == true) {
            context.read<ProjectProvider>().initProjectsStream();
          }
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

  // ✅ CORRIGÉ: Enlève 0x avant int.parse avec radix:16
  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      String cleaned = colorString.trim().toUpperCase();
      
      if (cleaned.startsWith('0X')) {
        cleaned = cleaned.substring(2);
      } else if (cleaned.startsWith('#')) {
        cleaned = cleaned.substring(1);
      }
      
      if (cleaned.length == 6) {
        cleaned = 'FF' + cleaned;
      }
      
      if (cleaned.length != 8) {
        print('Format couleur invalide: $colorString → cleaned=$cleaned');
        return const Color(0xFF6B4EFF);
      }
      
      final intValue = int.parse(cleaned, radix: 16);
      return Color(intValue);
    } catch (e) {
      print('Erreur parsing couleur "$colorString": $e');
      return const Color(0xFF6B4EFF);
    }
  }

  // ✅ MODIFIÉ: Supprimé "Partager", "Modifier" navigue vers EditProjectPage
  void _showProjectOptions(BuildContext context, ProjectModel project) {
    final projectProvider = context.read<ProjectProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ✅ MODIFIER: Navigation vers EditProjectPage
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF6B4EFF)),
                  title: const Text('Modifier le projet'),
                  onTap: () {
                    Navigator.pop(context); // Ferme le bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProjectPage(project: project),
                      ),
                    );
                  },
                ),
                
                // ❌ SUPPRIMÉ: Option "Partager"
                
                const SizedBox(height: 8),
                
                // SUPPRIMER
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await projectProvider.deleteProject(project.id);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(projectProvider.error ?? 'Erreur lors de la suppression'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
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
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 1:
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