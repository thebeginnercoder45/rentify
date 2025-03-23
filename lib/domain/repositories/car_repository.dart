import 'package:rentapp/data/models/car.dart';

abstract class CarRepository {
  Future<List<Car>> fetchCars();
  Future<Car?> getCarById(String id);
  Future<List<Car>> searchCarsByModel(String query);
  Future<List<Car>> filterCarsByPrice(double minPrice, double maxPrice);
  Future<String> addCar(Car car);
  Future<void> updateCar(String id, Car car);
  Future<void> updateCarAvailability(String id, bool isAvailable);
  Future<void> deleteCar(String id);
}
