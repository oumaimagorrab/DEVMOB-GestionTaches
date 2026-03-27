class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // Stockage des tâches par projet ID
  final Map<String, List<Map<String, dynamic>>> _tasks = {};

  List<Map<String, dynamic>> getTasks(String projectId) {
    return _tasks[projectId] ?? [];
  }

  void addTask(String projectId, Map<String, dynamic> task) {
    if (!_tasks.containsKey(projectId)) {
      _tasks[projectId] = [];
    }
    
    // Générer un ID unique pour la tâche
    task['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    task['projectId'] = projectId;
    
    _tasks[projectId]!.add(task);
  }

  void deleteTask(String projectId, String taskId) {
    if (_tasks.containsKey(projectId)) {
      _tasks[projectId]!.removeWhere((t) => t['id'] == taskId);
    }
  }

  void updateTask(String projectId, String taskId, Map<String, dynamic> updatedTask) {
    if (_tasks.containsKey(projectId)) {
      final index = _tasks[projectId]!.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        _tasks[projectId]![index] = {..._tasks[projectId]![index], ...updatedTask};
      }
    }
  }

  void toggleTaskComplete(String projectId, String taskId) {
    if (_tasks.containsKey(projectId)) {
      final task = _tasks[projectId]!.firstWhere((t) => t['id'] == taskId);
      task['isCompleted'] = !(task['isCompleted'] ?? false);
      task['status'] = task['isCompleted'] ? 'done' : 'todo';
    }
  }
}