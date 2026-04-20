import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestiontaches/views/profile/user_profile_page.dart';
import 'package:gestiontaches/views/auth/ajoutermembre_page.dart';
import 'package:gestiontaches/views/project/collaborator_projects_page.dart';

class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  int _selectedIndex = 1; // Équipe est sélectionnée par défaut
  bool _isLoading = true;
  String? _currentUserId;
  bool _isCurrentUserAdmin = false;

  // Listes dynamiques
  List<Map<String, dynamic>> administrators = [];
  List<Map<String, dynamic>> collaborators = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _checkUserRole();
    _loadTeamMembers();
  }

  // 🔥 VÉRIFIER LE RÔLE DE L'UTILISATEUR
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isCurrentUserAdmin = data['role'] == 'admin' || data['isAdmin'] == true;
        });
      }
    } catch (e) {
      print('Erreur vérification rôle: $e');
    }
  }

  // 🔥 RÉCUPÉRATION DYNAMIQUE DES MEMBRES DEPUIS FIRESTORE
  Future<void> _loadTeamMembers() async {
    setState(() => _isLoading = true);
    
    try {
      FirebaseFirestore.instance
          .collection('users')
          .snapshots()
          .listen((snapshot) {
        final List<Map<String, dynamic>> admins = [];
        final List<Map<String, dynamic>> collabs = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final member = {
            'id': doc.id,
            'name': data['name'] ?? 'Sans nom',
            'email': data['email'] ?? 'Sans email',
            'image': data['imageUrl'] ?? data['photoURL'] ?? 'https://i.pravatar.cc/150?img=0',
            'role': data['role'] ?? 'Membre',
            'isAdmin': data['role'] == 'admin' || data['isAdmin'] == true,
          };

          if (doc.id == _currentUserId) {
            _isCurrentUserAdmin = member['isAdmin'];
          }

          if (member['isAdmin']) {
            admins.add(member);
          } else {
            collabs.add(member);
          }
        }

        setState(() {
          administrators = admins;
          collaborators = collabs;
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Erreur chargement membres: $e');
      setState(() => _isLoading = false);
    }
  }

  // ... (toutes les méthodes existantes: _promoteMember, _demoteMember, etc.) ...

  Future<void> _promoteMember(String memberId) async {
    if (!_isCurrentUserAdmin) {
      _showError('Seuls les administrateurs peuvent promouvoir des membres');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(memberId).update({
        'role': 'admin',
        'isAdmin': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess('Membre promu administrateur avec succès');
    } catch (e) {
      _showError('Erreur lors de la promotion: $e');
    }
  }

  Future<void> _demoteMember(String memberId) async {
    if (!_isCurrentUserAdmin) {
      _showError('Action non autorisée');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(memberId).update({
        'role': 'member',
        'isAdmin': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess('Administrateur rétrogradé en membre');
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (!_isCurrentUserAdmin) {
      _showError('Action non autorisée');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(memberId).delete();
      _showSuccess('Membre retiré avec succès');
    } catch (e) {
      _showError('Erreur lors de la suppression: $e');
    }
  }

  Future<void> _addMemberByEmail(String email) async {
    if (!_isCurrentUserAdmin) {
      _showError('Seuls les administrateurs peuvent ajouter des membres');
      return;
    }
    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existing.docs.isNotEmpty) {
        _showError('Cet email est déjà membre de l\'équipe');
        return;
      }

      await FirebaseFirestore.instance.collection('users').add({
        'email': email,
        'name': 'Nouveau Membre',
        'role': 'member',
        'isAdmin': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': 'https://i.pravatar.cc/150?img=${DateTime.now().millisecond}',
      });
      _showSuccess('Invitation envoyée à $email');
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showOptionsMenu(BuildContext context, Map<String, dynamic> member) {
    final bool isAdmin = member['isAdmin'];
    final String memberId = member['id'];
    final bool isCurrentUser = memberId == _currentUserId;

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
                
                if (_isCurrentUserAdmin && !isCurrentUser) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                        color: const Color(0xFF6B4EFF),
                        size: 20,
                      ),
                    ),
                    title: Text(isAdmin ? 'Rétrograder en membre' : 'Promouvoir admin'),
                    onTap: () {
                      Navigator.pop(context);
                      if (isAdmin) {
                        _demoteMember(memberId);
                      } else {
                        _promoteMember(memberId);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                if (_isCurrentUserAdmin && !isCurrentUser)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                    ),
                    title: Text('Retirer', style: TextStyle(color: Colors.red.shade400)),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(memberId, member['name']);
                    },
                  ),

                if (!_isCurrentUserAdmin)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Options disponibles uniquement pour les administrateurs',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment retirer $memberName de l\'équipe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(memberId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Membres de l\'équipe',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isCurrentUserAdmin)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF6B4EFF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Color(0xFF6B4EFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (administrators.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            'Administrateurs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${administrators.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...administrators.map((admin) => _buildMemberCard(
                        member: admin,
                        onMorePressed: () => _showOptionsMenu(context, admin),
                      )),
                      const SizedBox(height: 24),
                    ],
                    
                    Row(
                      children: [
                        const Text(
                          'Collaborateurs',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${collaborators.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          if (collaborators.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, color: Colors.grey.shade400, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun collaborateur',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...collaborators.asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;
                              return Column(
                                children: [
                                  _buildCollaboratorItem(
                                    member: member,
                                    onMorePressed: () => _showOptionsMenu(context, member),
                                    onPromote: () => _promoteMember(member['id']),
                                  ),
                                  if (index < collaborators.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 76,
                                      endIndent: 16,
                                      color: Colors.grey.shade200,
                                    ),
                                ],
                              );
                            }),
                          
                          if (_isCurrentUserAdmin)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddMemberOptions(),
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text(
                                    'Ajouter un membre',  
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B4EFF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      
      // 🎯 NAVIGATION ADAPTATIVE SELON LE RÔLE
      // Admin: FAB + BottomNav custom (4 items)
      // Collaborateur: BottomNavigationBar standard (3 items) comme CollaboratorProjectsPage
      floatingActionButton: _isCurrentUserAdmin
          ? GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/createprojects'),
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
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: _isCurrentUserAdmin
          ? FloatingActionButtonLocation.centerDocked
          : null,
      
      bottomNavigationBar: _isCurrentUserAdmin
          // 🎯 MENU ADMIN (4 items + FAB)
          ? Container(
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
                      _buildAdminNavItem(Icons.home_outlined, 'Accueil', 0),
                      _buildAdminNavItem(Icons.folder_outlined, 'Projets', 1),
                      const SizedBox(width: 56),
                      _buildAdminNavItem(Icons.people_outline, 'Équipe', 2),
                      _buildAdminNavItem(Icons.person_outline, 'Profil', 3),
                    ],
                  ),
                ),
              ),
            )
          // 🎯 MENU COLLABORATEUR (3 items) - Identique à CollaboratorProjectsPage
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CollaboratorProjectsPage()),
                    );
                    break;
                  case 1:
                    // Déjà sur Équipe
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                    break;
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
                  label: 'Équipe',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }

  // 🎯 NAV ITEM POUR ADMIN (custom)
  Widget _buildAdminNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushNamed(context, '/projects');
            break;
          case 2:
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

  Widget _buildMemberCard({
    required Map<String, dynamic> member,
    required VoidCallback onMorePressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildAvatar(member['image']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['email'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onMorePressed,
            child: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorItem({
    required Map<String, dynamic> member,
    required VoidCallback onMorePressed,
    required VoidCallback onPromote,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(member['image']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member['email'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Membre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onMorePressed,
                child: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isCurrentUserAdmin)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: onPromote,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B4EFF),
                  side: const BorderSide(color: Color(0xFF6B4EFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Promouvoir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String imageUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: imageUrl.isEmpty || imageUrl == 'https://i.pravatar.cc/150?img=0'
          ? Icon(Icons.person, color: Colors.grey.shade400)
          : null,
    );
  }

  void _showAddMemberOptions() {
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
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                const Text(
                  'Ajouter un membre',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez comment ajouter le nouveau membre',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMemberByEmailDialog();
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF6B4EFF), size: 24),
                  ),
                  title: const Text('Par email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text('Envoyer une invitation par email', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_outlined, color: Colors.green, size: 24),
                  ),
                  title: const Text('Nouveau compte', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text('Créer un compte pour le membre', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMemberByEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Inviter par email'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Email du membre',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6B4EFF))),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(context);
                _addMemberByEmail(emailController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}