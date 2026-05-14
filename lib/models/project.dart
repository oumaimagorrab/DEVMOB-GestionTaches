import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? dueDate;  // ← AJOUTÉ
  final double? progress;
  final List<String> members;
  final String? color;
  final String status;

  ProjectModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.dueDate,  // ← AJOUTÉ
    this.progress = 0.0,
    this.members = const [],
    this.color,
    this.status = 'active',
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      dueDate: json['dueDate'] != null ? _parseDate(json['dueDate']) : null,  // ← AJOUTÉ
      progress: json['progress'] != null ? (json['progress'] as num).toDouble() : 0.0,
      members: List<String>.from(json['members'] ?? []),
      color: json['color'],
      status: json['status'] ?? 'active',
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
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,  // ← AJOUTÉ
      'progress': progress,
      'members': members,
      'color': color,
      'status': status,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? dueDate,  // ← AJOUTÉ
    double? progress,
    List<String>? members,
    String? color,
    String? status,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,  // ← AJOUTÉ
      progress: progress ?? this.progress,
      members: members ?? this.members,
      color: color ?? this.color,
      status: status ?? this.status,
    );
  }
}