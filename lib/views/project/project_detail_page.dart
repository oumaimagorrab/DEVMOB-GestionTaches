import 'package:flutter/material.dart';

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
      'title': 'Configuration serveur',
      'description': 'Mise en place de l\'environnement de production',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'date': '18 Mars',
      'comments': 2,
      'assignee': 'https://i.pravatar.cc/150?img=1',
      'status': 'todo',
    },
    {
      'title': 'Tests E2E',
      'description': 'Créer les scénarios de test automatisés',
      'priority': 'Low',
      'priorityColor': Colors.grey,
      'date': '22 Mars',
      'comments': 0,
      'assignee': 'https://i.pravatar.cc/150?img=2',
      'status': 'todo',
    },
    {
      'title': 'Développement API',
      'description': 'Endpoints authentification utilisateur',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '20 Mars',
      'comments': 1,
      'assignee': 'https://i.pravatar.cc/150?img=3',
      'status': 'inprogress',
    },
    {
      'title': 'Interface dashboard',
      'description': 'Composants graphiques et visualisation',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '25 Mars',
      'comments': 3,
      'assignee': 'https://i.pravatar.cc/150?img=4',
      'status': 'inprogress',
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
              widget.project['title'],
              style: const TextStyle(
                fontSize: 24,
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

          const SizedBox(height: 16),

          // Barre de progression
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.project['progress'],
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.project['progressColor'],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(widget.project['progress'] * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.project['progressColor'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6B4EFF),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF6B4EFF),
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Tâches'),
              Tab(text: 'Membres'),
              Tab(text: 'Infos'),
            ],
          ),

          const SizedBox(height: 8),

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

      // FAB
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4EFF), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4EFF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final todoTasks = tasks.where((t) => t['status'] == 'todo').toList();
    final inProgressTasks = tasks.where((t) => t['status'] == 'inprogress').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne TO DO
          _buildTaskColumn(
            title: 'TO DO',
            tasks: todoTasks,
            count: todoTasks.length,
            countColor: Colors.grey.shade600,
          ),

          const SizedBox(width: 12),

          // Colonne IN PROGRESS
          _buildTaskColumn(
            title: 'IN PROGRESS',
            tasks: inProgressTasks,
            count: inProgressTasks.length,
            countColor: const Color(0xFF6B4EFF),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskColumn({
    required String title,
    required List<Map<String, dynamic>> tasks,
    required int count,
    required Color countColor,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de colonne
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: countColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: countColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des tâches
          ...tasks.map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge priorité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          const SizedBox(height: 10),

          // Titre
          Text(
            task['title'],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            task['description'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar assigné
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(task['assignee']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Commentaires et date
              Row(
                children: [
                  if (task['comments'] > 0) ...[
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
                    task['date'],
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
    );
  }
}