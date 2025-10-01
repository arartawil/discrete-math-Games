import 'dart:convert';

class UserProfile {
  const UserProfile({required this.name, required this.studentNumber});

  final String name;
  final String studentNumber;

  Map<String, dynamic> toJson() => {
        'name': name,
        'studentNumber': studentNumber,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      studentNumber: json['studentNumber'] as String? ?? '',
    );
  }

  static UserProfile? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    return UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  String toJsonString() => jsonEncode(toJson());

  UserProfile copyWith({String? name, String? studentNumber}) {
    return UserProfile(
      name: name ?? this.name,
      studentNumber: studentNumber ?? this.studentNumber,
    );
  }

  bool get isValid => name.isNotEmpty && studentNumber.isNotEmpty;
}
