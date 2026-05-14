import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;        // ID de l'admin destinataire
  final String senderId;      // ID du collaborateur qui a fait l'action
  final String senderName;    // Nom du collaborateur
  final String type;          // 'task_completed', 'project_created', etc.
  final String title;         // Titre de la notif
  final String message;       // Message détaillé
  final String? projectId;    // ID du projet concerné
  final String? projectName;  // Nom du projet
  final String? taskId;       // ID de la tâche concernée
  final String? taskName;     // Nom de la tâche
  final bool read;            // Lu ou non
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.title,
    required this.message,
    this.projectId,
    this.projectName,
    this.taskId,
    this.taskName,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Collaborateur',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      projectId: json['projectId'],
      projectName: json['projectName'],
      taskId: json['taskId'],
      taskName: json['taskName'],
      read: json['read'] ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is DateTime) return dateValue;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'message': message,
      'projectId': projectId,
      'projectName': projectName,
      'taskId': taskId,
      'taskName': taskName,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? senderId,
    String? senderName,
    String? type,
    String? title,
    String? message,
    String? projectId,
    String? projectName,
    String? taskId,
    String? taskName,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}