import 'package:flutter/material.dart';
import 'package:gestiontaches/models/project.dart';
import 'package:gestiontaches/providers/project_provider.dart';
import 'package:provider/provider.dart';

class EditProjectPage extends StatefulWidget {
  final ProjectModel project;

  const EditProjectPage({super.key, required this.project});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late int _selectedColorIndex;

  final List<Map<String, dynamic>> projectColors = [
    {'color': const Color(0xFF5B5BD6), 'hex': 'FF5B5BD6'},
    {'color': const Color(0xFFA855F7), 'hex': 'FFA855F7'},
    {'color': const Color(0xFF10B981), 'hex': 'FF10B981'},
    {'color': const Color(0xFFF59E0B), 'hex': 'FFF59E0B'},
    {'color': const Color(0xFFEF4444), 'hex': 'FFEF4444'},
    {'color': const Color(0xFF3B82F6), 'hex': 'FF3B82F6'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(text: widget.project.description ?? '');
    
    // Trouve l'index de la couleur actuelle
    _selectedColorIndex = 0;
    for (int i = 0; i < projectColors.length; i++) {
      if (projectColors[i]['hex'] == widget.project.color) {
        _selectedColorIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProject() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer un nom de projet');
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    // TODO: Ajoute une méthode updateProject dans ton ProjectProvider
    // provider.updateProject(
    //   projectId: widget.project.id,
    //   title: _nameController.text.trim(),
    //   description: _descriptionController.text.trim(),
    //   color: projectColors[_selectedColorIndex]['hex'],
    // );

    _showSnackBar('Projet modifié avec succès', isSuccess: true);
    Navigator.pop(context, true);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          'Modifier le projet',
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
              onPressed: _nameController.text.trim().isEmpty ? null : _updateProject,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B5BD6),
                disabledForegroundColor: Colors.grey.shade400,
              ),
              child: const Text(
                'Enregistrer',
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
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
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
                final color = projectColors[index]['color'] as Color;
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
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.4),
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
          ],
        ),
      ),
    );
  }
}