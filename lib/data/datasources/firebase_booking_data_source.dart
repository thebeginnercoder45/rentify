import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/data/models/booking.dart';

class FirebaseBookingDataSource {
  final FirebaseFirestore firestore;
  final String collectionName = 'bookings';

  FirebaseBookingDataSource({required this.firestore});

  // CREATE - Add a new booking
  Future<String> addBooking(Booking booking) async {
    final docRef =
        await firestore.collection(collectionName).add(booking.toJson());
    return docRef.id;
  }

  // READ - Get bookings by user ID
  Future<List<Booking>> getBookingsByUserId(String userId) async {
    var snapshot = await firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Booking.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // READ - Get bookings by car ID
  Future<List<Booking>> getBookingsByCarId(String carId) async {
    var snapshot = await firestore
        .collection(collectionName)
        .where('carId', isEqualTo: carId)
        .orderBy('startDate')
        .get();
    return snapshot.docs
        .map((doc) => Booking.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // READ - Check if car is available for date range
  Future<bool> isCarAvailableForDates(
      String carId, DateTime startDate, DateTime endDate) async {
    // Convert to Timestamp for Firestore query
    final start = Timestamp.fromDate(startDate);
    final end = Timestamp.fromDate(endDate);

    // Find any bookings that overlap with the date range
    var snapshot = await firestore
        .collection(collectionName)
        .where('carId', isEqualTo: carId)
        .where('status',
            whereIn: ['pending', 'confirmed']) // Only check active bookings
        .get();

    // Check each booking for overlap
    for (var doc in snapshot.docs) {
      final booking = Booking.fromJson({...doc.data(), 'id': doc.id});

      // Check if the new booking overlaps with existing booking
      if (!(booking.endDate.isBefore(startDate) ||
          booking.startDate.isAfter(endDate))) {
        return false; // Car is not available (there's an overlap)
      }
    }

    return true; // Car is available for the date range
  }

  // UPDATE - Update booking status
  Future<void> updateBookingStatus(String id, String status) async {
    await firestore.collection(collectionName).doc(id).update({
      'status': status,
    });
  }

  // DELETE - Cancel a booking
  Future<void> cancelBooking(String id) async {
    await firestore.collection(collectionName).doc(id).update({
      'status': 'cancelled',
    });
  }
}
