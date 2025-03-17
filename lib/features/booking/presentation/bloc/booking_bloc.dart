import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/models/booking_model.dart';

// Events
abstract class BookingEvent {}

class CreateBooking extends BookingEvent {
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;

  CreateBooking({
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
  });
}

class LoadUserBookings extends BookingEvent {}

class LoadCarBookings extends BookingEvent {
  final String carId;

  LoadCarBookings(this.carId);
}

class CancelBooking extends BookingEvent {
  final String bookingId;

  CancelBooking(this.bookingId);
}

class ModifyBooking extends BookingEvent {
  final String bookingId;
  final DateTime? startDate;
  final DateTime? endDate;

  ModifyBooking({required this.bookingId, this.startDate, this.endDate});
}

class CheckCarAvailability extends BookingEvent {
  final String carId;
  final DateTime startDate;
  final DateTime endDate;

  CheckCarAvailability({
    required this.carId,
    required this.startDate,
    required this.endDate,
  });
}

// States
abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingCreated extends BookingState {
  final BookingModel booking;

  BookingCreated(this.booking);
}

class BookingsLoaded extends BookingState {
  final List<BookingModel> bookings;

  BookingsLoaded(this.bookings);
}

class BookingError extends BookingState {
  final String message;

  BookingError(this.message);
}

class BookingCancelled extends BookingState {
  final String bookingId;

  BookingCancelled(this.bookingId);
}

class BookingModified extends BookingState {
  final BookingModel booking;

  BookingModified(this.booking);
}

class CarAvailabilityChecked extends BookingState {
  final bool isAvailable;

  CarAvailabilityChecked(this.isAvailable);
}

// Bloc
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repository;

  BookingBloc(this._repository) : super(BookingInitial()) {
    on<CreateBooking>(_onCreateBooking);
    on<LoadUserBookings>(_onLoadUserBookings);
    on<LoadCarBookings>(_onLoadCarBookings);
    on<CancelBooking>(_onCancelBooking);
    on<ModifyBooking>(_onModifyBooking);
    on<CheckCarAvailability>(_onCheckCarAvailability);
  }

  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final booking = await _repository.createBooking(
        carId: event.carId,
        startDate: event.startDate,
        endDate: event.endDate,
        totalPrice: event.totalPrice,
      );
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadUserBookings(
    LoadUserBookings event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final bookings = await _repository.getUserBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadCarBookings(
    LoadCarBookings event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final bookings = await _repository.getCarBookings(event.carId);
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      await _repository.cancelBooking(event.bookingId);
      emit(BookingCancelled(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onModifyBooking(
    ModifyBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final booking = await _repository.modifyBooking(
        bookingId: event.bookingId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(BookingModified(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCheckCarAvailability(
    CheckCarAvailability event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingLoading());
      final isAvailable = await _repository.isCarAvailable(
        carId: event.carId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(CarAvailabilityChecked(isAvailable));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
