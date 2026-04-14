import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestiontaches/models/user.dart'; 
import 'package:gestiontaches/providers/project_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ AJOUTÉ

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
 bool _isLoadingMembers = true; // ✅ AJOUTÉ

 final List<Color> projectColors = [
   const Color(0xFF5B5BD6),
   const Color(0xFFA855F7),
   const Color(0xFF10B981),
   const Color(0xFFF59E0B),
   const Color(0xFFEF4444),
   const Color(0xFF3B82F6),
 ];

 // ✅ SUPPRIMÉ : Base de données simulée
 // final Map<String, UserModel> registeredUsers = {...};

 // ✅ AJOUTÉ : Liste des membres récupérés de Firestore
 List<UserModel> _recentMembers = [];
 List<UserModel> _allUsers = []; // Tous les utilisateurs pour la recherche

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
   // ✅ Charger les membres depuis Firestore au lieu des données simulées
   _loadMembersFromFirestore();
 }

 @override
 void dispose() {
   _nameController.dispose();
   _descriptionController.dispose();
   _emailController.dispose();
   super.dispose();
 }

 // ✅ NOUVELLE MÉTHODE : Charger les membres depuis Firestore
 Future<void> _loadMembersFromFirestore() async {
   try {
     setState(() => _isLoadingMembers = true);

     // Récupérer les utilisateurs les plus récents depuis Firestore
     final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
         .collection('users')
         .orderBy('createdAt', descending: true) // Les plus récents d'abord
         .limit(10) // Limiter à 10 membres récents
         .get();

     final List<UserModel> loadedUsers = usersSnapshot.docs.map((doc) {
       final data = doc.data() as Map<String, dynamic>;
       return UserModel(
         id: doc.id,
         name: data['displayName'] ?? data['name'] ?? 'Utilisateur',
         email: data['email'] ?? '',
         photoURL: data['photoURL'] ?? data['avatar'] ?? 'https://i.pravatar.cc/150?img=${doc.hashCode % 70}',
         createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
         isActive: data['isActive'] ?? true,
       );
     }).toList();

     setState(() {
       _allUsers = loadedUsers;
       // Filtrer pour exclure l'utilisateur courant de la liste des récents
       final currentUserId = FirebaseAuth.instance.currentUser?.uid;
       _recentMembers = loadedUsers
           .where((u) => u.id != currentUserId)
           .take(5) // Prendre les 5 premiers (excluant l'utilisateur courant)
           .toList();
       _isLoadingMembers = false;
     });
   } catch (e) {
     print('❌ Erreur chargement membres Firestore: $e');
     setState(() => _isLoadingMembers = false);
     
     // Fallback sur une liste vide ou données par défaut si erreur
     _showSnackBar('Erreur lors du chargement des membres', isSuccess: false);
   }
 }

 // ✅ NOUVELLE MÉTHODE : Rechercher un utilisateur par email dans Firestore
 Future<UserModel?> _findUserByEmail(String email) async {
   try {
     // Chercher dans la liste déjà chargée d'abord
     final existingUser = _allUsers.firstWhere(
       (u) => u.email.toLowerCase() == email.toLowerCase(),
       orElse: () => null as UserModel, // Hack pour éviter l'exception
     );
     
     if (existingUser != null) return existingUser;

     // Si pas trouvé, faire une requête Firestore
     final QuerySnapshot result = await FirebaseFirestore.instance
         .collection('users')
         .where('email', isEqualTo: email.toLowerCase())
         .limit(1)
         .get();

     if (result.docs.isNotEmpty) {
       final doc = result.docs.first;
       final data = doc.data() as Map<String, dynamic>;
       return UserModel(
         id: doc.id,
         name: data['displayName'] ?? data['name'] ?? email.split('@')[0],
         email: email,
         photoURL: data['photoURL'] ?? data['avatar'] ?? 'https://i.pravatar.cc/150?img=${email.hashCode % 70}',
         createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
         isActive: data['isActive'] ?? true,
       );
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

   // ✅ MODIFIÉ : Rechercher dans Firestore au lieu de registeredUsers
   final user = await _findUserByEmail(email);
   bool isNewUser = user == null;

   UserModel userToInvite;
   if (user != null) {
     // Utilisateur existant trouvé dans Firestore
     userToInvite = user;
   } else {
     // Créer un nouvel utilisateur non enregistré
     userToInvite = UserModel(
       id: DateTime.now().millisecondsSinceEpoch.toString(),
       name: email.split('@')[0],
       email: email,
       photoURL: 'https://i.pravatar.cc/150?img=${email.hashCode % 70}',
       createdAt: DateTime.now(),
       isActive: false,
     );
   }

   setState(() {
     invitedMembers.add(userToInvite);
     _emailController.clear();
     _isInviting = false;
   });

   // Afficher le message approprié
   if (isNewUser) {
     _showSnackBar('Invitation envoyée à $email', isSuccess: true);
     _sendEmailInvitation(email);
   } else {
     _showSnackBar('${userToInvite.name} a été ajouté au projet', isSuccess: true);
   }
 }

 // Simuler l'envoi d'email
 void _sendEmailInvitation(String email) {
   print('📧 Envoi d\'invitation à: $email');
   print('📧 Sujet: Invitation à rejoindre le projet "${_nameController.text}"');
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
   final members = invitedMembers.map((m) => m.id).toList();

   final project = await provider.createProject(
     title: _nameController.text.trim(),
     description: _descriptionController.text.trim().isEmpty
         ? null
         : _descriptionController.text.trim(),
     createdBy: currentUserId,
     members: members,
     color: projectColors[_selectedColorIndex].value.toRadixString(16),
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
                 
                 // ✅ MODIFIÉ : Membres récents depuis Firestore
                 if (_recentMembers.isNotEmpty) ...[
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
                       // Bouton pour rafraîchir
                       GestureDetector(
                         onTap: _loadMembersFromFirestore,
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
                     children: _recentMembers.where((m) => 
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
                 ] else if (!_isLoadingMembers) ...[
                   // Message si aucun membre récent
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