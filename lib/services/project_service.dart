import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestiontaches/models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'projects';

  // Singleton pattern
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  // Créer un nouveau projet
  Future<ProjectModel> createProject({
    required String title,
    String? description,
    required String createdBy,
    List<String> members = const [],
    String? color,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      
      final project = ProjectModel(
        id: docRef.id,
        title: title,
        description: description,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        members: members,
        color: color,
      );

      await docRef.set(project.toJson());
      return project;
    } catch (e) {
      throw Exception('Erreur lors de la création du projet: $e');
    }
  }

  // Récupérer tous les projets
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

  // Récupérer les projets d'un utilisateur spécifique
  Stream<List<ProjectModel>> getUserProjects(String userId) {
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

  // Récupérer un projet par ID
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

  // Mettre à jour un projet
  Future<void> updateProject(
    String projectId, {
    String? title,
    String? description,
    List<String>? members,
    String? color,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (members != null) updates['members'] = members;
      if (color != null) updates['color'] = color;

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(projectId).update(updates);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du projet: $e');
    }
  }

  // Ajouter un membre au projet
  Future<void> addMember(String projectId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du membre: $e');
    }
  }

  // Retirer un membre du projet
  Future<void> removeMember(String projectId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait du membre: $e');
    }
  }

  // Supprimer un projet
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection(_collection).doc(projectId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du projet: $e');
    }
  }

  // Rechercher des projets
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
}