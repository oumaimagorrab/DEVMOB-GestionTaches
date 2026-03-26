import 'package:flutter/material.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'En cours',
                      style: TextStyle(
                        color: Colors.indigo[400],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.indigo[400],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Développer l\'API REST',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                'Créer les endpoints pour la gestion des utilisateurs, projets et tâches.\nImplémenter l\'authentification JWT et les permissions.',
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
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=11',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bob Durand',
                            style: TextStyle(
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
                          const Text(
                            '15 Mars 2024',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    
                    // Priority
                    _buildInfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Priorité',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'High',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
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
                      value: '8 Mars 2024',
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