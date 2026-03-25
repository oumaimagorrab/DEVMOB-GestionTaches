import 'package:flutter/material.dart'; 

class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  int _selectedIndex = 2;

  final List<Map<String, dynamic>> administrators = [
    {
      'name': 'Alice Martin',
      'email': 'alice@devmob.com',
      'image': 'https://i.pravatar.cc/150?img=1',
      'role': 'Admin',
      'isAdmin': true,
    },
    {
      'name': 'Bob Durand',
      'email': 'bob@devmob.com',
      'image': 'https://i.pravatar.cc/150?img=2',
      'role': 'Admin',
      'isAdmin': true,
    },
  ];

  final List<Map<String, dynamic>> collaborators = [
    {
      'name': 'Claire Petit',
      'email': 'claire@devmob.com',
      'image': 'https://i.pravatar.cc/150?img=3',
      'role': 'Membre',
      'isAdmin': false,
    },
    {
      'name': 'David Lopez',
      'email': 'david@devmob.com',
      'image': 'https://i.pravatar.cc/150?img=4',
      'role': 'Membre',
      'isAdmin': false,
    },
  ];

  void _promoteMember(int index) {
    setState(() {
      collaborators[index]['isAdmin'] = true;
      collaborators[index]['role'] = 'Admin';
      administrators.add(collaborators.removeAt(index));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membre promu administrateur')),
    );
  }

  void _showOptionsMenu(BuildContext context, Map<String, dynamic> member) {
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  title: const Text('Modifier'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
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
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Administrateurs
              const Text(
                'Administrateurs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Liste des administrateurs
              ...administrators.map((admin) => _buildMemberCard(
                member: admin,
                onMorePressed: () => _showOptionsMenu(context, admin),
              )),
              
              const SizedBox(height: 24),
              
              // ✅ SECTION COLLABORATEURS AVEC BOUTON AJOUTER À L'INTÉRIEUR
              const Text(
                'Collaborateurs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Container des collaborateurs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Liste des collaborateurs
                    ...collaborators.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Column(
                        children: [
                          _buildCollaboratorItem(
                            member: member,
                            onMorePressed: () => _showOptionsMenu(context, member),
                            onPromote: () => _promoteMember(index),
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
                    
                    // ✅ BOUTON AJOUTER UN MEMBRE À L'INTÉRIEUR DU CONTAINER
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddMemberDialog(),
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
      
      // FAB
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/createprojects');
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
      
      // Bottom Navigation Bar
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
                _buildNavItem(Icons.settings_outlined, 'Plus', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Carte pour les administrateurs (sans bordure extérieure)
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
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(member['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Nom et email
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
          
          // Badge Admin
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
          
          // Menu options
          GestureDetector(
            onTap: onMorePressed,
            child: Icon(
              Icons.more_vert,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Item pour les collaborateurs (dans le container groupé)
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
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(member['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Nom et email
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
              
              // Badge Membre
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
              
              // Menu options
              GestureDetector(
                onTap: onMorePressed,
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bouton Promouvoir
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
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

        // ✅ NAVIGATION SELON L'INDEX
        switch (index) {
          case 0: // Accueil
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 1: // Projets
            Navigator.pushNamed(context, '/projects');
            break;
          case 2: // Équipe
            
            break;
          case 3: // Plus
            Navigator.pushNamed(context, '/createprojects');
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

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un membre'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Email du membre',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
            ),
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
                setState(() {
                  collaborators.add({
                    'name': 'Nouveau Membre',
                    'email': emailController.text,
                    'image': 'https://i.pravatar.cc/150?img=${10 + collaborators.length}',
                    'role': 'Membre',
                    'isAdmin': false,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membre ajouté avec succès')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}