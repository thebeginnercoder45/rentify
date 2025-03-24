import 'package:rentapp/data/models/booking.dart';

abstract class BookingEvent {
  const BookingEvent();

  List<Object?> get props => [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingEvent && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => props.hashCode;
}

class FetchBookings extends BookingEvent {
  final String userId;

  const FetchBookings({required this.userId});

  @override
  List<Object?> get props => [userId];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchBookings && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class FetchAllBookings extends BookingEvent {
  const FetchAllBookings();
}

class CreateBooking extends BookingEvent {
  final Booking booking;

  const CreateBooking({required this.booking});

  @override
  List<Object?> get props => [booking];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateBooking && other.booking == booking;
  }

  @override
  int get hashCode => booking.hashCode;
}

class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final String status;

  const UpdateBookingStatus({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateBookingStatus &&
        other.bookingId == bookingId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(bookingId, status);
}

class CancelBooking extends BookingEvent {
  final String bookingId;

  const CancelBooking({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CancelBooking && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

class FilterBookingsByStatus extends BookingEvent {
  final String status;

  const FilterBookingsByStatus({required this.status});

  @override
  List<Object?> get props => [status];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterBookingsByStatus && other.status == status;
  }

  @override
  int get hashCode => status.hashCode;
}

class FetchBookingDetails extends BookingEvent {
  final String bookingId;

  const FetchBookingDetails({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchBookingDetails && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

class FetchFilteredBookings extends BookingEvent {
  final String userId;
  final String? status;
  final DateTime startDate;
  final DateTime endDate;

  const FetchFilteredBookings({
    required this.userId,
    this.status,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, status, startDate, endDate];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchFilteredBookings &&
        other.userId == userId &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(userId, status, startDate, endDate);
}

class LoadBookings extends BookingEvent {
  final String? userId;

  const LoadBookings({this.userId});

  @override
  List<Object?> get props => [userId];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadBookings && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
