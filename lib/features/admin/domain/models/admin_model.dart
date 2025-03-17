import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json, String id) {
    return AdminModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      permissions: List<String>.from(json['permissions'] as List),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AdminModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
