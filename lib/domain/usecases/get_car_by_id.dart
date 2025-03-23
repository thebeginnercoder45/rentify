import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';

class GetCarById {
  final CarRepository repository;

  GetCarById(this.repository);

  Future<Car?> call(String id) async {
    return await repository.getCarById(id);
  }
}
