import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_project_page.dart'; 

class DashboardPage extends StatefulWidget {
  
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "Utilisateur";
    
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
                  // Menu hamburger
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  
                  // Notification avec badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
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
                  
                  // Photo de profil
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Salutation
                    Text(
                      'Bonjour $userName ! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Date
                    Text(
                      dateFormat.format(now),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Sous-titre
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        children: const [
                          TextSpan(text: 'Vous avez '),
                          TextSpan(
                            text: '3 tâches',
                            style: TextStyle(
                              color: Color(0xFF6B4EFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' en attente aujourd\'hui'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Grille de statistiques
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        // Projets actifs
                        _buildStatCard(
                          icon: Icons.folder_outlined,
                          iconColor: const Color(0xFF6B4EFF),
                          iconBgColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                          value: '12',
                          label: 'Projets actifs',
                          footer: '+2 ce mois',
                          footerColor: Colors.green,
                        ),
                        
                        // Tâches terminées
                        _buildStatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green,
                          iconBgColor: Colors.green.withOpacity(0.1),
                          value: '48',
                          label: 'Tâches terminées',
                          footer: 'cette semaine',
                          footerColor: Colors.grey.shade600,
                          showProgressBar: true,
                          progressColor: Colors.green,
                        ),
                        
                        // Tâches en retard
                        _buildStatCard(
                          icon: Icons.error_outline,
                          iconColor: Colors.red,
                          iconBgColor: Colors.red.withOpacity(0.1),
                          value: '3',
                          label: 'Tâches en retard',
                          showBadge: true,
                        ),
                        
                        // Membres actifs
                        _buildStatCard(
                          icon: Icons.people_outline,
                          iconColor: Colors.orange,
                          iconBgColor: Colors.orange.withOpacity(0.1),
                          value: '8',
                          label: 'Membres actifs',
                          showAvatars: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 100), // Espace pour le FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      floatingActionButton: GestureDetector(
        onTap: () {
          // ✅ NAVIGATION VERS CREATE PROJECT
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
                const SizedBox(width: 56), // Espace pour le FAB
                _buildNavItem(Icons.people_outline, 'Équipe', 2),
                _buildNavItem(Icons.settings_outlined, 'Plus', 3),
              ],
            ),
          ),
        ),
      ),
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
    bool showAvatars = false,
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
          
          if (showAvatars) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: Stack(
                children: [
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: i * 16,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://i.pravatar.cc/150?img=${10 + i}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
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
          
        // ✅ NAVIGATION SELON L'INDEX
        switch (index) {
          case 0: // Accueil
            // Déjà sur Dashboard
            break;
          case 1: // Projets
            Navigator.pushNamed(context, '/projects');
            break;
          case 2: // Équipe
            Navigator.pushNamed(context, '/team');
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
}