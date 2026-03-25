import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> tasks = [
    // TO DO (5 tâches)
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
      'title': 'Setup CI/CD',
      'description': 'Configuration GitHub Actions',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '25 Mars',
      'comments': 1,
      'assignee': 'https://i.pravatar.cc/150?img=3',
      'status': 'todo',
    },
    {
      'title': 'Documentation API',
      'description': 'Rédiger la documentation Swagger',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'date': '28 Mars',
      'comments': 0,
      'assignee': 'https://i.pravatar.cc/150?img=4',
      'status': 'todo',
    },
    {
      'title': 'Review code',
      'description': 'Revue des pull requests',
      'priority': 'Low',
      'priorityColor': Colors.grey,
      'date': '30 Mars',
      'comments': 3,
      'assignee': 'https://i.pravatar.cc/150?img=5',
      'status': 'todo',
    },
    // IN PROGRESS (3 tâches)
    {
      'title': 'Développer l\'API REST',
      'description': 'Endpoints pour la gestion des utilisateurs et projets',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '15 Mars',
      'comments': 5,
      'assignee': 'https://i.pravatar.cc/150?img=6',
      'status': 'inprogress',
    },
    {
      'title': 'Interface utilisateur',
      'description': 'Composants React pour le dashboard',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '16 Mars',
      'comments': 3,
      'assignee': 'https://i.pravatar.cc/150?img=7',
      'status': 'inprogress',
    },
    {
      'title': 'Authentification',
      'description': 'JWT et middleware de sécurité',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '20 Mars',
      'comments': 2,
      'assignee': 'https://i.pravatar.cc/150?img=8',
      'status': 'inprogress',
    },
    // DONE (8 tâches)
    {
      'title': 'Maquette Figma',
      'description': 'Design system et prototypes interactifs',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '10 Mars',
      'comments': 12,
      'assignee': 'https://i.pravatar.cc/150?img=9',
      'status': 'done',
    },
    {
      'title': 'Base de données',
      'description': 'Schéma et migrations Supabase',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'date': '12 Mars',
      'comments': 4,
      'assignee': 'https://i.pravatar.cc/150?img=10',
      'status': 'done',
    },
    {
      'title': 'Analyse besoins',
      'description': 'Spécifications fonctionnelles',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '5 Mars',
      'comments': 8,
      'assignee': 'https://i.pravatar.cc/150?img=11',
      'status': 'done',
    },
    {
      'title': 'Architecture',
      'description': 'Diagrammes et choix technologiques',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'date': '8 Mars',
      'comments': 2,
      'assignee': 'https://i.pravatar.cc/150?img=12',
      'status': 'done',
    },
    {
      'title': 'Setup projet',
      'description': 'Initialisation repo et structure',
      'priority': 'Low',
      'priorityColor': Colors.grey,
      'date': '1 Mars',
      'comments': 0,
      'assignee': 'https://i.pravatar.cc/150?img=13',
      'status': 'done',
    },
    {
      'title': 'Charte graphique',
      'description': 'Logo, couleurs et typographie',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'date': '3 Mars',
      'comments': 1,
      'assignee': 'https://i.pravatar.cc/150?img=14',
      'status': 'done',
    },
    {
      'title': 'User stories',
      'description': 'Définition des parcours utilisateurs',
      'priority': 'High',
      'priorityColor': Colors.red,
      'date': '6 Mars',
      'comments': 5,
      'assignee': 'https://i.pravatar.cc/150?img=15',
      'status': 'done',
    },
    {
      'title': 'Benchmark',
      'description': 'Analyse concurrentielle',
      'priority': 'Low',
      'priorityColor': Colors.grey,
      'date': '2 Mars',
      'comments': 0,
      'assignee': 'https://i.pravatar.cc/150?img=16',
      'status': 'done',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final todoTasks = tasks.where((t) => t['status'] == 'todo').toList();
    final inProgressTasks = tasks.where((t) => t['status'] == 'inprogress').toList();
    final doneTasks = tasks.where((t) => t['status'] == 'done').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.project?['title'] ?? 'Refonte E-commerce',
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
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
            onPressed: () {},
          ),
        ],
      ),
      // ✅ CORRECTION: SingleChildScrollView pour éviter l'overflow
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne TO DO
              _buildKanbanColumn(
                title: 'TO DO',
                count: todoTasks.length,
                countColor: Colors.grey.shade600,
                columnColor: const Color(0xFFF1F5F9),
                tasks: todoTasks,
              ),

              const SizedBox(width: 16),

              // Colonne IN PROGRESS
              _buildKanbanColumn(
                title: 'IN PROGRESS',
                count: inProgressTasks.length,
                countColor: const Color(0xFF6366F1),
                columnColor: const Color(0xFFEEF2FF),
                tasks: inProgressTasks,
              ),

              const SizedBox(width: 16),

              // Colonne DONE
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
    // ✅ CORRECTION: ConstrainedBox pour limiter la hauteur + SingleChildScrollView
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 180, // Hauteur max
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
            // Header
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

            // ✅ CORRECTION: Expanded + SingleChildScrollView pour les tâches
            Expanded(
              child: SingleChildScrollView(
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
    return Container(
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
          // Badge priorité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (task['priorityColor'] as Color).withOpacity(0.12),
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
                width: 32,
                height: 32,
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