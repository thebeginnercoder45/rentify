import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/car_repository.dart';
import '../../domain/models/car_model.dart';

// Events
abstract class CarEvent {}

class LoadCars extends CarEvent {}

class LoadCarDetails extends CarEvent {
  final String carId;
  LoadCarDetails(this.carId);
}

class SearchCars extends CarEvent {
  final String? query;
  final String? brand;
  final String? type;
  final double? maxPrice;
  final bool? isAvailable;

  SearchCars({
    this.query,
    this.brand,
    this.type,
    this.maxPrice,
    this.isAvailable,
  });
}

class AddCar extends CarEvent {
  final CarModel car;
  AddCar(this.car);
}

class UpdateCar extends CarEvent {
  final CarModel car;
  UpdateCar(this.car);
}

class DeleteCar extends CarEvent {
  final String carId;
  DeleteCar(this.carId);
}

class ToggleCarAvailability extends CarEvent {
  final String carId;
  final bool isAvailable;
  ToggleCarAvailability(this.carId, this.isAvailable);
}

// States
abstract class CarState {}

class CarInitial extends CarState {}

class CarLoading extends CarState {}

class CarsLoaded extends CarState {
  final List<CarModel> cars;
  CarsLoaded(this.cars);
}

class CarDetailsLoaded extends CarState {
  final CarModel car;
  CarDetailsLoaded(this.car);
}

class CarError extends CarState {
  final String message;
  CarError(this.message);
}

// Bloc
class CarBloc extends Bloc<CarEvent, CarState> {
  final CarRepository carRepository;

  CarBloc({required this.carRepository}) : super(CarInitial()) {
    on<LoadCars>(_onLoadCars);
    on<LoadCarDetails>(_onLoadCarDetails);
    on<SearchCars>(_onSearchCars);
    on<AddCar>(_onAddCar);
    on<UpdateCar>(_onUpdateCar);
    on<DeleteCar>(_onDeleteCar);
    on<ToggleCarAvailability>(_onToggleCarAvailability);
  }

  Future<void> _onLoadCars(LoadCars event, Emitter<CarState> emit) async {
    try {
      emit(CarLoading());
      final cars = await carRepository.getAllCars();
      emit(CarsLoaded(cars));
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onLoadCarDetails(
    LoadCarDetails event,
    Emitter<CarState> emit,
  ) async {
    try {
      emit(CarLoading());
      final car = await carRepository.getCarById(event.carId);
      if (car != null) {
        emit(CarDetailsLoaded(car));
      } else {
        emit(CarError('Car not found'));
      }
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onSearchCars(SearchCars event, Emitter<CarState> emit) async {
    try {
      emit(CarLoading());
      final cars = await carRepository.searchCars(
        query: event.query,
        brand: event.brand,
        type: event.type,
        maxPrice: event.maxPrice,
        isAvailable: event.isAvailable,
      );
      emit(CarsLoaded(cars));
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onAddCar(AddCar event, Emitter<CarState> emit) async {
    try {
      await carRepository.addCar(event.car);
      add(LoadCars());
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onUpdateCar(UpdateCar event, Emitter<CarState> emit) async {
    try {
      await carRepository.updateCar(event.car);
      add(LoadCars());
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onDeleteCar(DeleteCar event, Emitter<CarState> emit) async {
    try {
      await carRepository.deleteCar(event.carId);
      add(LoadCars());
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }

  Future<void> _onToggleCarAvailability(
    ToggleCarAvailability event,
    Emitter<CarState> emit,
  ) async {
    try {
      await carRepository.toggleCarAvailability(event.carId, event.isAvailable);
      add(LoadCars());
    } catch (e) {
      emit(CarError(e.toString()));
    }
  }
}
