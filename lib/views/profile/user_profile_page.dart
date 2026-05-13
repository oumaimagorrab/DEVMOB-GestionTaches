import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gestiontaches/views/auth/ajoutermembre_page.dart';
import 'package:gestiontaches/views/project/create_project_page.dart';
import 'package:gestiontaches/views/project/dashboard_page.dart';
import 'package:gestiontaches/views/project/project_liste_page.dart';
import 'package:gestiontaches/views/project/collaborator_projects_page.dart';
import 'package:gestiontaches/views/profile/team_member_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  bool _isCurrentUserAdmin = false;
  bool _isLoadingRole = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // 🔥 VÉRIFIER LE RÔLE DE L'UTILISATEUR
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingRole = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final isAdmin = data['role'] == 'admin' || data['isAdmin'] == true;
        setState(() {
          _isCurrentUserAdmin = isAdmin;
          _selectedIndex = isAdmin ? 3 : 2;
          _isLoadingRole = false;
        });
      } else {
        setState(() => _isLoadingRole = false);
      }
    } catch (e) {
      print('Erreur verification role: $e');
      setState(() => _isLoadingRole = false);
    }
  }

  // 📸 PRENDRE UNE PHOTO AVEC LA CAMERA
  Future<void> _takePhoto() async {
    Navigator.pop(context);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        await _savePhotoLocally(photo.path);
      }
    } catch (e) {
      _showError('Erreur camera: $e');
    }
  }

  // 🖼️ CHOISIR DEPUIS LA GALERIE
  Future<void> _pickFromGallery() async {
    Navigator.pop(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _savePhotoLocally(image.path);
      }
    } catch (e) {
      _showError('Erreur galerie: $e');
    }
  }

  // 💾 SAUVEGARDER LA PHOTO LOCALEMENT ET METTRE A JOUR FIRESTORE
  Future<void> _savePhotoLocally(String sourcePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Copier l'image dans le dossier local de l'app
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = '${appDir.path}/$fileName';

      final File sourceFile = File(sourcePath);
      await sourceFile.copy(localPath);

      // Sauvegarder le chemin dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': localPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Photo mise a jour avec succes');
    } catch (e) {
      _showError('Erreur sauvegarde photo: $e');
    }
  }

  // 🗑️ SUPPRIMER LA PHOTO DE PROFIL
  Future<void> _deletePhoto() async {
    Navigator.pop(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Recuperer le chemin actuel pour supprimer le fichier
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final String? currentPath = data['photoURL'] as String?;
        if (currentPath != null && currentPath.isNotEmpty) {
          final File file = File(currentPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // Mettre a jour Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Photo supprimee');
    } catch (e) {
      _showError('Erreur suppression: $e');
    }
  }

  // 🎨 BOTTOM SHEET PERSONNALISE POUR LE SELECTEUR DE PHOTO
  void _showImagePickerOptions() {
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
                // Indicateur de drag
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
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez une option',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),

                // Option : Prendre une photo
                _buildPhotoOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFF6B4EFF),
                  iconBgColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                  title: 'Prendre une photo',
                  subtitle: 'Utiliser la camera',
                  onTap: _takePhoto,
                ),

                const SizedBox(height: 12),

                // Option : Choisir depuis la galerie
                _buildPhotoOption(
                  icon: Icons.photo_library_rounded,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.withOpacity(0.1),
                  title: 'Choisir depuis la galerie',
                  subtitle: 'Selectionner une photo existante',
                  onTap: _pickFromGallery,
                ),

                const SizedBox(height: 12),

                // Option : Supprimer la photo
                _buildPhotoOption(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.withOpacity(0.1),
                  title: 'Supprimer la photo',
                  subtitle: 'Retirer la photo actuelle',
                  onTap: _deletePhoto,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 WIDGET POUR CHAQUE OPTION DU BOTTOM SHEET
  Widget _buildPhotoOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
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
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "Jean Dupont";
    final String userEmail = user?.email ?? "jean.dupont@devmob.com";

    final String roleBadge = _isCurrentUserAdmin ? 'Admin' : 'Collaborateur';
    final Color roleColor = _isCurrentUserAdmin ? const Color(0xFF6B4EFF) : const Color(0xFF5B5BD6);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String? localImagePath;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          localImagePath = data?['photoURL'] as String?;
                        }

                        final hasLocalImage = localImagePath != null && localImagePath.isNotEmpty && File(localImagePath).existsSync();

                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: hasLocalImage
                                  ? ClipOval(
                                      child: Image.file(
                                        File(localImagePath!),
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey.shade400,
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
                        );
                      },
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
                        color: roleColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleBadge,
                        style: const TextStyle(
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
                      title: 'Confidentialite',
                      onTap: _navigateToPrivacy,
                    ),

                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'A propos',
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
                          'Se deconnecter',
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

      bottomNavigationBar: _isLoadingRole
          ? const SizedBox.shrink()
          : _isCurrentUserAdmin
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
                          _buildAdminNavItem(Icons.people_outline, 'Equipe', 2),
                          _buildAdminNavItem(Icons.person_outline, 'Profil', 3),
                        ],
                      ),
                    ),
                  ),
                )
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const TeamMembersPage()),
                        );
                        break;
                      case 2:
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

  Widget _buildAdminNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushNamed(context, '/projects');
            break;
          case 2:
            Navigator.pushReplacement(
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
                  content: 'TaskFlow est votre assistant de gestion de projets et d\'equipes. Organisez vos taches, suivez l\'avancement de vos projets et collaborez efficacement avec votre equipe, tout en un seul endroit.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.task_alt,
                  title: 'Gerer vos projets',
                  content: 'Creez des projets en appuyant sur le bouton violet "+" en bas de l\'ecran. Attribuez des taches aux membres de votre equipe, definissez des deadlines et suivez la progression en temps reel.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.people_outline,
                  title: 'Gerer votre equipe',
                  content: 'Accedez a l\'onglet "Equipe" pour voir tous les membres. En tant qu\'administrateur, vous pouvez inviter de nouveaux membres par email, promouvoir des collaborateurs ou gerer les roles.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  content: 'Recevez des alertes lorsqu\'une tache vous est assignee, qu\'un projet approche de sa deadline ou qu\'un membre commente votre travail.',
                ),
                const SizedBox(height: 20),
                _buildHelpSection(
                  icon: Icons.support_agent,
                  title: 'Besoin d\'aide ?',
                  content: 'Si vous rencontrez un probleme ou avez une suggestion, contactez notre equipe support a l\'adresse : support@taskflow.app',
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
              'Confidentialite',
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
                  title: 'Politique de confidentialite',
                  content: 'Chez TaskFlow, nous prenons la protection de vos donnees tres au serieux. Cette politique explique comment nous collectons, utilisons et protegeons vos informations personnelles.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Donnees collectees',
                  content: 'Nous collectons uniquement les donnees necessaires au fonctionnement de l\'application : votre nom, adresse email, photo de profil, et les informations relatives aux projets et taches que vous creez. Ces donnees sont stockees de maniere securisee sur nos serveurs.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Utilisation des donnees',
                  content: 'Vos donnees sont utilisees pour : vous permettre d\'acceder a votre compte, gerer vos projets et equipes, vous envoyer des notifications importantes, et ameliorer nos services. Nous ne vendons jamais vos donnees a des tiers.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Securite',
                  content: 'Toutes vos donnees sont chiffrees en transit et au repos. Nous utilisons l\'authentification Firebase et des protocoles de securite avances pour garantir la protection de vos informations.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Vos droits',
                  content: 'Vous disposez d\'un droit d\'acces, de rectification et de suppression de vos donnees. Pour exercer ces droits ou pour toute question, contactez-nous a privacy@taskflow.app.',
                ),
                const SizedBox(height: 20),
                _buildPrivacySection(
                  title: 'Derniere mise a jour',
                  content: 'Cette politique a ete mise a jour le 20 avril 2026.',
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
              'A propos',
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
                  'Developpe avec ❤️ par l\'equipe TaskFlow',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 TaskFlow. Tous droits reserves.',
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
        title: const Text('Deconnexion'),
        content: const Text('Etes-vous sur de vouloir vous deconnecter ?'),
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
            child: const Text('Deconnecter'),
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
        SnackBar(content: Text('Erreur lors de la deconnexion: ${e.toString()}')),
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
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecte');

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      final email = _emailController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': fullName,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(fullName);

      if (email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
        _showSuccess('Un email de verification a ete envoye a $email');
      } else {
        _showSuccess('Profil mis a jour avec succes');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Erreur sauvegarde: $e');
    }

    setState(() => _isSaving = false);
  }

  // 📸 PRENDRE UNE PHOTO DANS EDIT PROFILE
  Future<void> _takePhotoEdit() async {
    Navigator.pop(context);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        await _savePhotoLocallyEdit(photo.path);
      }
    } catch (e) {
      _showError('Erreur camera: $e');
    }
  }

  // 🖼️ CHOISIR DEPUIS LA GALERIE DANS EDIT PROFILE
  Future<void> _pickFromGalleryEdit() async {
    Navigator.pop(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _savePhotoLocallyEdit(image.path);
      }
    } catch (e) {
      _showError('Erreur galerie: $e');
    }
  }

  // 💾 SAUVEGARDER LA PHOTO DANS EDIT PROFILE
  Future<void> _savePhotoLocallyEdit(String sourcePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = '${appDir.path}/$fileName';

      final File sourceFile = File(sourcePath);
      await sourceFile.copy(localPath);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': localPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Photo mise a jour avec succes');
    } catch (e) {
      _showError('Erreur sauvegarde photo: $e');
    }
  }

  // 🗑️ SUPPRIMER LA PHOTO DANS EDIT PROFILE
  Future<void> _deletePhotoEdit() async {
    Navigator.pop(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final String? currentPath = data['photoURL'] as String?;
        if (currentPath != null && currentPath.isNotEmpty) {
          final File file = File(currentPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Photo supprimee');
    } catch (e) {
      _showError('Erreur suppression: $e');
    }
  }

  // 🎨 BOTTOM SHEET POUR EDIT PROFILE
  void _showImagePickerOptionsEdit() {
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
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez une option',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPhotoOptionEdit(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFF6B4EFF),
                  iconBgColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                  title: 'Prendre une photo',
                  subtitle: 'Utiliser la camera',
                  onTap: _takePhotoEdit,
                ),
                const SizedBox(height: 12),
                _buildPhotoOptionEdit(
                  icon: Icons.photo_library_rounded,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.withOpacity(0.1),
                  title: 'Choisir depuis la galerie',
                  subtitle: 'Selectionner une photo existante',
                  onTap: _pickFromGalleryEdit,
                ),
                const SizedBox(height: 12),
                _buildPhotoOptionEdit(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.withOpacity(0.1),
                  title: 'Supprimer la photo',
                  subtitle: 'Retirer la photo actuelle',
                  onTap: _deletePhotoEdit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOptionEdit({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
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
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String? localImagePath;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          localImagePath = data?['photoURL'] as String?;
                        }

                        final hasLocalImage = localImagePath != null && localImagePath.isNotEmpty && File(localImagePath).existsSync();

                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: hasLocalImage
                                  ? ClipOval(
                                      child: Image.file(
                                        File(localImagePath!),
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey.shade400,
                                    ),
                            ),
                            GestureDetector(
                              onTap: _showImagePickerOptionsEdit,
                              child: Container(
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
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'Prenom',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
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
        appBar: AppBar(title: const Text('Confidentialite')),
        body: const Center(child: Text('Page de confidentialite')),
      );
}