import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String _selectedAssignee = '';
  bool _notifyOnComplete = false;

  final List<Map<String, dynamic>> assignees = [
    {'name': 'Bob Durand', 'image': 'https://i.pravatar.cc/150?img=2'},
    {'name': 'Alice Martin', 'image': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'Claire Petit', 'image': 'https://i.pravatar.cc/150?img=3'},
  ];

  final List<String> priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedAssignee = assignees.first['name'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  void _saveTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de tâche')),
      );
      return;
    }

    final assigneeData = assignees.firstWhere(
      (a) => a['name'] == _selectedAssignee,
      orElse: () => assignees.first,
    );

    final newTask = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'priority': _selectedPriority,
      'priorityColor': _getPriorityColor(_selectedPriority),
      'date': _selectedDate != null 
          ? DateFormat('d MMM').format(_selectedDate!)
          : DateFormat('d MMM').format(DateTime.now()),
      'comments': 0,
      'assignee': assigneeData['image'],
      'assigneeName': assigneeData['name'],
      'status': 'todo',
      'isCompleted': false,
      'createdAt': DateTime.now().toIso8601String(),
      'notifyOnComplete': _notifyOnComplete, // ✅ UTILISÉ ICI
    };

    // Afficher confirmation si notification activée
    if (_notifyOnComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous serez notifié lorsque la tâche sera terminée'),
          backgroundColor: Color(0xFF6B4EFF),
        ),
      );
    }

    Navigator.pop(context, newTask);
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
            child: ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 14,
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

            // Dropdown assigné
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAssignee,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                  items: assignees.map((assignee) {
                    return DropdownMenuItem<String>(
                      value: assignee['name'],
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(assignee['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            assignee['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAssignee = value!;
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

            // ✅ NOTIFICATION TOGGLE - Maintenant utilisé
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