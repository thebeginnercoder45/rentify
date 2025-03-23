import 'package:rentapp/data/models/car.dart';

abstract class CarEvent {
  const CarEvent();

  List<Object?> get props => [];
}

class LoadCars extends CarEvent {
  const LoadCars();
}

class AddCar extends CarEvent {
  final Car car;

  const AddCar(this.car);

  @override
  List<Object?> get props => [car];
}

class UpdateCar extends CarEvent {
  final Car car;

  const UpdateCar(this.car);

  @override
  List<Object?> get props => [car];
}

class DeleteCar extends CarEvent {
  final String carId;

  const DeleteCar(this.carId);

  @override
  List<Object?> get props => [carId];
}

class SearchCars extends CarEvent {
  final String query;

  const SearchCars(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCarsByCategory extends CarEvent {
  final String category;

  const FilterCarsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}
