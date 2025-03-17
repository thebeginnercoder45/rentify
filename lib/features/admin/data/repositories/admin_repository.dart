import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/admin_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'admins';

  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AdminModel?> getCurrentAdmin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();

    if (doc.docs.isEmpty) return null;
    return AdminModel.fromJson(doc.docs.first.data(), doc.docs.first.id);
  }

  Future<bool> isAdmin(String userId) async {
    final doc =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();
    return doc.docs.isNotEmpty;
  }

  Future<List<AdminModel>> getAllAdmins() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => AdminModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createAdmin({
    required String userId,
    required String name,
    required String email,
    required List<String> permissions,
  }) async {
    final admin = AdminModel(
      id: '',
      userId: userId,
      name: name,
      email: email,
      permissions: permissions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add(admin.toJson());
  }

  Future<void> updateAdminPermissions({
    required String adminId,
    required List<String> permissions,
  }) async {
    await _firestore.collection(_collection).doc(adminId).update({
      'permissions': permissions,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteAdmin(String adminId) async {
    await _firestore.collection(_collection).doc(adminId).delete();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final carsSnapshot = await _firestore.collection('cars').get();
    final bookingsSnapshot = await _firestore.collection('bookings').get();
    final usersSnapshot = await _firestore.collection('users').get();
    final paymentsSnapshot = await _firestore.collection('payments').get();

    double totalRevenue = 0;
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') {
        totalRevenue += (data['amount'] as num).toDouble();
      }
    }

    return {
      'totalCars': carsSnapshot.docs.length,
      'totalBookings': bookingsSnapshot.docs.length,
      'totalUsers': usersSnapshot.docs.length,
      'totalRevenue': totalRevenue,
      'activeBookings':
          bookingsSnapshot.docs
              .where((doc) => doc.data()['status'] == 'confirmed')
              .length,
    };
  }
}
