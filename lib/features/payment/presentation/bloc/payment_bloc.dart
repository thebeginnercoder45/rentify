import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/models/payment_model.dart';

// Events
abstract class PaymentEvent {}

class CreatePayment extends PaymentEvent {
  final String bookingId;
  final double amount;
  final PaymentMethod method;

  CreatePayment({
    required this.bookingId,
    required this.amount,
    required this.method,
  });
}

class LoadUserPayments extends PaymentEvent {}

class LoadBookingPayments extends PaymentEvent {
  final String bookingId;

  LoadBookingPayments(this.bookingId);
}

class ProcessPayment extends PaymentEvent {
  final String paymentId;

  ProcessPayment(this.paymentId);
}

// States
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentCreated extends PaymentState {
  final PaymentModel payment;

  PaymentCreated(this.payment);
}

class PaymentsLoaded extends PaymentState {
  final List<PaymentModel> payments;

  PaymentsLoaded(this.payments);
}

class PaymentError extends PaymentState {
  final String message;

  PaymentError(this.message);
}

class PaymentProcessed extends PaymentState {
  final PaymentModel payment;

  PaymentProcessed(this.payment);
}

// Bloc
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;

  PaymentBloc(this._repository) : super(PaymentInitial()) {
    on<CreatePayment>(_onCreatePayment);
    on<LoadUserPayments>(_onLoadUserPayments);
    on<LoadBookingPayments>(_onLoadBookingPayments);
    on<ProcessPayment>(_onProcessPayment);
  }

  Future<void> _onCreatePayment(
    CreatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      final payment = await _repository.createPayment(
        bookingId: event.bookingId,
        amount: event.amount,
        method: event.method,
      );
      emit(PaymentCreated(payment));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadUserPayments(
    LoadUserPayments event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      final payments = await _repository.getUserPayments();
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadBookingPayments(
    LoadBookingPayments event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      final payments = await _repository.getBookingPayments(event.bookingId);
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      await _repository.processMockPayment(event.paymentId);
      final payment = await _repository.getPayment(event.paymentId);
      emit(PaymentProcessed(payment));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
