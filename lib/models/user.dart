class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoURL; // Photo de profil uploadée par l'utilisateur
  final DateTime createdAt;
  final bool isActive;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    required this.createdAt,
    this.isActive = true,
    this.role = 'collaborateur',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? json['nomComplet'] ?? '',
      email: json['email'] ?? '',
      // Photo uploadée par l'utilisateur (pas d'avatar automatique)
      photoURL: json['photoURL'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      role: json['role'] ?? 'collaborateur',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoURL,
    DateTime? createdAt,
    bool? isActive,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isRegularUser => role == 'collaborateur';
}