import 'package:flutter/material.dart';
import 'package:gestiontaches/views/task/add_task_page.dart';
import 'package:gestiontaches/views/task/task_board_page.dart';
import 'package:gestiontaches/models/project.dart';
import 'package:provider/provider.dart';
import 'package:gestiontaches/providers/task_provider.dart';
import 'package:gestiontaches/models/task.dart';

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

  @override
  void initState() {
    super.initState();

    final taskProvider = context.read<TaskProvider>();
    taskProvider.initProjectTasksStream(widget.project.id);

    taskProvider.loadStats(widget.project.id);

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();


// Stats si tu veux les afficher
final stats = taskProvider.stats;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
            onPressed: () {},
          ),
        ],
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?img=1'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Créé par vous',
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
              const Tab(text: 'Membres'),
              const Tab(text: 'Infos'),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                const Center(child: Text('Membres')),
                const Center(child: Text('Infos')),
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
      onDismissed: (_) async{
          final taskProvider = context.read<TaskProvider>();
          await taskProvider.deleteTask(task.id);
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
            GestureDetector(
              onTap: () async {
                final taskProvider = context.read<TaskProvider>();

                await taskProvider.changeStatus(
                  task.id,
                  task.isCompleted ? 'todo' : 'done',
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (task.isCompleted)
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  border: Border.all(
                    color: (task.isCompleted)
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: (task.isCompleted)
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: (task.isCompleted)
                          ? Colors.grey.shade500
                          : Colors.black87,
                      decoration: (task.isCompleted)
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

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(task.assigneeId ?? 'https://i.pravatar.cc/150?img=11'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}