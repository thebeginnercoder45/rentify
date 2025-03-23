import 'package:rentapp/data/datasources/firebase_booking_data_source.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseBookingDataSource dataSource;

  BookingRepositoryImpl(this.dataSource);

  @override
  Future<String> createBooking(Booking booking) {
    return dataSource.addBooking(booking);
  }

  @override
  Future<List<Booking>> getBookingsByUserId(String userId) {
    return dataSource.getBookingsByUserId(userId);
  }

  @override
  Future<List<Booking>> getBookingsByCarId(String carId) {
    return dataSource.getBookingsByCarId(carId);
  }

  @override
  Future<bool> isCarAvailableForDates(
      String carId, DateTime startDate, DateTime endDate) {
    return dataSource.isCarAvailableForDates(carId, startDate, endDate);
  }

  @override
  Future<void> updateBookingStatus(String id, String status) {
    return dataSource.updateBookingStatus(id, status);
  }

  @override
  Future<void> cancelBooking(String id) {
    return dataSource.cancelBooking(id);
  }
}
