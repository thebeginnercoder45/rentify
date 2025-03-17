import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'bookings';

  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<BookingModel> createBooking({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final booking = BookingModel(
      id: '',
      carId: carId,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(booking.toJson());
    return booking.copyWith(id: docRef.id);
  }

  Future<List<BookingModel>> getUserBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<BookingModel>> getCarBookings(String carId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('carId', isEqualTo: carId)
            .where(
              'status',
              whereIn: [
                BookingStatus.pending.toString(),
                BookingStatus.confirmed.toString(),
              ],
            )
            .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<bool> isCarAvailable({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final bookings = await getCarBookings(carId);
    return !bookings.any((booking) {
      return (startDate.isBefore(booking.endDate) &&
          endDate.isAfter(booking.startDate));
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(_collection).doc(bookingId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = BookingModel.fromJson(doc.data()!, doc.id);
    if (booking.userId != userId) {
      throw Exception('Not authorized to cancel this booking');
    }

    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.confirmed) {
      throw Exception('Cannot cancel booking in current status');
    }

    await docRef.update({
      'status': BookingStatus.cancelled.toString(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<BookingModel> modifyBooking({
    required String bookingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(_collection).doc(bookingId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = BookingModel.fromJson(doc.data()!, doc.id);
    if (booking.userId != userId) {
      throw Exception('Not authorized to modify this booking');
    }

    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.confirmed) {
      throw Exception('Cannot modify booking in current status');
    }

    if (startDate != null && endDate != null) {
      final isAvailable = await isCarAvailable(
        carId: booking.carId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!isAvailable) {
        throw Exception('Car is not available for selected dates');
      }
    }

    final updates = <String, dynamic>{'updatedAt': DateTime.now()};

    if (startDate != null) updates['startDate'] = startDate;
    if (endDate != null) updates['endDate'] = endDate;

    await docRef.update(updates);

    final updatedDoc = await docRef.get();
    return BookingModel.fromJson(updatedDoc.data()!, bookingId);
  }
}
