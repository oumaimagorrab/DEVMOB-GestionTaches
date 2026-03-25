import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateTaskPage extends StatefulWidget {
  final String projectId;
  final Function(Map<String, dynamic>)? onTaskCreated;

  const CreateTaskPage({
    super.key,
    required this.projectId,
    this.onTaskCreated,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  String _selectedPriority = '';
  String _selectedAssignee = 'Bob Durand';
  bool _notifyOnComplete = false;

  final List<Map<String, dynamic>> assignees = [
    {'name': 'Bob Durand', 'image': 'https://i.pravatar.cc/150?img=2'},
    {'name': 'Alice Martin', 'image': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'Claire Petit', 'image': 'https://i.pravatar.cc/150?img=3'},
  ];

  final List<String> priorities = ['Low', 'Medium', 'High'];

  final List<Map<String, dynamic>> attachments = [
    {'name': 'design-mockup.fig', 'size': '2.4 MB', 'icon': Icons.insert_drive_file},
    {'name': 'requirements.pdf', 'size': '1.1 MB', 'icon': Icons.picture_as_pdf},
  ];

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

    final newTask = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'priority': _selectedPriority.isEmpty ? 'Medium' : _selectedPriority,
      'priorityColor': _getPriorityColor(_selectedPriority),
      'date': _selectedDate != null 
          ? DateFormat('d MMM').format(_selectedDate!)
          : '${DateTime.now().day} ${_getMonth(DateTime.now().month)}',
      'comments': 0,
      'assignee': assignees.firstWhere((a) => a['name'] == _selectedAssignee)['image'],
      'status': 'todo',
    };

    widget.onTaskCreated?.call(newTask);
    Navigator.pop(context);
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

  String _getMonth(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
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
        centerTitle: true,
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
                                    : '',
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
                            value: _selectedPriority.isEmpty ? null : _selectedPriority,
                            isExpanded: true,
                            hint: Text(
                              '',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
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

            // Pièces jointes
            const Text(
              'Pièces jointes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Zone de drop
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.grey.shade500,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquer ou déposer des fichiers',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, images, jusqu\'à 10MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des fichiers joints
            ...attachments.map((file) => _buildAttachmentItem(file)),

            const SizedBox(height: 24),

            // Notification toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Me notifier quand cette tâche est terminée',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
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
                ),
              ],
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

  Widget _buildAttachmentItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            file['icon'] as IconData,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  file['size'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}