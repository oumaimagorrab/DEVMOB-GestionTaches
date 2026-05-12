import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project.dart';

class ProjectDetailPage2 extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailPage2({super.key, required this.project});

  @override
  State<ProjectDetailPage2> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Toutes';
  String? _creatorName;
  List<Map<String, dynamic>> _allTasks = [];

  final Map<String, Color> _priorityColors = {
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.grey,
  };

  final Map<String, String> _priorityLabels = {
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  @override
  void initState() {
    super.initState();
    _loadCreatorName();
  }

  // ─── SNACKBAR HELPERS (déclarés avant usage) ───
  void _showError(String message) {
    if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🔥 RÉSOUT LE NOM DU CRÉATEUR
  Future<void> _loadCreatorName() async {
    final createdBy = widget.project.createdBy;
    if (createdBy == null || createdBy.isEmpty) {
      setState(() => _creatorName = 'Inconnu');
      return;
    }

    // Si c'est déjà un nom (pas un UID), l'utiliser directement
    if (!createdBy.contains(RegExp(r'^[a-zA-Z0-9]{20,}$'))) {
      setState(() => _creatorName = createdBy);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(createdBy).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _creatorName = data['name'] ?? data['displayName'] ?? 'Admin';
        });
      } else {
        setState(() => _creatorName = 'Admin');
      }
    } catch (e) {
      setState(() => _creatorName = 'Admin');
    }
  }

  // 🔥 RÉCUPÈRE L'UID DU USER CONNECTÉ
  String? _getCurrentUserId() {
    return context.read<AppAuthProvider>().user?.id;
  }

  // 🔥 BASCULE LE STATUT D'UNE TÂCHE
  Future<void> _toggleTaskStatus(String taskId, String currentStatus) async {
    String newStatus;

    switch (currentStatus) {
      case 'todo':
        newStatus = 'in_progress';
        break;
      case 'in_progress':
        newStatus = 'done';
        break;
      default:
        newStatus = 'done';
    }

    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'done') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        updateData['isCompleted'] = true;
      } else {
        updateData['isCompleted'] = false;
      }

      await _firestore.collection('tasks').doc(taskId).update(updateData);

      // ✅ Utilisation directe des méthodes déclarées plus haut
      _showSuccess(newStatus == 'done' ? 'Tâche terminée !' : 'Tâche en cours');
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey.shade300;
      case 'in_progress':
        return const Color(0xFF6B4EFF);
      case 'done':
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _getCurrentUserId();
    final project = widget.project;
    final Color progressColor = _getProgressColor(project.status);
    final double progress = project.progress ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          project.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── CRÉATEUR ───
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: Icon(Icons.person, size: 16, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Créé par ${_creatorName ?? "Chargement..."}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── BARRE DE PROGRESSION ───
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── FILTRES ───
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Toutes'),
                    const SizedBox(width: 8),
                    _buildFilterChip('À faire'),
                    const SizedBox(width: 8),
                    _buildFilterChip('En cours'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terminées'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── LISTE DES TÂCHES ───
              if (userId == null)
                const Center(child: Text('Utilisateur non authentifié'))
              else
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('tasks')
                      .where('projectId', isEqualTo: project.id)
                      .where('assigneeId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      print('📊 Tasks trouvées: ${snapshot.data!.docs.length}');
                      for (var doc in snapshot.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        print('📝 ${d['title']} | assigneeId: ${d['assigneeId']} | status: ${d['status']}');
                      }
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6B4EFF)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'Erreur: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(userId);
                    }

                    _allTasks = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {'id': doc.id, ...data};
                    }).toList();

                    _allTasks.sort((a, b) {
                      final aDate = a['createdAt'] as Timestamp?;
                      final bDate = b['createdAt'] as Timestamp?;
                      if (aDate == null || bDate == null) return 0;
                      return bDate.compareTo(aDate);
                    });

                    return _buildTaskList(_allTasks);
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String userId) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucune tâche assignée',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Votre ID: $userId',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    final filtered = tasks.where((task) {
      final status = task['status'] ?? 'todo';
      switch (_selectedFilter) {
        case 'À faire':
          return status == 'todo';
        case 'En cours':
          return status == 'in_progress';
        case 'Terminées':
          return status == 'done';
        default:
          return true;
      }
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Aucune tâche dans cette catégorie',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((task) {
        final taskId = task['id'] as String;
        final status = task['status'] ?? 'todo';
        final priority = task['priority'] ?? 'low';
        final title = task['title'] ?? 'Sans titre';
        final dueDate = task['dueDate'] != null
            ? (task['dueDate'] as Timestamp).toDate()
            : null;

        return _buildTaskItem(
          taskId: taskId,
          title: title,
          status: status,
          priority: priority,
          dueDate: dueDate,
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String taskId,
    required String title,
    required String status,
    required String priority,
    required DateTime? dueDate,
  }) {
    final statusColor = _getStatusColor(status);
    final priorityColor = _priorityColors[priority] ?? Colors.grey;
    final priorityLabel = _priorityLabels[priority] ?? 'Low';
    final bool isDone = status == 'done';
    final bool isInProgress = status == 'in_progress';

    return GestureDetector(
      onTap: () => _toggleTaskStatus(taskId, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cercle de statut
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isInProgress ? statusColor : Colors.transparent,
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDone ? Colors.grey.shade400 : Colors.black87,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (dueDate != null) ...[
                        Text(
                          _formatDate(dueDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(Icons.person, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(String status) {
    switch (status) {
      case 'en_cours':
        return const Color(0xFF5B5BD6);
      case 'termine':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}