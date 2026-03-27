import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;
  final String projectTitle;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.projectTitle,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late String _currentStatus;
  late Map<String, dynamic> _task;

  final List<Map<String, String>> statusOptions = [
    {'value': 'todo', 'label': 'À faire', 'color': 'grey'},
    {'value': 'inprogress', 'label': 'En cours', 'color': 'indigo'},
    {'value': 'done', 'label': 'Terminé', 'color': 'green'},
  ];

  @override
  void initState() {
    super.initState();
    _task = Map.from(widget.task);
    _currentStatus = _task['status'] ?? 'todo';
    if (_task['isCompleted'] == true) {
      _currentStatus = 'done';
    }
  }

  String get _statusLabel {
    switch (_currentStatus) {
      case 'done':
        return 'Terminé';
      case 'inprogress':
        return 'En cours';
      case 'todo':
      default:
        return 'À faire';
    }
  }

  Color get _statusColor {
    switch (_currentStatus) {
      case 'done':
        return const Color(0xFF10B981);
      case 'inprogress':
        return const Color(0xFF6B4EFF);
      case 'todo':
      default:
        return Colors.grey.shade600;
    }
  }

  Color get _statusBgColor {
    switch (_currentStatus) {
      case 'done':
        return const Color(0xFFD1FAE5);
      case 'inprogress':
        return const Color(0xFFE8E4FF);
      case 'todo':
      default:
        return Colors.grey.shade100;
    }
  }

  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Changer le statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...statusOptions.map((status) {
                  final isSelected = _currentStatus == status['value'];
                  final color = status['color'] == 'green' 
                      ? const Color(0xFF10B981)
                      : status['color'] == 'indigo'
                          ? const Color(0xFF6B4EFF)
                          : Colors.grey.shade600;
                  
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      status['label']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check, color: color)
                        : null,
                    onTap: () {
                      setState(() {
                        _currentStatus = status['value']!;
                        _task['status'] = _currentStatus;
                        _task['isCompleted'] = _currentStatus == 'done';
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _task['priorityColor'] as Color? ?? Colors.orange;
    final priorityLabel = _task['priority'] ?? 'Medium';
    final assigneeName = _task['assigneeName'] ?? 'Non assigné';
    final assigneeImage = _task['assignee'] ?? 'https://i.pravatar.cc/150?img=11';
    final date = _task['date'] ?? 'Non définie';
    final createdAt = _task['createdAt'] != null
        ? DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.parse(_task['createdAt']))
        : 'Date inconnue';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {
              // TODO: Modifier la tâche
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black54),
            onPressed: () {
              // TODO: Supprimer la tâche
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer la tâche'),
                  content: const Text('Voulez-vous vraiment supprimer cette tâche ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, {'deleted': true});
                      },
                      child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Projet parent
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.projectTitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status Chip (cliquable)
              GestureDetector(
                onTap: _changeStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _statusColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title dynamique
              Text(
                _task['title'] ?? 'Sans titre',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description dynamique
              Text(
                _task['description']?.isNotEmpty == true
                    ? _task['description']
                    : 'Aucune description',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Assigned to
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Assigné à',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(assigneeImage),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assigneeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Modifier',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 24),
                    
                    // Due date
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Échéance',
                      child: Row(
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_currentStatus != 'done')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'En retard',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 24),
                    
                    // Priority dynamique
                    _buildInfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Priorité',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const Divider(height: 24),
                    
                    // Created date
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Créée le',
                      value: createdAt,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Comments Section
              Text(
                'Commentaires (3)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Comment 1
              _buildComment(
                name: 'Alice Martin',
                time: '2h',
                avatarUrl: 'https://i.pravatar.cc/150?img=5',
                comment: 'J\'ai terminé la première version, @Bob peux-tu relire ?',
                highlightName: true,
              ),
              
              const SizedBox(height: 16),
              
              // Comment 2
              _buildComment(
                name: 'Bob Durand',
                time: '1h',
                avatarUrl: 'https://i.pravatar.cc/150?img=11',
                comment: 'Super travail ! Quelques ajustements à faire sur @Claire ta partie',
                highlightName: true,
              ),
              
              const SizedBox(height: 16),
              
              // Comment 3
              _buildComment(
                name: 'Claire Petit',
                time: '30min',
                avatarUrl: 'https://i.pravatar.cc/150?img=9',
                comment: 'Ok je regarde ça maintenant',
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      
      // Bottom Comment Input
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=12',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.alternate_email,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_file,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: child ?? Text(
            value ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComment({
    required String name,
    required String time,
    required String avatarUrl,
    required String comment,
    bool highlightName = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(avatarUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  children: _buildCommentText(comment, highlightName),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildCommentText(String text, bool highlightMentions) {
    if (!highlightMentions) {
      return [TextSpan(text: text)];
    }
    
    final List<TextSpan> spans = [];
    final parts = text.split(RegExp(r'(@\w+)'));
    final matches = RegExp(r'@\w+').allMatches(text).map((m) => m.group(0)).toList();
    
    int matchIndex = 0;
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (matchIndex < matches.length && i < parts.length - 1) {
        spans.add(TextSpan(
          text: matches[matchIndex],
          style: TextStyle(
            color: Colors.indigo[400],
            fontWeight: FontWeight.w600,
          ),
        ));
        matchIndex++;
      }
    }
    
    return spans;
  }
}