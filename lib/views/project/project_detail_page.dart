import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/views/task/add_task_page.dart';
import 'package:gestiontaches/views/task/task_board_page.dart';
import 'package:gestiontaches/models/project.dart';
import 'package:provider/provider.dart';
import 'package:gestiontaches/providers/task_provider.dart';
import 'package:gestiontaches/models/task.dart';
import 'package:gestiontaches/views/task/task_detail_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🖼️ Cache des infos utilisateurs : Map<userId, {name, photoURL, email, role}>
  final Map<String, Map<String, dynamic>> _usersCache = {};
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();

    print('📂 ProjectDetailPage initState - projectId: ${widget.project.id}');
    
    final taskProvider = context.read<TaskProvider>();
    taskProvider.initProjectTasksStream(widget.project.id);
    taskProvider.loadStats(widget.project.id);

    // ✅ 2 onglets : Tâches et Membres
    _tabController = TabController(length: 2, vsync: this);

    // Charge tous les utilisateurs nécessaires (créateur + membres + assignés)
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔄 Charge tous les utilisateurs nécessaires pour cette page
  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);

    // Collecte tous les IDs uniques : créateur + membres du projet
    final Set<String> userIds = {};
    userIds.add(widget.project.createdBy); // Créateur
    userIds.addAll(widget.project.members); // Membres

    // Ajoute aussi les assignés des tâches si déjà chargés
    final taskProvider = context.read<TaskProvider>();
    for (final task in taskProvider.tasks) {
      if (task.assigneeId != null && task.assigneeId!.isNotEmpty) {
        userIds.add(task.assigneeId!);
      }
    }

    // Charge chaque utilisateur depuis Firestore
    for (final userId in userIds) {
      if (_usersCache.containsKey(userId)) continue;

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _usersCache[userId] = {
              'id': doc.id,
              'name': data['name'] ?? data['displayName'] ?? 'Utilisateur',
              'email': data['email'] ?? '',
              'photoURL': data['photoURL'] ?? '',
              'role': data['role'] ?? 'collaborateur',
              'isAdmin': data['role'] == 'admin' || data['isAdmin'] == true,
            };
          });
        }
      } catch (e) {
        print('❌ Erreur chargement utilisateur $userId: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoadingUsers = false);
    }
  }

  /// 🔄 Recharge les utilisateurs quand les tâches changent (pour les assignés)
  void _loadTaskAssignees(List<TaskModel> tasks) {
    final Set<String> newAssignees = {};
    for (final task in tasks) {
      if (task.assigneeId != null &&
          task.assigneeId!.isNotEmpty &&
          !_usersCache.containsKey(task.assigneeId!)) {
        newAssignees.add(task.assigneeId!);
      }
    }

    if (newAssignees.isEmpty) return;

    for (final userId in newAssignees) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _usersCache[userId] = {
              'id': doc.id,
              'name': data['name'] ?? data['displayName'] ?? 'Utilisateur',
              'email': data['email'] ?? '',
              'photoURL': data['photoURL'] ?? '',
              'role': data['role'] ?? 'collaborateur',
              'isAdmin': data['role'] == 'admin' || data['isAdmin'] == true,
            };
          });
        }
      }).catchError((e) {
        print('❌ Erreur chargement assigné $userId: $e');
      });
    }
  }

  /// 🖼️ Widget avatar avec photo de profil locale (même logique que TeamMembersPage)
  Widget _buildAvatar(String? userId, {double size = 36}) {
    // Récupère la photo depuis le cache
    final user = userId != null ? _usersCache[userId] : null;
    final photoURL = user?['photoURL'] as String? ?? '';

    final bool hasPhoto = photoURL.isNotEmpty && File(photoURL).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.file(
                File(photoURL),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400);
                },
              ),
            )
          : Icon(Icons.person, size: size * 0.5, color: Colors.grey.shade400),
    );
  }

  /// 📝 Récupère le nom d'un utilisateur depuis le cache
  String _getUserName(String? userId) {
    if (userId == null) return 'Inconnu';
    final user = _usersCache[userId];
    return user?['name'] as String? ?? 'Utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final stats = taskProvider.stats;

    // 🔄 Charge les assignés des nouvelles tâches
    if (taskProvider.tasks.isNotEmpty) {
      _loadTaskAssignees(taskProvider.tasks);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.project.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🖼️ Créateur avec vrai nom et photo depuis Firestore
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildAvatar(widget.project.createdBy, size: 28),
                const SizedBox(width: 8),
                Text(
                  _isLoadingUsers
                      ? 'Chargement...'
                      : 'Créé par ${_getUserName(widget.project.createdBy)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildProgressBar(),
          ),

          const SizedBox(height: 24),

          // ✅ 2 onglets : Tâches et Membres
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6B4EFF),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF6B4EFF),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'Tâches (${taskProvider.tasks.length})'),
              Tab(text: 'Membres (${widget.project.members.length})'),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final allTasks = context.watch<TaskProvider>().tasks;
    final total = allTasks.length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).toInt()}% (${completed}/${total})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4EFF),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Onglet Membres avec photos locales
  Widget _buildMembersTab() {
    final members = widget.project.members;

    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
        ),
      );
    }

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucun membre',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final memberId = members[index];
        final member = _usersCache[memberId];

        if (member == null) {
          return const SizedBox.shrink();
        }

        final bool isAdmin = member['isAdmin'] as bool;
        final String photoURL = member['photoURL'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildAvatar(memberId, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member['email'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFF6B4EFF).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAdmin ? 'Admin' : 'Membre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAdmin ? const Color(0xFF6B4EFF) : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.tasks;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: allTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune tâche',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: allTasks.length,
                    itemBuilder: (context, index) {
                      final task = allTasks[index];
                      return _buildTaskItem(task);
                    },
                  ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskPage(projectId: widget.project.id),
                  ),
                );

                if (result == true && mounted) {
                  print('🔄 Rafraîchissement du stream après création');
                  final taskProvider = context.read<TaskProvider>();
                  taskProvider.initProjectTasksStream(widget.project.id);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tâche créée avec succès'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Ajouter une tâche',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KanbanBoardPage(project: widget.project),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B4EFF), Color(0xFF5B5BD6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.view_kanban_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voir le tableau des tâches',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Voir TO DO • IN PROGRESS • DONE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final taskProvider = context.read<TaskProvider>();
        await taskProvider.deleteTask(task.id);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(
                task: task,
                projectTitle: widget.project.title,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted
                            ? Colors.grey.shade500
                            : Colors.black87,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          task.dueDate != null
                              ? '${task.dueDate!.day}/${task.dueDate!.month}'
                              : '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (task.priorityColor as Color?)?.withOpacity(0.1) ??
                                Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: task.priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🖼️ Avatar assigné avec photo locale depuis le cache
              _buildAvatar(task.assigneeId, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}