import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final double? progress;
  final List<String> members;
  final String? color;
  final String status;  // ✅ Ajout du champ status

  ProjectModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.progress = 0.0,
    this.members = const [],
    this.color,
    this.status = 'active',  // ✅ Valeur par défaut
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      progress: json['progress'] != null ? (json['progress'] as num).toDouble() : 0.0,
      members: List<String>.from(json['members'] ?? []),
      color: json['color'],
      status: json['status'] ?? 'active',  // ✅ Lecture du status
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) return DateTime.parse(dateValue);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'progress': progress,
      'members': members,
      'color': color,
      'status': status,  // ✅ Sauvegarde du status
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    double? progress,
    List<String>? members,
    String? color,
    String? status,  // ✅ Ajout dans copyWith
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      members: members ?? this.members,
      color: color ?? this.color,
      status: status ?? this.status,  // ✅ Utilisation du status
    );
  }
}