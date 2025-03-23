import 'package:rentapp/domain/repositories/booking_repository.dart';

/// Use case for cancelling a booking
class CancelBooking {
  final BookingRepository _bookingRepository;

  /// Constructor that takes a [BookingRepository] instance
  CancelBooking(this._bookingRepository);

  /// Cancels a booking
  Future<void> call(String bookingId, String carId) async {
    try {
      await _bookingRepository.cancelBooking(bookingId);
      return;
    } catch (e) {
      rethrow;
    }
  }
}
