import 'package:flutter/material.dart';
import 'package:gestiontaches/services/task_service.dart';
import 'package:gestiontaches/views/task/task_detail_page.dart';

class KanbanBoardPage extends StatefulWidget {
  final Map<String, dynamic>? project;

  const KanbanBoardPage({
    super.key,
    this.project,
  });

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> get tasks => 
      _taskService.getTasks(widget.project?['id'] ?? '');

  @override
  Widget build(BuildContext context) {
    final todoTasks = tasks.where((t) => 
        t['status'] == 'todo' && (t['isCompleted'] != true)).toList();
    final inProgressTasks = tasks.where((t) => t['status'] == 'inprogress').toList();
    final doneTasks = tasks.where((t) => 
        t['isCompleted'] == true || t['status'] == 'done').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.project?['title'] ?? 'Tableau Kanban',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKanbanColumn(
                title: 'TO DO',
                count: todoTasks.length,
                countColor: Colors.grey.shade600,
                columnColor: const Color(0xFFF1F5F9),
                tasks: todoTasks,
              ),
              const SizedBox(width: 16),
              _buildKanbanColumn(
                title: 'IN PROGRESS',
                count: inProgressTasks.length,
                countColor: const Color(0xFF6366F1),
                columnColor: const Color(0xFFEEF2FF),
                tasks: inProgressTasks,
              ),
              const SizedBox(width: 16),
              _buildKanbanColumn(
                title: 'DONE',
                count: doneTasks.length,
                countColor: const Color(0xFF10B981),
                columnColor: const Color(0xFFF0FDF4),
                tasks: doneTasks,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanColumn({
    required String title,
    required int count,
    required Color countColor,
    required Color columnColor,
    required List<Map<String, dynamic>> tasks,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 180,
        maxWidth: 300,
      ),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: columnColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: countColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: countColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune tâche',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: tasks.map((task) => _buildTaskCard(task)).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    // Déterminer le statut textuel
    String statusText;
    if (task['isCompleted'] == true || task['status'] == 'done') {
      statusText = 'Terminé';
    } else if (task['status'] == 'inprogress') {
      statusText = 'En cours';
    } else {
      statusText = 'À faire';
    }

    return GestureDetector(
      onTap: () {
        // Navigation vers le détail de la tâche
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(
              task: task,
              projectTitle: widget.project?['title'] ?? 'Projet',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (task['priorityColor'] as Color?)?.withOpacity(0.12) ??
                       Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task['priority'] ?? 'Medium',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: task['priorityColor'] ?? Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              task['title'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (task['description']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(
                task['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(task['assignee'] ?? 'https://i.pravatar.cc/150?img=11'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if ((task['comments'] ?? 0) > 0) ...[
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task['comments'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task['date'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}