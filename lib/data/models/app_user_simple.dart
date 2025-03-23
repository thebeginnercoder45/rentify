import 'package:cloud_firestore/cloud_firestore.dart';

/// A simplified user model that doesn't depend on FirebaseUser
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final bool isAnonymous;
  final bool isAdmin;
  final bool isGuest;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.isAnonymous,
    required this.isAdmin,
    required this.isGuest,
  });

  // Convert user to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'isAnonymous': isAnonymous,
      'isAdmin': isAdmin,
      'isGuest': isGuest,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  // Create user from Firestore data
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      isGuest: map['isGuest'] ?? false,
    );
  }

  // Create a guest user
  factory AppUser.guest(String uid) {
    return AppUser(
      uid: uid,
      email: '',
      displayName: 'Guest',
      phoneNumber: '',
      isAnonymous: true,
      isAdmin: false,
      isGuest: true,
    );
  }

  // Copy the user with new values
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    bool? isAnonymous,
    bool? isAdmin,
    bool? isGuest,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isAdmin: isAdmin ?? this.isAdmin,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
