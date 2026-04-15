import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "Jean Dupont";
    final String userEmail = user?.email ?? "jean.dupont@devmob.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Photo de profil avec badge caméra
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  // Badge caméra cliquable
                  GestureDetector(
                    onTap: () {
                      _showImagePickerOptions();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Nom
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),

              // Badge Admin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Menu items - Style de l'image
              _buildMenuItem(
                icon: Icons.edit_outlined,
                title: 'Modifier Profil',
                onTap: () {
                  _navigateToEditProfile();
                },
              ),

              _buildMenuItem(
                icon: null,
                title: 'Thème',
                trailing: Switch(
                  value: _isDarkTheme,
                  onChanged: (value) {
                    setState(() {
                      _isDarkTheme = value;
                    });
                    _toggleTheme(value);
                  },
                  activeColor: const Color(0xFF6B4EFF),
                ),
              ),

              _buildMenuItem(
                icon: Icons.language_outlined,
                title: 'Langue',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Français',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () {
                  _showLanguageSelector();
                },
              ),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Aide',
                onTap: () {
                  _navigateToHelp();
                },
              ),

              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Confidentialité',
                onTap: () {
                  _navigateToPrivacy();
                },
              ),

              const SizedBox(height: 32),

              // Bouton déconnexion
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutConfirmation();
                  },
                  icon: const Icon(Icons.logout, size: 20, color: Colors.red),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes pour les actions cliquables
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter la logique caméra
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter la logique galerie
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Implémenter la suppression
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    // Navigation vers la page d'édition du profil
    // Ajoutez cette route dans votre main.dart si elle n'existe pas
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _toggleTheme(bool isDark) {
    // Implémenter le changement de thème
    // Par exemple avec Provider ou GetX
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Choisir la langue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Color(0xFF6B4EFF)),
              title: const Text('Français'),
              onTap: () {
                Navigator.pop(context);
                // Changer la langue
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                // Changer la langue
              },
            ),
            ListTile(
              title: const Text('Español'),
              onTap: () {
                Navigator.pop(context);
                // Changer la langue
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHelp() {
    // Ajoutez cette route dans votre main.dart si elle n'existe pas
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpPage()),
    );
  }

  void _navigateToPrivacy() {
    // Ajoutez cette route dans votre main.dart si elle n'existe pas
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPage()),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigation vers la page de connexion en utilisant la route nommée
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: ${e.toString()}')),
      );
    }
  }

  Widget _buildMenuItem({
    IconData? icon,
    required String title,
    String? badge,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: icon != null
            ? Icon(
                icon,
                color: Colors.grey.shade600,
                size: 22,
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: trailing ??
            (badge != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  )),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// Placeholder classes pour les pages supplémentaires
// À remplacer par vos vraies pages ou supprimer si elles existent déjà
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: const Center(child: Text('Page de modification du profil')),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: const Center(child: Text('Page d\'aide')),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: const Center(child: Text('Page de confidentialité')),
    );
  }
}