import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as auth show User;
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final auth.User? firebaseUser;
  final bool isAdmin;
  final Map<String, dynamic>? userData;

  AppUser({
    this.firebaseUser,
    required this.isAdmin,
    this.userData,
  });

  // Constructor that allows creating AppUser with direct properties
  AppUser.fromProperties({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    required bool isAdmin,
    required bool isAnonymous,
  })  : firebaseUser = null,
        this.isAdmin = isAdmin,
        userData = {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'photoURL': photoURL,
          'isAnonymous': isAnonymous,
          'isAdmin': isAdmin,
        };

  // Factory constructor to create AppUser from Firebase User
  static Future<AppUser> fromFirebaseUser(auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      return AppUser(
        firebaseUser: null,
        isAdmin: false,
        userData: null,
      );
    }

    try {
      // Extract only the uid which appears to work
      String uid;
      try {
        uid = firebaseUser.uid;
        print('[USER DEBUG] Got UID from Firebase: $uid');
      } catch (e) {
        print('[USER DEBUG] Error getting uid directly: $e');
        uid = 'unknown-uid';
      }

      // Instead of accessing other properties directly, get everything from Firestore
      try {
        // Check if user data exists in Firestore
        print('[USER DEBUG] Fetching user data from Firestore for $uid');
        final docSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (docSnapshot.exists) {
          print('[USER DEBUG] User data found in Firestore');
          final userData = docSnapshot.data();
          // Safe type conversion
          bool isUserAdmin = false;
          if (userData != null && userData.containsKey('isAdmin')) {
            isUserAdmin = userData['isAdmin'] == true;
          }

          return AppUser(
            firebaseUser: null, // Avoid using firebaseUser object at all
            isAdmin: isUserAdmin,
            userData: userData,
          );
        } else {
          print('[USER DEBUG] No user data in Firestore, creating new');
          // Create new user data if it doesn't exist
          final newUserData = {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'isAdmin': false,
          };

          // Create the user in Firestore right away
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set(newUserData, SetOptions(merge: true));
            print('[USER DEBUG] Created new user in Firestore');
          } catch (e) {
            print('[USER DEBUG] Error creating user in Firestore: $e');
          }

          return AppUser(
            firebaseUser: null, // Avoid using firebaseUser object at all
            isAdmin: false,
            userData: newUserData,
          );
        }
      } catch (firestoreError) {
        print('[USER DEBUG] Error accessing Firestore: $firestoreError');
        // Return minimal user with basic data if Firestore fails
        return AppUser(
          firebaseUser: null, // Avoid using firebaseUser object at all
          isAdmin: false,
          userData: {
            'uid': uid,
          },
        );
      }
    } catch (e) {
      print('[USER DEBUG] Error in fromFirebaseUser: $e');
      // Create a minimal default user to prevent app crashes
      return AppUser(
        firebaseUser: null,
        isAdmin: false,
        userData: {
          'uid': 'unknown-uid',
        },
      );
    }
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    // Start with userData if it exists
    final Map<String, dynamic> map = userData != null
        ? Map<String, dynamic>.from(userData!)
        : <String, dynamic>{};

    // Always include these fields
    map['uid'] = uid;
    if (email != null) map['email'] = email;
    if (displayName != null) map['displayName'] = displayName;
    map['isAdmin'] = isAdmin;
    map['isAnonymous'] = isAnonymous;

    return map;
  }

  // Convenience getters to access Firebase user properties
  String get uid => firebaseUser?.uid ?? userData?['uid'] as String? ?? '';

  String? get email {
    try {
      if (firebaseUser != null) {
        try {
          return firebaseUser!.email;
        } catch (e) {
          print('[USER DEBUG] Error accessing firebaseUser.email: $e');
        }
      }
      return userData?['email'] as String?;
    } catch (e) {
      print('[USER DEBUG] Error getting email: $e');
      return null;
    }
  }

  String? get displayName {
    try {
      if (firebaseUser != null) {
        try {
          return firebaseUser!.displayName;
        } catch (e) {
          print('[USER DEBUG] Error accessing firebaseUser.displayName: $e');
        }
      }
      return userData?['displayName'] as String?;
    } catch (e) {
      print('[USER DEBUG] Error getting displayName: $e');
      return null;
    }
  }

  String? get photoURL {
    try {
      if (firebaseUser != null) {
        try {
          return firebaseUser!.photoURL;
        } catch (e) {
          print('[USER DEBUG] Error accessing firebaseUser.photoURL: $e');
        }
      }
      return userData?['photoURL'] as String?;
    } catch (e) {
      print('[USER DEBUG] Error getting photoURL: $e');
      return null;
    }
  }

  bool get isAnonymous {
    try {
      if (firebaseUser != null) {
        try {
          return firebaseUser!.isAnonymous;
        } catch (e) {
          print('[USER DEBUG] Error accessing firebaseUser.isAnonymous: $e');
        }
      }
      return userData?['isGuest'] == true;
    } catch (e) {
      print('[USER DEBUG] Error getting isAnonymous: $e');
      return false;
    }
  }

  // Save user data to Firestore
  Future<void> saveToFirestore() async {
    try {
      if (firebaseUser == null &&
          (userData == null || userData!['uid'] == null)) {
        print('[USER DEBUG] Cannot save user data: No UID available');
        return;
      }

      String? uid;
      try {
        uid = firebaseUser?.uid;
      } catch (e) {
        print('[USER DEBUG] Error accessing firebaseUser.uid: $e');
      }

      uid ??= userData?['uid'] as String?;

      if (uid == null) {
        print('[USER DEBUG] Cannot save user data: No valid UID');
        return;
      }

      print('[USER DEBUG] Saving user data for UID: $uid');

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      String? userEmail;
      String? userDisplayName;

      try {
        if (firebaseUser != null) {
          try {
            userEmail = firebaseUser!.email;
          } catch (e) {
            print(
                '[USER DEBUG] Error accessing firebaseUser.email during save: $e');
          }

          try {
            userDisplayName = firebaseUser!.displayName;
          } catch (e) {
            print(
                '[USER DEBUG] Error accessing firebaseUser.displayName during save: $e');
          }
        }
      } catch (e) {
        print('[USER DEBUG] Error accessing Firebase user properties: $e');
      }

      final Map<String, dynamic> dataToSave = {
        'uid': uid,
        'email': userEmail ?? userData?['email'],
        'displayName': userDisplayName ?? userData?['displayName'],
        'lastLogin': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
      };

      // Add any other user data that exists
      if (userData != null) {
        // Don't overwrite existing fields with null values
        userData!.forEach((key, value) {
          if (value != null && !dataToSave.containsKey(key)) {
            dataToSave[key] = value;
          }
        });
      }

      print('[USER DEBUG] Data to save: ${dataToSave.keys.join(', ')}');

      await userRef.set(dataToSave, SetOptions(merge: true));
      print('[USER DEBUG] User data saved successfully for $uid');
    } catch (e) {
      print('[USER DEBUG] Error saving user data: $e');
      // We're swallowing the exception here so it doesn't crash the app
      // but we've logged it for debugging
    }
  }
}
