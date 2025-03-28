import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/data/models/activity_log.dart';

/// Repository for managing booking data in Firestore.
class BookingRepository {
  final FirebaseFirestore _firestore;
  final String _collectionName = 'bookings';

  /// Creates a new instance of [BookingRepository].
  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for bookings.
  CollectionReference get _bookingsRef =>
      _firestore.collection(_collectionName);

  /// Creates a new booking in Firestore.
  Future<String?> createBooking(Booking booking) async {
    try {
      final docRef = await _bookingsRef.add(booking.toJson());
      final bookingId = docRef.id;

      // Log booking activity
      await ActivityLogger.seedActivityLog(
        type: ActivityType.bookingCreated,
        title: 'New Booking Created',
        description: 'Booking #$bookingId was created',
        userId: booking.userId,
        relatedId: bookingId,
      );

      return bookingId;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  /// Gets all bookings for a specific user.
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _bookingsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Booking.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('Error getting user bookings: $e');
      return [];
    }
  }

  /// Gets a booking by its ID.
  Future<Booking?> getBookingById(String id) async {
    try {
      final docSnapshot = await _bookingsRef.doc(id).get();
      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return Booking.fromJson({...data, 'id': id});
    } catch (e) {
      debugPrint('Error getting booking by ID: $e');
      return null;
    }
  }

  /// Updates a booking status in Firestore.
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookingsRef.doc(bookingId).update({'status': status});

      // Get the booking to include user ID in activity log
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      final booking = Booking.fromJson(
          {...bookingDoc.data() as Map<String, dynamic>, 'id': bookingId});

      // Log appropriate activity based on status
      if (status == 'confirmed') {
        await ActivityLogger.logBookingConfirmed(bookingId, booking.userId);
      } else if (status == 'cancelled') {
        await ActivityLogger.seedActivityLog(
          type: ActivityType.bookingCancelled,
          title: 'Booking Cancelled',
          description: 'Booking #$bookingId was cancelled',
          userId: booking.userId,
          relatedId: bookingId,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }

  /// Cancels a booking.
  Future<bool> cancelBooking(String id) async {
    try {
      await _bookingsRef.doc(id).update({'status': 'cancelled'});
      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  /// Checks if a car is available for a specific date range.
  Future<bool> isCarAvailableForDates(
      String carId, DateTime startDate, DateTime endDate) async {
    try {
      // Check for overlapping bookings
      final querySnapshot = await _bookingsRef
          .where('carId', isEqualTo: carId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bookingStartDate = (data['startDate'] as Timestamp).toDate();
        final bookingEndDate = (data['endDate'] as Timestamp).toDate();

        // Check for overlap
        if (startDate.isBefore(bookingEndDate) &&
            endDate.isAfter(bookingStartDate)) {
          return false; // Overlap found, car is not available
        }
      }

      return true; // No overlap, car is available
    } catch (e) {
      debugPrint('Error checking car availability: $e');
      return false; // Assume not available on error
    }
  }
}
