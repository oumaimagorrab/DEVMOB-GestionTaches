import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestiontaches/services/project_service.dart';
import 'package:gestiontaches/models/user.dart'; // Utilisation de UserModel

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  DateTime? _selectedDate;
  int _selectedColorIndex = 0;
  int _descriptionLength = 0;
  bool _isInviting = false;

  final List<Color> projectColors = [
    const Color(0xFF5B5BD6),
    const Color(0xFFA855F7),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
  ];

  // Base de données simulée des utilisateurs enregistrés (utilise UserModel)
  final Map<String, UserModel> registeredUsers = {
    'alice@example.com': UserModel(
      id: '1',
      name: 'Alice Martin',
      email: 'alice@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=1',
      createdAt: DateTime.now(),
      isActive: true,
    ),
    'bob@example.com': UserModel(
      id: '2',
      name: 'Bob Durand',
      email: 'bob@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=2',
      createdAt: DateTime.now(),
      isActive: true,
    ),
    'claire@example.com': UserModel(
      id: '3',
      name: 'Claire Petit',
      email: 'claire@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=3',
      createdAt: DateTime.now(),
      isActive: true,
    ),
    'david@example.com': UserModel(
      id: '4',
      name: 'David Bernard',
      email: 'david@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=4',
      createdAt: DateTime.now(),
      isActive: true,
    ),
  };

  // Membres récents pour l'affichage rapide
  final List<UserModel> recentMembers = [];

  // Membres invités au projet
  List<UserModel> invitedMembers = [];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
    // Initialiser les membres récents
    recentMembers.addAll(registeredUsers.values.take(3));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B5BD6),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Valider le format de l'email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Inviter un membre par email
  Future<void> _inviteMember() async {
    final email = _emailController.text.trim().toLowerCase();
    
    if (email.isEmpty) {
      _showSnackBar('Veuillez entrer un email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Format d\'email invalide');
      return;
    }

    // Vérifier si déjà invité
    if (invitedMembers.any((m) => m.email == email)) {
      _showSnackBar('Cet utilisateur est déjà invité');
      return;
    }

    setState(() {
      _isInviting = true;
    });

    // Simuler un appel API
    await Future.delayed(const Duration(seconds: 1));

    UserModel? user;
    bool isNewUser = false;

    // Vérifier si l'utilisateur existe dans la base
    if (registeredUsers.containsKey(email)) {
      user = registeredUsers[email]!;
    } else {
      // Créer un nouvel utilisateur non enregistré
      isNewUser = true;
      user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Générer un ID unique
        name: email.split('@')[0], // Utiliser la partie avant @ comme nom temporaire
        email: email,
        photoURL: 'https://i.pravatar.cc/150?img=${email.hashCode % 70}',
        createdAt: DateTime.now(),
        isActive: false, // Non actif car non enregistré
      );
    }

    setState(() {
      invitedMembers.add(user!);
      _emailController.clear();
      _isInviting = false;
    });

    // Afficher le message approprié
    if (isNewUser) {
      _showSnackBar('Invitation envoyée à $email', isSuccess: true);
      // Ici vous pouvez intégrer un vrai service d'email
      _sendEmailInvitation(email);
    } else {
      _showSnackBar('${user.name} a été ajouté au projet', isSuccess: true);
    }
  }

  // Simuler l'envoi d'email
  void _sendEmailInvitation(String email) {
    print('📧 Envoi d\'invitation à: $email');
    print('📧 Sujet: Invitation à rejoindre le projet "${_nameController.text}"');
    print('📧 Contenu: Vous êtes invité à rejoindre le projet...');
    // Intégration possible avec: SendGrid, Firebase, EmailJS, etc.
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _createProject() {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un nom de projet');
      return;
    }
    
    final newProject = {
      'title': _nameController.text,
      'description': _descriptionController.text.isEmpty 
          ? 'Aucune description' 
          : _descriptionController.text,
      'progress': 0.0,
      'progressColor': projectColors[_selectedColorIndex],
      'date': _selectedDate,
      'members': invitedMembers.isEmpty 
          ? ['https://i.pravatar.cc/150?img=11']
          : invitedMembers.map((m) => m.photoURL).toList(),
      'memberDetails': invitedMembers.map((m) => m.toJson()).toList(),
      'topBorderColor': projectColors[_selectedColorIndex],
    };
    
    ProjectService().addProject(newProject);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    
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
          'Nouveau projet',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _nameController.text.isNotEmpty ? _createProject : null,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B5BD6),
                disabledForegroundColor: Colors.grey.shade400,
              ),
              child: const Text(
                'Créer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Informations
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nom du projet
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nom du projet *',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5B5BD6), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5B5BD6), width: 1),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_descriptionLength/500',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? dateFormat.format(_selectedDate!)
                          : 'Date d\'échéance',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Couleur du projet
            const Text(
              'Couleur du projet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: List.generate(projectColors.length, (index) {
                final isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: projectColors[index],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: projectColors[index].withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 32),
            
            // Section Membres
            const Text(
              'Membres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des membres déjà invités
            if (invitedMembers.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: invitedMembers.length,
                  itemBuilder: (context, index) {
                    final user = invitedMembers[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6B4EFF),
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(user.photoURL ?? 'https://i.pravatar.cc/150?img=0'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Indicateur pour utilisateur non actif (non enregistré)
                              if (!user.isActive)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mail_outline,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      invitedMembers.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.name.split(' ')[0],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!user.isActive)
                            Text(
                              'En attente',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[600],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Ajouter par email
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Ajouter par email',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5B5BD6), width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isInviting ? null : _inviteMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isInviting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Inviter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Membres suggérés (enregistrés)
            if (recentMembers.isNotEmpty) ...[
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: recentMembers.where((m) => 
                  !invitedMembers.any((invited) => invited.email == m.email)
                ).map((user) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        invitedMembers.add(user);
                      });
                      _showSnackBar('${user.name} ajouté', isSuccess: true);
                    },
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundImage: NetworkImage(user.photoURL ?? 'https://i.pravatar.cc/150?img=0'),
                      ),
                      label: Text(user.name),
                      backgroundColor: Colors.grey.shade100,
                      deleteIcon: const Icon(Icons.add, size: 18),
                      onDeleted: () {
                        setState(() {
                          invitedMembers.add(user);
                        });
                        _showSnackBar('${user.name} ajouté', isSuccess: true);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}