import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'payments';

  PaymentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<PaymentModel> createPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final payment = PaymentModel(
      id: '',
      bookingId: bookingId,
      userId: userId,
      amount: amount,
      status: PaymentStatus.pending,
      method: method,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(payment.toJson());
    return payment.copyWith(id: docRef.id);
  }

  Future<PaymentModel> getPayment(String paymentId) async {
    final doc = await _firestore.collection(_collection).doc(paymentId).get();
    if (!doc.exists) {
      throw Exception('Payment not found');
    }
    return PaymentModel.fromJson(doc.data()!, doc.id);
  }

  Future<List<PaymentModel>> getUserPayments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<PaymentModel>> getBookingPayments(String bookingId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('bookingId', isEqualTo: bookingId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(_collection).doc(paymentId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Payment not found');
    }

    final payment = PaymentModel.fromJson(doc.data()!, doc.id);
    if (payment.userId != userId) {
      throw Exception('Not authorized to update this payment');
    }

    final updates = <String, dynamic>{
      'status': status.toString(),
      'updatedAt': DateTime.now(),
    };

    if (transactionId != null) {
      updates['transactionId'] = transactionId;
    }

    await docRef.update(updates);
  }

  Future<void> processMockPayment(String paymentId) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Randomly succeed or fail
    final success = DateTime.now().millisecondsSinceEpoch % 2 == 0;

    await updatePaymentStatus(
      paymentId: paymentId,
      status: success ? PaymentStatus.completed : PaymentStatus.failed,
      transactionId:
          success ? 'MOCK_${DateTime.now().millisecondsSinceEpoch}' : null,
    );
  }
}
