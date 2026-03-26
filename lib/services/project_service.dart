class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final List<Map<String, dynamic>> projects = [];

  void addProject(Map<String, dynamic> project) {
    projects.add(project);
  }

  void deleteProject(int index) {
    if (index >= 0 && index < projects.length) {
      projects.removeAt(index);
    }
  }

  List<Map<String, dynamic>> getProjects() {
    return List.unmodifiable(projects);
  }
}