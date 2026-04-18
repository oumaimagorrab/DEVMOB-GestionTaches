import 'package:flutter/foundation.dart';
import 'package:gestiontaches/models/project.dart';
import 'package:gestiontaches/services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<ProjectModel> _projects = [];
  List<ProjectModel> _userProjects = [];
  List<ProjectModel> _activeProjects = [];  // ✅ NOUVEAU: projets actifs seulement
  ProjectModel? _selectedProject;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get userProjects => _userProjects;
  List<ProjectModel> get activeProjects => _activeProjects;  // ✅ NOUVEAU
  ProjectModel? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream subscription
  Stream<List<ProjectModel>>? _projectsStream;
  Stream<List<ProjectModel>>? _userProjectsStream;
  Stream<List<ProjectModel>>? _activeProjectsStream;  // ✅ NOUVEAU

  // Initialiser les streams
  void initProjectsStream() {
    _projectsStream = _projectService.getProjects();
    _projectsStream?.listen((projects) {
      _projects = projects;
      notifyListeners();
    });
  }

  // ✅ NOUVELLE MÉTHODE: Stream des projets actifs seulement
  void initActiveProjectsStream() {
    _activeProjectsStream = _projectService.getActiveProjects();
    _activeProjectsStream?.listen((projects) {
      _activeProjects = projects;
      notifyListeners();
    });
  }

  void initUserProjectsStream(String userId) {
    _userProjectsStream = _projectService.getUserProjects(userId);
    _userProjectsStream?.listen((projects) {
      _userProjects = projects;
      _projects = projects;
      notifyListeners();
    });
  }

  // ✅ CRÉER un projet avec status
  Future<ProjectModel?> createProject({
    required String title,
    String? description,
    required String createdBy,
    List<String> members = const [],
    String? color,
    String status = 'active',  // ✅ AJOUTÉ
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final project = await _projectService.createProject(
        title: title,
        description: description,
        createdBy: createdBy,
        members: members,
        color: color,
        status: status,  // ✅ AJOUTÉ
      );

      // Ajouter le créateur comme membre si pas déjà inclus
      if (!project.members.contains(createdBy)) {
        await _projectService.addMember(project.id, createdBy);
      }

      _setLoading(false);
      return project;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Sélectionner un projet
  void selectProject(ProjectModel project) {
    _selectedProject = project;
    notifyListeners();
  }

  void clearSelectedProject() {
    _selectedProject = null;
    notifyListeners();
  }

  // ✅ METTRE À JOUR un projet (avec status optionnel)
  Future<bool> updateProject(
    String projectId, {
    String? title,
    String? description,
    List<String>? members,
    String? color,
    String? status,  // ✅ AJOUTÉ
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _projectService.updateProject(
        projectId,
        title: title,
        description: description,
        members: members,
        color: color,
        status: status,  // ✅ AJOUTÉ
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Changer le status d'un projet
  Future<bool> updateProjectStatus(String projectId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      await _projectService.updateProjectStatus(projectId, status);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Archiver un projet
  Future<bool> archiveProject(String projectId) async {
    return updateProjectStatus(projectId, 'archived');
  }

  // ✅ NOUVELLE MÉTHODE: Marquer comme terminé
  Future<bool> completeProject(String projectId) async {
    return updateProjectStatus(projectId, 'completed');
  }

  // ✅ NOUVELLE MÉTHODE: Réactiver un projet
  Future<bool> reactivateProject(String projectId) async {
    return updateProjectStatus(projectId, 'active');
  }

  // Ajouter un membre
  Future<bool> addMember(String projectId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _projectService.addMember(projectId, userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Retirer un membre
  Future<bool> removeMember(String projectId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _projectService.removeMember(projectId, userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Supprimer un projet
  Future<bool> deleteProject(String projectId) async {
    _setLoading(true);
    _clearError();

    try {
      await _projectService.deleteProject(projectId);
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Rechercher des projets
  Future<void> searchProjects(String query) async {
    _setLoading(true);
    _clearError();

    try {
      final results = await _projectService.searchProjects(query);
      _projects = results;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Obtenir un projet par ID depuis la liste locale
  ProjectModel? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vérifier si un utilisateur est membre d'un projet
  bool isUserMember(String projectId, String userId) {
    final project = getProjectById(projectId);
    return project?.members.contains(userId) ?? false;
  }

  @override
  void dispose() {
    // Nettoyer les streams si nécessaire
    super.dispose();
  }

  void addProjectLocally(ProjectModel project) {
    _projects.add(project);
    notifyListeners();
  }
}