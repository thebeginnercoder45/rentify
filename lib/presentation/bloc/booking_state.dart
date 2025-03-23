import 'package:rentapp/data/models/booking.dart';

abstract class BookingState {
  const BookingState();

  List<Object?> get props => [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingState && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => props.hashCode;
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<Booking> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingsLoaded && other.bookings == bookings;
  }

  @override
  int get hashCode => bookings.hashCode;
}

class BookingCreated extends BookingState {
  final Booking booking;

  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingCreated && other.booking == booking;
  }

  @override
  int get hashCode => booking.hashCode;
}

class BookingDetailsLoaded extends BookingState {
  final Booking booking;

  const BookingDetailsLoaded(this.booking);

  @override
  List<Object?> get props => [booking];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingDetailsLoaded && other.booking == booking;
  }

  @override
  int get hashCode => booking.hashCode;
}

class BookingUpdated extends BookingState {
  final String bookingId;
  final String status;

  const BookingUpdated({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingUpdated &&
        other.bookingId == bookingId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(bookingId, status);
}

class BookingCancelled extends BookingState {
  final String bookingId;

  const BookingCancelled(this.bookingId);

  @override
  List<Object?> get props => [bookingId];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingCancelled && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
