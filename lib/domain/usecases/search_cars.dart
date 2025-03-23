import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';

class SearchCars {
  final CarRepository repository;

  SearchCars(this.repository);

  Future<List<Car>> call(String query) async {
    return await repository.searchCarsByModel(query);
  }
}
