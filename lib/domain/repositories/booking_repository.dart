import 'package:rentapp/data/models/booking.dart';

abstract class BookingRepository {
  Future<String> createBooking(Booking booking);
  Future<List<Booking>> getBookingsByUserId(String userId);
  Future<List<Booking>> getBookingsByCarId(String carId);
  Future<bool> isCarAvailableForDates(
      String carId, DateTime startDate, DateTime endDate);
  Future<void> updateBookingStatus(String id, String status);
  Future<void> cancelBooking(String id);
}
