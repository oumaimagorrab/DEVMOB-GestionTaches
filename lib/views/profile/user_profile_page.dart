import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/views/auth/ajoutermembre_page.dart';
import 'package:gestiontaches/views/project/create_project_page.dart';
import 'package:gestiontaches/views/project/dashboard_page.dart';
import 'package:gestiontaches/views/project/project_liste_page.dart';
import 'package:gestiontaches/views/profile/team_member_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;

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
                  GestureDetector(
                    onTap: _showImagePickerOptions,
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

              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),

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

              _buildMenuItem(
                icon: Icons.edit_outlined,
                title: 'Modifier Profil',
                onTap: _navigateToEditProfile,
              ),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Aide',
                onTap: _navigateToHelp,
              ),

              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Confidentialité',
                onTap: _navigateToPrivacy,
              ),

              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'À propos',
                onTap: _navigateToAbout,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutConfirmation,
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

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),

      floatingActionButton: GestureDetector(
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Aide',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpSection(
                  icon: Icons.rocket_launch_outlined,
                  title: 'Bienvenue sur TaskFlow',
                  content: 'TaskFlow est votre assistant de gestion de projets et d\'équipes. Organisez vos tâches, suivez l\'avancement de vos projets et collaborez efficacement avec votre équipe, tout en un seul endroit.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.task_alt,
                  title: 'Gérer vos projets',
                  content: 'Créez des projets en appuyant sur le bouton violet "+" en bas de l\'écran. Attribuez des tâches aux membres de votre équipe, définissez des deadlines et suivez la progression en temps réel.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.people_outline,
                  title: 'Gérer votre équipe',
                  content: 'Accédez à l\'onglet "Équipe" pour voir tous les membres. En tant qu\'administrateur, vous pouvez inviter de nouveaux membres par email, promouvoir des collaborateurs ou gérer les rôles.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  content: 'Recevez des alertes lorsqu\'une tâche vous est assignée, qu\'un projet approche de sa deadline ou qu\'un membre commente votre travail.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.support_agent,
                  title: 'Besoin d\'aide ?',
                  content: 'Si vous rencontrez un problème ou avez une suggestion, contactez notre équipe support à l\'adresse : support@taskflow.app',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B4EFF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Confidentialité',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrivacySection(
                  title: 'Politique de confidentialité',
                  content: 'Chez TaskFlow, nous prenons la protection de vos données très au sérieux. Cette politique explique comment nous collectons, utilisons et protégeons vos informations personnelles.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Données collectées',
                  content: 'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application : votre nom, adresse email, photo de profil, et les informations relatives aux projets et tâches que vous créez. Ces données sont stockées de manière sécurisée sur nos serveurs.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Utilisation des données',
                  content: 'Vos données sont utilisées pour : vous permettre d\'accéder à votre compte, gérer vos projets et équipes, vous envoyer des notifications importantes, et améliorer nos services. Nous ne vendons jamais vos données à des tiers.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Sécurité',
                  content: 'Toutes vos données sont chiffrées en transit et au repos. Nous utilisons l\'authentification Firebase et des protocoles de sécurité avancés pour garantir la protection de vos informations.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Vos droits',
                  content: 'Vous disposez d\'un droit d\'accès, de rectification et de suppression de vos données. Pour exercer ces droits ou pour toute question, contactez-nous à privacy@taskflow.app.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Dernière mise à jour',
                  content: 'Cette politique a été mise à jour le 20 avril 2026.',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4EFF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'À propos',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B5BD6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B5BD6), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B5BD6).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TaskFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B5BD6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Développé avec ❤️ par l\'équipe TaskFlow',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 TaskFlow. Tous droits réservés.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            ? Icon(icon, color: Colors.grey.shade600, size: 22)
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
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushNamed(context, '/projects');
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeamMembersPage()),
            );
            break;
          case 3:
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade500,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 PAGE MODIFIER PROFIL - FONCTIONNELLE AVEC FIRESTORE
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 🔥 CHARGER LES DONNÉES DEPUIS FIRESTORE
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final fullName = data['name'] ?? user.displayName ?? '';

        // Séparer nom et prénom (suppose "Prénom Nom" ou juste un nom)
        final nameParts = fullName.trim().split(' ');
        if (nameParts.length >= 2) {
          _firstNameController.text = nameParts.first;
          _lastNameController.text = nameParts.sublist(1).join(' ');
        } else {
          _firstNameController.text = fullName;
          _lastNameController.text = '';
        }

        _emailController.text = data['email'] ?? user.email ?? '';
      } else {
        // Fallback sur Firebase Auth
        final fullName = user.displayName ?? '';
        final nameParts = fullName.trim().split(' ');
        if (nameParts.length >= 2) {
          _firstNameController.text = nameParts.first;
          _lastNameController.text = nameParts.sublist(1).join(' ');
        } else {
          _firstNameController.text = fullName;
        }
        _emailController.text = user.email ?? '';
      }
    } catch (e) {
      _showError('Erreur chargement: $e');
    }

    setState(() => _isLoading = false);
  }

  // 🔥 SAUVEGARDER LES MODIFICATIONS
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      final email = _emailController.text.trim();

      // 1. Mettre à jour Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': fullName,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Mettre à jour Firebase Auth (displayName)
      await user.updateDisplayName(fullName);

      // 3. Mettre à jour l'email si différent
      if (email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
        _showSuccess('Un email de vérification a été envoyé à $email');
      } else {
        _showSuccess('Profil mis à jour avec succès');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Erreur sauvegarde: $e');
    }

    setState(() => _isSaving = false);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6B4EFF),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo de profil
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
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Champ Prénom
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'Prénom',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 16),

                    // Champ Nom
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 16),

                    // Champ Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bouton Sauvegarder
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4EFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sauvegarder les modifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Aide')),
        body: const Center(child: Text('Page d\'aide')),
      );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Confidentialité')),
        body: const Center(child: Text('Page de confidentialité')),
      );
}