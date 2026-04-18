import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestiontaches/models/user.dart'; 
import 'package:gestiontaches/providers/project_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
  bool _isLoadingMembers = true;

  final List<Color> projectColors = [
    const Color(0xFF5B5BD6),
    const Color(0xFFA855F7),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
  ];

  List<Map<String, dynamic>> _members = [];
  String? _selectedMemberId;
  List<Map<String, dynamic>> invitedMembers = [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _usersSubscription?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('✅ Utilisateur déjà connecté: ${currentUser.uid}');
      _loadMembers();
    } else {
      print('⏳ Attente de l\'authentification...');
      setState(() => _isLoadingMembers = true);
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        print('✅ Utilisateur authentifié: ${user.uid}');
        _subscribeMembersStream();
      } else if (user == null && mounted) {
        print('⚠️ Utilisateur déconnecté');
        _usersSubscription?.cancel();
        setState(() {
          _isLoadingMembers = false;
          _members = [];
        });
      }
    });
  }

  Future<void> _loadMembers() async {
    _subscribeMembersStream();
  }

  void _subscribeMembersStream() {
    _usersSubscription?.cancel();
    setState(() => _isLoadingMembers = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ ERREUR: Tentative d\'abonnement sans utilisateur connecté');
      setState(() => _isLoadingMembers = false);
      return;
    }

    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> loadedMembers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['displayName'] ?? data['name'] ?? 'Utilisateur',
          'image': data['photoURL'] ?? data['avatar'] ?? 'https://i.pravatar.cc/150?img=${doc.hashCode % 70}',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'collaborateur',
        };
      }).toList();

      final filteredMembers = loadedMembers.where((m) {
        final role = m['role'] as String?;
        final id = m['id'] as String?;
        return role != 'admin' && id != currentUser.uid;
      }).toList();

      print('🔔 Mise à jour membres (stream): ${filteredMembers.length}');

      if (mounted) {
        setState(() {
          _members = filteredMembers;
          _isLoadingMembers = false;
        });
      }
    }, onError: (e) {
      print('❌ Erreur stream membres: $e');
      if (mounted) setState(() => _isLoadingMembers = false);
    });
  }

  Future<Map<String, dynamic>?> _findUserByEmail(String email) async {
    try {
      final existingUser = _members.cast<Map<String, dynamic>?>().firstWhere(
        (m) => m != null && (m['email'] as String).toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      if (existingUser != null) return existingUser;

      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final doc = result.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final role = data['role'] ?? 'collaborateur';
        if (role == 'admin') {
          return null;
        }

        return {
          'id': doc.id,
          'name': data['displayName'] ?? data['name'] ?? email.split('@')[0],
          'image': data['photoURL'] ?? data['avatar'] ?? 'https://i.pravatar.cc/150?img=${email.hashCode % 70}',
          'email': email,
          'role': role,
        };
      }
      return null;
    } catch (e) {
      print('❌ Erreur recherche utilisateur: $e');
      return null;
    }
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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

    if (invitedMembers.any((m) => m['email'] == email)) {
      _showSnackBar('Cet utilisateur est déjà invité');
      return;
    }

    setState(() => _isInviting = true);

    final user = await _findUserByEmail(email);
    bool isNewUser = user == null;

    Map<String, dynamic> userToInvite;
    if (user != null) {
      if (user['role'] == 'admin') {
        setState(() => _isInviting = false);
        _showSnackBar('Impossible d\'ajouter un administrateur comme membre');
        return;
      }
      userToInvite = user;
    } else {
      userToInvite = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': email.split('@')[0],
        'email': email,
        'image': 'https://i.pravatar.cc/150?img=${email.hashCode % 70}',
        'role': 'collaborateur',
      };
    }

    setState(() {
      invitedMembers.add(userToInvite);
      _emailController.clear();
      _isInviting = false;
    });

    if (isNewUser) {
      _showSnackBar('Invitation envoyée à $email', isSuccess: true);
    } else {
      _showSnackBar('${userToInvite['name']} a été ajouté au projet', isSuccess: true);
    }
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

  // ✅ MODIFIÉ: Ajout du paramètre status
  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer un nom de projet');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _showSnackBar('Erreur: Utilisateur non connecté');
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final List<String> memberIds = invitedMembers
        .map((m) => m['id'] as String)
        .toList();

    // ✅ AJOUTÉ: Paramètre status='active'
    final project = await provider.createProject(
      title: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdBy: currentUserId,
      members: memberIds,
      color: projectColors[_selectedColorIndex].value.toRadixString(16),
      status: 'active',  // ✅ AJOUTÉ: Le nouveau projet est actif par défaut
    );

    if (project != null) {
      provider.addProjectLocally(project);
      _showSnackBar('Projet créé avec succès', isSuccess: true);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Erreur lors de la création du projet');
    }
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
              onPressed: _nameController.text.trim().isEmpty ? null : () => _createProject(),
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
            )
          ),
        ],
      ),
      body: _isLoadingMembers
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5BD6)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

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

                  const Text(
                    'Membres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                          image: NetworkImage(user['image'] ?? 'https://i.pravatar.cc/150?img=0'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (!(user['isActive'] ?? true))
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
                                  (user['name'] as String).split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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

                  if (_members.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Membres récents',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadMembers,
                          child: Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _members.where((m) => 
                        !invitedMembers.any((invited) => invited['email'] == m['email'])
                      ).map((member) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              invitedMembers.add(member);
                            });
                            _showSnackBar('${member['name']} ajouté', isSuccess: true);
                          },
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundImage: NetworkImage(member['image']),
                            ),
                            label: Text(member['name']),
                            backgroundColor: Colors.grey.shade100,
                            deleteIcon: const Icon(Icons.add, size: 18),
                            onDeleted: () {
                              setState(() {
                                invitedMembers.add(member);
                              });
                              _showSnackBar('${member['name']} ajouté', isSuccess: true);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ] else if (!_isLoadingMembers) ...[
                    Center(
                      child: Text(
                        'Aucun membre récent trouvé',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}