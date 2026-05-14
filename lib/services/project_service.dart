import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'projects';

  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  // ✅ CRÉER un projet avec dueDate
  Future<ProjectModel> createProject({
    required String title,
    String? description,
    required String createdBy,
    List<String> members = const [],
    String? color,
    String status = 'active',
    DateTime? dueDate,  // ← AJOUTÉ
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      final project = ProjectModel(
        id: docRef.id,
        title: title,
        description: description,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        dueDate: dueDate,  // ← AJOUTÉ
        members: members,
        color: color,
        status: status,
      );

      await docRef.set(project.toJson());
      return project;
    } catch (e) {
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  Stream<List<ProjectModel>> getProjects() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Stream<List<ProjectModel>> getActiveProjects() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final createdProjects = snapshot.docs
          .map((doc) => ProjectModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      return createdProjects;
    });
  }

  Stream<List<ProjectModel>> getSharedProjects(String userId) {
    return _firestore
        .collection(_collection)
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(projectId).get();
      if (doc.exists) {
        return ProjectModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du projet: $e');
    }
  }

  // ✅ METTRE À JOUR avec dueDate
  Future<void> updateProject(
    String projectId, {
    String? title,
    String? description,
    List<String>? members,
    String? color,
    String? status,
    DateTime? dueDate,  // ← AJOUTÉ
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (members != null) updates['members'] = members;
      if (color != null) updates['color'] = color;
      if (status != null) updates['status'] = status;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);  // ← AJOUTÉ

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(projectId).update(updates);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Erreur lors du changement de status: $e');
    }
  }

  Future<void> archiveProject(String projectId) async {
    return updateProjectStatus(projectId, 'archived');
  }

  Future<void> completeProject(String projectId) async {
    return updateProjectStatus(projectId, 'completed');
  }

  Future<void> addMember(String projectId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du membre: $e');
    }
  }

  Future<void> removeMember(String projectId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait du membre: $e');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du projet: $e');
    }
  }

  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => ProjectModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
    // ✅ NOUVELLE MÉTHODE: Calcule et met à jour la progression d'un projet
  Future<void> updateProjectProgress(String projectId) async {
    try {
      // Récupère toutes les tâches du projet
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final tasks = tasksSnapshot.docs;
      final total = tasks.length;
      
      if (total == 0) {
        await _firestore.collection(_collection).doc(projectId).update({
          'progress': 0.0,
        });
        return;
      }

      final completed = tasks.where((doc) {
        final data = doc.data();
        return data['status'] == 'done' || data['isCompleted'] == true;
      }).length;

      final progress = completed / total;

      await _firestore.collection(_collection).doc(projectId).update({
        'progress': progress,
      });
    } catch (e) {
      print('Erreur mise à jour progression: $e');
    }
  }
}