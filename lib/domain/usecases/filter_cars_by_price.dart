import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';

class FilterCarsByPrice {
  final CarRepository repository;

  FilterCarsByPrice(this.repository);

  Future<List<Car>> call(double minPrice, double maxPrice) async {
    return await repository.filterCarsByPrice(minPrice, maxPrice);
  }
}
