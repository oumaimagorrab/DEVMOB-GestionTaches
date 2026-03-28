import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCompleteChanged;
  final bool showCheckbox;
  final bool showDescription;
  final bool isCompact;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onCompleteChanged,
    this.showCheckbox = true,
    this.showDescription = true,
    this.isCompact = false,
    this.onDelete,
  });

  /// Constructeur pour Kanban (sans checkbox, compact)
  const TaskTile.kanban({
    super.key,
    required this.task,
    required this.onTap,
    this.showCheckbox = false,
    this.showDescription = true,
    this.isCompact = true,
    this.onCompleteChanged,
    this.onDelete,
  });

  /// Constructeur pour liste (avec checkbox, complet)
  const TaskTile.list({
    super.key,
    required this.task,
    this.onTap,
    required this.onCompleteChanged,
    this.showCheckbox = true,
    this.showDescription = false,
    this.isCompact = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Mode Kanban : carte avec ombre
    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
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
            border: _isAssignedToMe 
                ? Border.all(color: const Color(0xFF6B4EFF), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge priorité
              _buildPriorityBadge(),
              const SizedBox(height: 10),
              // Titre
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              // Description (optionnel)
              if (showDescription && task.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
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
              // Footer avec avatar et date
              _buildFooter(),
            ],
          ),
        ),
      );
    }

    // Mode Liste : ListTile standard
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: showCheckbox
          ? Checkbox(
              value: task.isCompleted,
              onChanged: onCompleteChanged,
              activeColor: const Color(0xFF10B981),
            )
          : null,
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey.shade500 : Colors.black87,
        ),
      ),
      subtitle: showDescription && task.description != null
          ? Text(
              task.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Text(
              task.status,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge priorité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: task.priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                color: task.priorityColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  // Badge priorité (Kanban)
  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: task.priorityColor.withOpacity(0.12),
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
    );
  }

  // Footer avec avatar et date (Kanban)
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar assigné
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(
                task.assigneeId != null
                    ? 'https://i.pravatar.cc/150?img=${task.assigneeId.hashCode % 70}'
                    : 'https://i.pravatar.cc/150?img=11',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Date
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(task.dueDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Vérifier si la tâche est assignée à l'utilisateur courant
  bool get _isAssignedToMe {
    // À connecter avec AuthProvider si besoin
    return false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}