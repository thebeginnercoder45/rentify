import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/domain/repositories/booking_repository.dart';

/// Use case for creating a new booking in the system
class CreateBooking {
  final BookingRepository _bookingRepository;

  /// Constructor that takes a [BookingRepository] instance
  CreateBooking(this._bookingRepository);

  /// Creates a new booking and returns the booking ID if successful
  Future<String?> call(Booking booking) async {
    try {
      return await _bookingRepository.createBooking(booking);
    } catch (e) {
      rethrow;
    }
  }
}
