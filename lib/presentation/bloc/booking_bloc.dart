import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/booking_event.dart';
import 'package:rentapp/presentation/bloc/booking_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/domain/repositories/booking_repository.dart';
import 'package:rentapp/domain/usecases/create_booking.dart' as use_cases;
import 'package:rentapp/domain/usecases/cancel_booking.dart' as domain;
import 'package:intl/intl.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingRepository bookingRepository;
  final use_cases.CreateBooking createBookingUseCase;
  final domain.CancelBooking cancelBookingUseCase;

  BookingBloc({
    required this.bookingRepository,
    required this.createBookingUseCase,
    required this.cancelBookingUseCase,
  }) : super(BookingInitial()) {
    on<FetchBookings>(_onFetchBookings);
    on<FetchAllBookings>(_onFetchAllBookings);
    on<CreateBooking>(_onCreateBooking);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<CancelBooking>(_onCancelBooking);
    on<FetchBookingDetails>(_onFetchBookingDetails);
    on<FilterBookingsByStatus>(_onFilterBookingsByStatus);
    on<FetchFilteredBookings>(_onFetchFilteredBookings);
  }

  Future<void> _onFetchBookings(
      FetchBookings event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      print('Fetching bookings for user: ${event.userId}');

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: event.userId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
          'Found ${querySnapshot.docs.length} bookings for user ${event.userId}');

      final bookings = _parseBookingsFromDocs(querySnapshot.docs);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      print('Error fetching bookings: $e');
      emit(BookingError(
          'Failed to load bookings. Please check your connection and try again.'));
    }
  }

  Future<void> _onFetchAllBookings(
      FetchAllBookings event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = _parseBookingsFromDocs(querySnapshot.docs);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      print('Error fetching all bookings: $e');
      emit(BookingError(
          'Failed to load bookings. Please check your connection and try again.'));
    }
  }

  Future<void> _onCreateBooking(
      CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      // Check if the car is available
      final carDoc =
          await _firestore.collection('cars').doc(event.booking.carId).get();

      if (!carDoc.exists) {
        emit(BookingError('Car not found'));
        return;
      }

      final car = Car.fromFirestore(carDoc);

      if (!car.isAvailable) {
        emit(BookingError('This car is not available for booking'));
        return;
      }

      // Create booking in Firestore
      final bookingRef = _firestore.collection('bookings').doc();

      final bookingData = event.booking.toFirestore();
      await bookingRef.set(bookingData);

      // Get the created booking
      final bookingDoc = await bookingRef.get();
      final booking = Booking.fromFirestore(bookingDoc);

      // Update car availability if needed
      // Note: This is optional, depending on your business logic
      /*
      await _firestore.collection('cars').doc(event.booking.carId).update({
        'isAvailable': false,
      });
      */

      emit(BookingCreated(booking));
    } catch (e) {
      print('Error creating booking: $e');
      emit(BookingError('Failed to create booking: $e'));
    }
  }

  Future<void> _onUpdateBookingStatus(
      UpdateBookingStatus event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      // Update booking status in Firestore
      await _firestore.collection('bookings').doc(event.bookingId).update({
        'status': event.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If status is "cancelled", we might want to update car availability
      if (event.status == 'cancelled' || event.status == 'completed') {
        // First get the booking to get the car ID
        final bookingDoc =
            await _firestore.collection('bookings').doc(event.bookingId).get();
        if (bookingDoc.exists) {
          final booking = Booking.fromFirestore(bookingDoc);

          // Update car availability to true (available again)
          await _firestore.collection('cars').doc(booking.carId).update({
            'isAvailable': true,
          });
        }
      }

      emit(BookingUpdated(bookingId: event.bookingId, status: event.status));

      // Reload bookings
      final querySnapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = _parseBookingsFromDocs(querySnapshot.docs);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      print('Error updating booking status: $e');
      emit(BookingError('Failed to update booking status: $e'));
    }
  }

  Future<void> _onCancelBooking(
      CancelBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      // Update booking status to cancelled
      await _firestore.collection('bookings').doc(event.bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the booking to get the car ID
      final bookingDoc =
          await _firestore.collection('bookings').doc(event.bookingId).get();
      if (bookingDoc.exists) {
        final booking = Booking.fromFirestore(bookingDoc);

        // Update car availability to true (available again)
        await _firestore.collection('cars').doc(booking.carId).update({
          'isAvailable': true,
        });
      }

      emit(BookingUpdated(bookingId: event.bookingId, status: 'cancelled'));

      // Reload bookings
      final querySnapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = _parseBookingsFromDocs(querySnapshot.docs);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      print('Error cancelling booking: $e');
      emit(BookingError('Failed to cancel booking: $e'));
    }
  }

  Future<void> _onFetchBookingDetails(
      FetchBookingDetails event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final bookingDoc =
          await _firestore.collection('bookings').doc(event.bookingId).get();

      if (!bookingDoc.exists) {
        emit(BookingError('Booking not found'));
        return;
      }

      final booking = Booking.fromFirestore(bookingDoc);
      emit(BookingDetailsLoaded(booking));
    } catch (e) {
      print('Error fetching booking details: $e');
      emit(BookingError('Failed to load booking details: $e'));
    }
  }

  Future<void> _onFilterBookingsByStatus(
      FilterBookingsByStatus event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final querySnapshot = event.status == 'All'
          ? await _firestore
              .collection('bookings')
              .orderBy('createdAt', descending: true)
              .get()
          : await _firestore
              .collection('bookings')
              .where('status', isEqualTo: event.status.toLowerCase())
              .orderBy('createdAt', descending: true)
              .get();

      final bookings = _parseBookingsFromDocs(querySnapshot.docs);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      print('Error filtering bookings: $e');
      emit(BookingError('Failed to filter bookings: $e'));
    }
  }

  Future<void> _onFetchFilteredBookings(
      FetchFilteredBookings event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      print('Fetching filtered bookings for user: ${event.userId}');
      print('Filter date range: ${event.startDate} to ${event.endDate}');

      // Create query for user's bookings
      var query = _firestore
          .collection('bookings')
          .where('userId', isEqualTo: event.userId);

      // Add status filter if provided
      if (event.status != null && event.status != 'All') {
        query = query.where('status', isEqualTo: event.status!.toLowerCase());
      }

      // Get all bookings for the user (and status if filtered)
      final querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      print(
          'Found ${querySnapshot.docs.length} bookings matching initial criteria');

      // We need to filter by date range in memory because Firestore doesn't allow
      // complex queries with multiple range operators (startDate and endDate)
      final allBookings = _parseBookingsFromDocs(querySnapshot.docs);

      // Filter bookings by date range
      final filteredBookings = allBookings.where((booking) {
        // Check if booking dates overlap with the filter range
        return (booking.startDate.isAfter(event.startDate) ||
                booking.startDate.isAtSameMomentAs(event.startDate)) &&
            (booking.endDate.isBefore(event.endDate) ||
                booking.endDate.isAtSameMomentAs(event.endDate));
      }).toList();

      print('After date filtering: ${filteredBookings.length} bookings');

      emit(BookingsLoaded(filteredBookings));
    } catch (e) {
      print('Error fetching filtered bookings: $e');
      emit(BookingError(
          'Failed to load filtered bookings. Please check your connection and try again.'));
    }
  }

  // Helper method to parse bookings from QueryDocumentSnapshot list
  List<Booking> _parseBookingsFromDocs(List<QueryDocumentSnapshot> docs) {
    final bookings = <Booking>[];

    for (final doc in docs) {
      try {
        final booking = Booking.fromFirestore(doc);
        bookings.add(booking);
      } catch (e) {
        print('Error parsing booking document ${doc.id}: $e');
      }
    }

    return bookings;
  }
}
