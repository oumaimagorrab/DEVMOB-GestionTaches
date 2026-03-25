import 'package:flutter/material.dart';
import 'package:gestiontaches/views/task/add_task_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> project;

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

  final List<Map<String, dynamic>> tasks = [
    {
      'title': 'Créer la maquette de l\'interface',
      'date': '12 Mars',
      'priority': 'High',
      'priorityColor': Colors.red,
      'status': 'done',
      'assignee': 'https://i.pravatar.cc/150?img=1',
      'isCompleted': true,
    },
    {
      'title': 'Développer l\'API REST',
      'date': '15 Mars',
      'priority': 'High',
      'priorityColor': Colors.red,
      'status': 'inprogress',
      'assignee': 'https://i.pravatar.cc/150?img=2',
      'isCompleted': false,
    },
    {
      'title': 'Rédiger la documentation',
      'date': '18 Mars',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'status': 'todo',
      'assignee': 'https://i.pravatar.cc/150?img=3',
      'isCompleted': false,
    },
    {
      'title': 'Tests unitaires',
      'date': '20 Mars',
      'priority': 'Low',
      'priorityColor': Colors.grey,
      'status': 'todo',
      'assignee': 'https://i.pravatar.cc/150?img=4',
      'isCompleted': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          // Titre du projet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.project['title'] ?? 'Refonte Site E-commerce',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Créé par
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
                  'Créé par Alice Martin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Barre de progression
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                // Pourcentage centré sur la barre
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B4EFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Onglets
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
            tabs: const [
              Tab(text: 'Tâches'),
              Tab(text: 'Membres'),
              Tab(text: 'Infos'),
            ],
          ),

          const SizedBox(height: 16),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet Tâches
                _buildTasksTab(),
                // Onglet Membres
                const Center(child: Text('Membres')),
                // Onglet Infos
                const Center(child: Text('Infos')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Liste des tâches
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskItem(task);
              },
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Bouton Ajouter une tâche
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskPage(
                      projectId: widget.project['id'] ?? '1',
                      onTaskCreated: (newTask) {
                        setState(() {
                          tasks.add(newTask);
                        });
                      },
                    ),
                  ),
                );
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

          // ✅ Bouton Voir le tableau des tâches
          GestureDetector(
            onTap: () {
              // Navigation vers la vue Kanban
              Navigator.pushNamed(context, '/kanban', arguments: widget.project);
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

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Indicateur de statut (cercle)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task['isCompleted']
                  ? const Color(0xFF10B981)
                  : task['status'] == 'inprogress'
                      ? const Color(0xFF6B4EFF)
                      : Colors.transparent,
              border: Border.all(
                color: task['isCompleted']
                    ? const Color(0xFF10B981)
                    : task['status'] == 'inprogress'
                        ? const Color(0xFF6B4EFF)
                        : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: task['isCompleted']
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : task['status'] == 'inprogress'
                    ? const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
          ),

          const SizedBox(width: 16),

          // Contenu de la tâche
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: task['isCompleted']
                        ? Colors.grey.shade500
                        : Colors.black87,
                    decoration: task['isCompleted']
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      task['date'],
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
                        color: (task['priorityColor'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task['priority'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task['priorityColor'],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Avatar assigné
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(task['assignee']),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}