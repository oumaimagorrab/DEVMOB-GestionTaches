import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestiontaches/models/task.dart';
import 'package:provider/provider.dart';
import 'package:gestiontaches/providers/task_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajoutez ceci

class CreateTaskPage extends StatefulWidget {
  final String projectId;

  const CreateTaskPage({
    super.key,
    required this.projectId,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  String _selectedPriority = 'Medium';
  String? _selectedAssigneeId; // Changé de String à String?
  bool _notifyOnComplete = false;
  bool _isSaving = false;

  // ✅ Liste des membres récupérés de Firestore
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;

  final List<String> priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _loadMembers(); // Charger les membres au démarrage
    
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ MÉTHODE POUR CHARGER LES MEMBRES DEPUIS FIRESTORE
  Future<void> _loadMembers() async {
    try {
      // Option 1: Récupérer depuis la collection 'users'
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true) // Les plus récents d'abord
          .limit(10) // Limite à 10 membres récents
          .get();

      // Option 2: Si vous avez une sous-collection 'members' dans le projet
      // final QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
      //     .collection('projects')
      //     .doc(widget.projectId)
      //     .collection('members')
      //     .get();

      final List<Map<String, dynamic>> loadedMembers = usersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['displayName'] ?? data['name'] ?? 'Utilisateur',
          'image': data['photoURL'] ?? data['avatar'] ?? 'https://i.pravatar.cc/150?img=${doc.hashCode % 70}',
          'email': data['email'] ?? '',
        };
      }).toList();

      setState(() {
        _members = loadedMembers;
        _selectedAssigneeId = loadedMembers.isNotEmpty ? loadedMembers.first['id'] : null;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('❌ Erreur chargement membres: $e');
      setState(() {
        _isLoadingMembers = false;
      });
      // Fallback sur des données par défaut en cas d'erreur
      _members = [
        {'id': 'user1', 'name': 'Bob Durand', 'image': 'https://i.pravatar.cc/150?img=2', 'email': ''},
        {'id': 'user2', 'name': 'Alice Martin', 'image': 'https://i.pravatar.cc/150?img=1', 'email': ''},
      ];
      _selectedAssigneeId = 'user1';
    }
  }

  bool _isFormValid() {
    return _titleController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _selectedDate != null;
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
              primary: Color(0xFF6B4EFF),
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

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de tâche')),
      );
      return;
    }

    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un assigné')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final assigneeData = _members.firstWhere(
      (m) => m['id'] == _selectedAssigneeId,
      orElse: () => _members.first,
    );

    final taskProvider = context.read<TaskProvider>();

    print('🚀 Saving task dans projectId: ${widget.projectId}');
    print('👤 Assigné à: ${assigneeData['name']} (ID: $_selectedAssigneeId)');
    
    final task = await taskProvider.createTask(
      projectId: widget.projectId,
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _selectedPriority.toLowerCase(),
      createdBy: 'currentUserId',
      assigneeId: _selectedAssigneeId, // ✅ Envoie l'ID du membre
      // assigneeName: assigneeData['name'], // ✅ Ajoutez ce paramètre dans votre provider
      // assigneeImage: assigneeData['image'], // ✅ Ajoutez ce paramètre aussi
      dueDate: _selectedDate,
    );

    setState(() => _isSaving = false);

    if (task != null) {
      if (_notifyOnComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous serez notifié lorsque la tâche sera terminée'),
            backgroundColor: Color(0xFF6B4EFF),
          ),
        );
      }
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? 'Erreur lors de la création'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.orange;
    }
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
          'Nouvelle tâche',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: (_isSaving || !_isFormValid()) ? null : _saveTask,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                      ),
                    )
                  : Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isFormValid() 
                            ? const Color(0xFF6B4EFF)
                            : Colors.grey.shade400,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoadingMembers
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la tâche
                  _buildTextField(
                    controller: _titleController,
                    hintText: 'Nom de la tâche',
                  ),

                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Description de la tâche...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),

                  // Assigner à
                  const Text(
                    'Assigner à',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ Dropdown avec membres Firestore
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAssigneeId,
                        isExpanded: true,
                        hint: const Text('Sélectionner un membre'),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                        items: _members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member['id'],
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(member['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (member['email'].isNotEmpty)
                                        Text(
                                          member['email'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAssigneeId = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Échéance et Priorité
                  Row(
                    children: [
                      // Échéance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Échéance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate != null
                                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                          : 'Sélectionner',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _selectedDate != null
                                            ? Colors.black87
                                            : Colors.grey.shade400,
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
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Priorité
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priorité',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPriority,
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                                  items: priorities.map((priority) {
                                    return DropdownMenuItem<String>(
                                      value: priority,
                                      child: Text(
                                        priority,
                                        style: TextStyle(
                                          color: _getPriorityColor(priority),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPriority = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notification toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    size: 20,
                                    color: _notifyOnComplete 
                                        ? const Color(0xFF6B4EFF) 
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Me notifier quand cette tâche est terminée',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _notifyOnComplete 
                                            ? Colors.black87 
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_notifyOnComplete) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: Text(
                                    'Notification activée',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF6B4EFF),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Switch(
                          value: _notifyOnComplete,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnComplete = value;
                            });
                          },
                          activeColor: const Color(0xFF6B4EFF),
                          activeTrackColor: const Color(0xFF6B4EFF).withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}