class Member {
  final String name;
  final String email;
  final String image;
  final bool isRegistered;

  Member({
    required this.name,
    required this.email,
    required this.image,
    this.isRegistered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'image': image,
      'isRegistered': isRegistered,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      image: map['image'] ?? '',
      isRegistered: map['isRegistered'] ?? false,
    );
  }
}