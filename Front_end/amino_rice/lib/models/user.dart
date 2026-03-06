class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? joinDate;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.joinDate,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'joinDate': joinDate?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      joinDate: json['join_date'] != null
          ? DateTime.parse(json['join_date'])
          : null,
      profileImageUrl: json['profile_image_url'],
    );
  }
}
