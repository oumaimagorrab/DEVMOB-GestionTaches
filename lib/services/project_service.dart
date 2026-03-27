class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final List<Map<String, dynamic>> projects = [];

  void addProject(Map<String, dynamic> project) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    project['id'] = id;
    projects.add(project);
  }

  void deleteProject(int index) {
    if (index >= 0 && index < projects.length) {
      projects.removeAt(index);
    }
  }

  Map<String, dynamic>? getProjectById(String id) {
    try {
      return projects.firstWhere((p) => p['id'] == id);
    } catch (e) {
      return null;
    }
  }
}