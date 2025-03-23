import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/data/repositories/car_repository.dart';
import 'package:flutter/foundation.dart';

// Events
abstract class CarEvent {
  const CarEvent();
}

class LoadCars extends CarEvent {
  const LoadCars();
}

class AddSampleCars extends CarEvent {
  const AddSampleCars();
}

class AddCar extends CarEvent {
  final Car car;
  AddCar(this.car);
}

class UpdateCar extends CarEvent {
  final Car car;
  UpdateCar(this.car);
}

class DeleteCar extends CarEvent {
  final String carId;
  DeleteCar(this.carId);
}

// Internal events
class _LoadCarsSuccess extends CarEvent {
  final List<Car> cars;
  _LoadCarsSuccess(this.cars);
}

class _LoadCarsError extends CarEvent {
  final String message;
  _LoadCarsError(this.message);
}

// States
abstract class CarState {}

class CarInitial extends CarState {}

class CarLoading extends CarState {}

class CarLoaded extends CarState {
  final List<Car> cars;
  CarLoaded(this.cars);
}

class CarError extends CarState {
  final String message;
  CarError(this.message);
}

// Bloc
class CarBloc extends Bloc<CarEvent, CarState> {
  final CarRepository _carRepository;
  StreamSubscription? _carsSubscription;

  CarBloc({CarRepository? carRepository})
      : _carRepository = carRepository ?? CarRepository(),
        super(CarInitial()) {
    on<LoadCars>(_onLoadCars);
    on<AddCar>(_onAddCar);
    on<UpdateCar>(_onUpdateCar);
    on<DeleteCar>(_onDeleteCar);
    on<AddSampleCars>(_onAddSampleCars);
    on<_LoadCarsSuccess>(_onLoadCarsSuccess);
    on<_LoadCarsError>(_onLoadCarsError);

    // Automatically load cars when bloc is created
    add(LoadCars());
  }

  Future<void> _onLoadCars(LoadCars event, Emitter<CarState> emit) async {
    try {
      emit(CarLoading());

      _carsSubscription?.cancel();
      _carsSubscription = _carRepository.getCars().listen(
        (cars) {
          // Additional safety check before emitting the state
          if (cars.isEmpty) {
            // If there are no cars, add sample cars
            debugPrint('No cars found, attempting to add sample cars');
            _carRepository.addSampleCars().then((_) {
              debugPrint('Sample cars added successfully');
              // We don't immediately emit here as the stream will
              // automatically update with the new data
            }).catchError((error) {
              debugPrint('Error adding sample cars: $error');
              // If we fail to add sample cars, we'll emit the empty list
              add(_LoadCarsSuccess([]));
            });
          } else {
            debugPrint('Found ${cars.length} cars, emitting success state');
            add(_LoadCarsSuccess(cars));
          }
        },
        onError: (error) {
          debugPrint('Stream error in loadCars: $error');
          add(_LoadCarsError('Failed to load cars: ${error.toString()}'));
        },
      );
    } catch (e) {
      debugPrint('Exception in loadCars: $e');
      emit(CarError('Failed to load cars: ${e.toString()}'));
    }
  }

  void _onLoadCarsSuccess(_LoadCarsSuccess event, Emitter<CarState> emit) {
    emit(CarLoaded(event.cars));
  }

  void _onLoadCarsError(_LoadCarsError event, Emitter<CarState> emit) {
    emit(CarError(event.message));
  }

  Future<void> _onAddCar(AddCar event, Emitter<CarState> emit) async {
    try {
      await _carRepository.addCar(event.car);
      // The stream will automatically update the UI
    } catch (e) {
      emit(CarError('Failed to add car: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCar(UpdateCar event, Emitter<CarState> emit) async {
    try {
      await _carRepository.updateCar(event.car);
      // The stream will automatically update the UI
    } catch (e) {
      emit(CarError('Failed to update car: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCar(DeleteCar event, Emitter<CarState> emit) async {
    try {
      await _carRepository.deleteCar(event.carId);
      // The stream will automatically update the UI
    } catch (e) {
      emit(CarError('Failed to delete car: ${e.toString()}'));
    }
  }

  Future<void> _onAddSampleCars(
      AddSampleCars event, Emitter<CarState> emit) async {
    try {
      emit(CarLoading());
      await _carRepository.addSampleCars();
      // The stream will automatically update the UI
    } catch (e) {
      emit(CarError('Failed to add sample cars: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _carsSubscription?.cancel();
    return super.close();
  }
}
