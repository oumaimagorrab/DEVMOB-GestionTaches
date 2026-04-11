  import 'dart:async';
  import 'package:flutter/foundation.dart';
  import 'package:gestiontaches/models/task.dart';
  import 'package:gestiontaches/services/task_service.dart';

  class TaskProvider extends ChangeNotifier {
    final TaskService _taskService = TaskService();

    List<TaskModel> _tasks = [];
    List<TaskModel> _userTasks = [];
    TaskModel? _selectedTask;
    Map<String, int> _stats = {};
    bool _isLoading = false;
    String? _error;

    // Getters
    List<TaskModel> get tasks => _tasks;
    List<TaskModel> get userTasks => _userTasks;
    TaskModel? get selectedTask => _selectedTask;
    Map<String, int> get stats => _stats;
    bool get isLoading => _isLoading;
    String? get error => _error;

    // Getters filtrés
    List<TaskModel> get todoTasks => _tasks.where((t) => t.status == 'todo').toList();
    List<TaskModel> get inProgressTasks => _tasks.where((t) => t.status == 'inprogress').toList();
    List<TaskModel> get doneTasks => _tasks.where((t) => t.status == 'done').toList();
    List<TaskModel> get highPriorityTasks => _tasks.where((t) => t.priority == 'high').toList();

    // Streams
    Stream<List<TaskModel>>? _tasksStream;
    Stream<List<TaskModel>>? _userTasksStream;
    
    // Stream Subscriptions
    StreamSubscription<List<TaskModel>>? _tasksSubscription;
    StreamSubscription<List<TaskModel>>? _userTasksSubscription;

    void initProjectTasksStream(String projectId) {
      print('🔄 Initialisation stream pour projectId: $projectId');
      
      // Annuler l'ancienne subscription
      _tasksSubscription?.cancel();
      
      _tasksStream = _taskService.getProjectTasks(projectId);
      _tasksSubscription = _tasksStream?.listen(
        (tasks) {
          print('📨 Provider reçu ${tasks.length} tâches');
          _tasks = tasks;
          notifyListeners();
        },
        onError: (error) {
          print('❌ Erreur stream: $error');
          _setError(error.toString());
        },
      );
    }

    void initUserTasksStream(String userId) {
      // Annuler l'ancienne subscription
      _userTasksSubscription?.cancel();
      
      _userTasksStream = _taskService.getUserTasks(userId);
      _userTasksSubscription = _userTasksStream?.listen((tasks) {
        _userTasks = tasks;
        notifyListeners();
      });
    }

    // Créer une tâche
    Future<TaskModel?> createTask({
      required String projectId,
      required String title,
      String? description,
      String priority = 'medium',
      required String createdBy,
      String? assigneeId,
      DateTime? dueDate,
    }) async {
      _setLoading(true);
      _clearError();

      try {
        final task = await _taskService.createTask(
          projectId: projectId,
          title: title,
          description: description,
          priority: priority,
          createdBy: createdBy,
          assigneeId: assigneeId,
          dueDate: dueDate,
        );
        _setLoading(false);
        return task;
      } catch (e) {
        _setError(e.toString());
        return null;
      }
    }

    // Sélectionner une tâche
    void selectTask(TaskModel task) {
      _selectedTask = task;
      notifyListeners();
    }

    void clearSelectedTask() {
      _selectedTask = null;
      notifyListeners();
    }

    // Changer le statut
    Future<bool> changeStatus(String taskId, String newStatus) async {
      _setLoading(true);
      try {
        await _taskService.updateStatus(taskId, newStatus);
        _setLoading(false);
        return true;
      } catch (e) {
        _setError(e.toString());
        return false;
      }
    }

    // Assigner
    Future<bool> assignTask(String taskId, String? userId) async {
      _setLoading(true);
      try {
        await _taskService.assignTask(taskId, userId);
        _setLoading(false);
        return true;
      } catch (e) {
        _setError(e.toString());
        return false;
      }
    }

    // Mettre à jour
    Future<bool> updateTask(
      String taskId, {
      String? title,
      String? description,
      String? status,
      String? priority,
      String? assigneeId,
      DateTime? dueDate,
    }) async {
      _setLoading(true);
      try {
        await _taskService.updateTask(
          taskId,
          title: title,
          description: description,
          status: status,
          priority: priority,
          assigneeId: assigneeId,
          dueDate: dueDate,
        );
        _setLoading(false);
        return true;
      } catch (e) {
        _setError(e.toString());
        return false;
      }
    }

    // Supprimer
    Future<bool> deleteTask(String taskId) async {
      _setLoading(true);
      try {
        await _taskService.deleteTask(taskId);
        if (_selectedTask?.id == taskId) {
          _selectedTask = null;
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } catch (e) {
        _setError(e.toString());
        return false;
      }
    }

    // Charger les stats
    Future<void> loadStats(String projectId) async {
      try {
        _stats = await _taskService.getTaskStats(projectId);
        notifyListeners();
      } catch (e) {
        _setError(e.toString());
      }
    }

    // Helpers
    void _setLoading(bool value) {
      _isLoading = value;
      notifyListeners();
    }

    void _setError(String message) {
      _error = message;
      _isLoading = false;
      notifyListeners();
    }

    void _clearError() {
      _error = null;
    }

    void clearError() {
      _error = null;
      notifyListeners();
    }

    // Tâches en retard
    List<TaskModel> get overdueTasks {
      final now = DateTime.now();
      return _tasks.where((t) {
        if (t.dueDate == null || t.isCompleted) return false;
        return t.dueDate!.isBefore(now);
      }).toList();
    }

    // Tâches pour aujourd'hui
    List<TaskModel> get todayTasks {
      final now = DateTime.now();
      return _tasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == now.year &&
              t.dueDate!.month == now.month &&
              t.dueDate!.day == now.day;
      }).toList();
    }

    @override
    void dispose() {
      _tasksSubscription?.cancel();
      _userTasksSubscription?.cancel();
      super.dispose();
    }
  }