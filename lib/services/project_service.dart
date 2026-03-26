class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final List<Map<String, dynamic>> projects = [];
  
  // Stockage des tâches par projet ID
  final Map<String, List<Map<String, dynamic>>> projectTasks = {};

  void addProject(Map<String, dynamic> project) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    project['id'] = id;
    projects.add(project);
    projectTasks[id] = [];
  }

  void deleteProject(int index) {
    if (index >= 0 && index < projects.length) {
      final id = projects[index]['id'];
      projects.removeAt(index);
      projectTasks.remove(id);
    }
  }

  List<Map<String, dynamic>> getTasks(String projectId) {
    return projectTasks[projectId] ?? [];
  }

  void addTask(String projectId, Map<String, dynamic> task) {
    if (!projectTasks.containsKey(projectId)) {
      projectTasks[projectId] = [];
    }
    projectTasks[projectId]!.add(task);
  }

  void updateTask(String projectId, int taskIndex, Map<String, dynamic> task) {
    if (projectTasks.containsKey(projectId) && 
        taskIndex >= 0 && 
        taskIndex < projectTasks[projectId]!.length) {
      projectTasks[projectId]![taskIndex] = task;
    }
  }
}