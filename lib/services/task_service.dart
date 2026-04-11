import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Singleton
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // Créer une tâche
  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    String priority = 'medium',
    required String createdBy,
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      
      final task = TaskModel(
        id: docRef.id,
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        createdBy: createdBy,
        assigneeId: assigneeId,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );

      print('💾 Création tâche: $title (projectId: $projectId)');
      print('📊 Task toJson: ${task.toJson()}');
      
      await docRef.set(task.toJson());
      
      print('✅ Tâche créée avec ID: ${docRef.id}');
      return task;
    } catch (e) {
      print('❌ Erreur création: $e');
      throw Exception('Erreur création tâche: $e');
    }
  }

  // Récupérer toutes les tâches d'un projet
  Stream<List<TaskModel>> getProjectTasks(String projectId) {
    return _firestore
        .collection(_collection)
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
          try {
            print('📦 Snapshot reçu: ${snapshot.docs.length} documents');
            
            final tasks = <TaskModel>[];
            for (var doc in snapshot.docs) {
              try {
                final data = {...doc.data(), 'id': doc.id};
                print('📄 Doc ${doc.id}: $data');
                final task = TaskModel.fromJson(data);
                tasks.add(task);
              } catch (e) {
                print('❌ Erreur parsing doc ${doc.id}: $e');
              }
            }
            
            print('✅ ${tasks.length} tâches parsées');
            // Trier localement
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return tasks;
          } catch (e) {
            print('❌ Erreur map stream: $e');
            return [];
          }
        });
  }

  // Récupérer les tâches assignées à un utilisateur
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('assigneeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Trier localement par dueDate
          tasks.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
          return tasks;
        });
  }

  // Récupérer une tâche par ID
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Erreur récupération tâche: $e');
    }
  }

  // Mettre à jour le statut
  Future<void> updateStatus(String taskId, String newStatus) async {
    try {
      final isCompleted = newStatus == 'done';
      await _firestore.collection(_collection).doc(taskId).update({
        'status': newStatus,
        'isCompleted': isCompleted,
      });
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  // Assigner une tâche
  Future<void> assignTask(String taskId, String? assigneeId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'assigneeId': assigneeId,
      });
    } catch (e) {
      throw Exception('Erreur assignation: $e');
    }
  }

  // Mettre à jour une tâche complète
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (status != null) {
        updates['status'] = status;
        updates['isCompleted'] = status == 'done';
      }
      if (priority != null) updates['priority'] = priority;
      if (assigneeId != null) updates['assigneeId'] = assigneeId;
      if (dueDate != null) updates['dueDate'] = dueDate.toIso8601String();

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(taskId).update(updates);
      }
    } catch (e) {
      throw Exception('Erreur mise à jour: $e');
    }
  }

  // Ajouter un commentaire
  Future<void> addComment(String taskId, String comment) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'comments': FieldValue.arrayUnion([comment]),
      });
    } catch (e) {
      throw Exception('Erreur ajout commentaire: $e');
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      throw Exception('Erreur suppression: $e');
    }
  }

  // Compter les tâches par statut
  Future<Map<String, int>> getTaskStats(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('projectId', isEqualTo: projectId)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return {
        'total': tasks.length,
        'todo': tasks.where((t) => t.status == 'todo').length,
        'inprogress': tasks.where((t) => t.status == 'inprogress').length,
        'done': tasks.where((t) => t.status == 'done').length,
      };
    } catch (e) {
      throw Exception('Erreur stats: $e');
    }
  }
}