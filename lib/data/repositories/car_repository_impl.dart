import 'package:rentapp/data/datasources/firebase_car_data_source.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';

class CarRepositoryImpl implements CarRepository {
  final FirebaseCarDataSource dataSource;

  CarRepositoryImpl(this.dataSource);

  @override
  Future<List<Car>> fetchCars() {
    return dataSource.getCars();
  }

  @override
  Future<Car?> getCarById(String id) {
    return dataSource.getCarById(id);
  }

  @override
  Future<List<Car>> searchCarsByModel(String query) {
    return dataSource.searchCarsByModel(query);
  }

  @override
  Future<List<Car>> filterCarsByPrice(double minPrice, double maxPrice) {
    return dataSource.filterCarsByPrice(minPrice, maxPrice);
  }

  @override
  Future<String> addCar(Car car) {
    return dataSource.addCar(car);
  }

  @override
  Future<void> updateCar(String id, Car car) {
    return dataSource.updateCar(id, car);
  }

  @override
  Future<void> updateCarAvailability(String id, bool isAvailable) {
    return dataSource.updateCarAvailability(id, isAvailable);
  }

  @override
  Future<void> deleteCar(String id) {
    return dataSource.deleteCar(id);
  }
}
