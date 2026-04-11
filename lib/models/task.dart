import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String status; // 'todo', 'inprogress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final String createdBy;
  final String? assigneeId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final List<String> comments;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    required this.createdBy,
    this.assigneeId,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.comments = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      createdBy: json['createdBy'] ?? '',
      assigneeId: json['assigneeId'],
      createdAt: _parseDate(json['createdAt']),
      dueDate: json['dueDate'] != null ? _parseDate(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      comments: List<String>.from(json['comments'] ?? []),
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
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'createdBy': createdBy,
      'assigneeId': assigneeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'comments': comments,
    };
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? createdBy,
    String? assigneeId,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    List<String>? comments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      assigneeId: assigneeId ?? this.assigneeId,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      comments: comments ?? this.comments,
    );
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}