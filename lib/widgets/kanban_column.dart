import 'package:flutter/material.dart';
import '../models/task.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color headerColor;
  final List<TaskModel> tasks;
  final Function(TaskModel)? onTaskDrop;
  final Widget Function(TaskModel) taskBuilder;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.headerColor,
    required this.tasks,
    this.onTaskDrop,
    required this.taskBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 200,
      ),
      decoration: BoxDecoration(
        color: color,
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
                    color: headerColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: headerColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des tâches
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
                      children: tasks.map((task) => taskBuilder(task)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}