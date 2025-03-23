import 'package:rentapp/data/models/car.dart';

abstract class CarState {
  const CarState();

  List<Object?> get props => [];
}

class CarInitial extends CarState {}

class CarsLoading extends CarState {}

class CarsLoaded extends CarState {
  final List<Car> cars;

  const CarsLoaded(this.cars);

  @override
  List<Object?> get props => [cars];
}

class CarsError extends CarState {
  final String message;

  const CarsError(this.message);

  @override
  List<Object?> get props => [message];
}

class CarAdded extends CarState {
  final Car car;

  const CarAdded(this.car);

  @override
  List<Object?> get props => [car];
}

class CarUpdated extends CarState {
  final Car car;

  const CarUpdated(this.car);

  @override
  List<Object?> get props => [car];
}

class CarDeleted extends CarState {
  final String carId;

  const CarDeleted(this.carId);

  @override
  List<Object?> get props => [carId];
}
