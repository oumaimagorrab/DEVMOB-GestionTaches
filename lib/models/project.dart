import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  final String? color;

  ProjectModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.color,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      members: List<String>.from(json['members'] ?? []),
      color: json['color'],
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
      'members': members,
      'color': color,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? members,
    String? color,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      color: color ?? this.color,
    );
  }
}