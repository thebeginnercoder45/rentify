import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/car_model.dart';

class CarRepository {
  final FirebaseFirestore _firestore;

  CarRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<CarModel>> getAllCars() async {
    try {
      final snapshot = await _firestore.collection('cars').get();
      return snapshot.docs
          .map((doc) => CarModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cars: $e');
    }
  }

  Future<CarModel?> getCarById(String carId) async {
    try {
      final doc = await _firestore.collection('cars').doc(carId).get();
      if (!doc.exists) return null;
      return CarModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to load car: $e');
    }
  }

  Future<void> addCar(CarModel car) async {
    try {
      await _firestore.collection('cars').doc(car.id).set(car.toJson());
    } catch (e) {
      throw Exception('Failed to add car: $e');
    }
  }

  Future<void> updateCar(CarModel car) async {
    try {
      await _firestore.collection('cars').doc(car.id).update(car.toJson());
    } catch (e) {
      throw Exception('Failed to update car: $e');
    }
  }

  Future<void> deleteCar(String carId) async {
    try {
      await _firestore.collection('cars').doc(carId).delete();
    } catch (e) {
      throw Exception('Failed to delete car: $e');
    }
  }

  Future<void> toggleCarAvailability(String carId, bool isAvailable) async {
    try {
      await _firestore.collection('cars').doc(carId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle car availability: $e');
    }
  }

  Future<List<CarModel>> searchCars({
    String? query,
    String? brand,
    String? type,
    double? maxPrice,
    bool? isAvailable,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore.collection('cars');

      if (query != null && query.isNotEmpty) {
        queryRef = queryRef.where('name', isGreaterThanOrEqualTo: query);
      }

      if (brand != null && brand.isNotEmpty) {
        queryRef = queryRef.where('brand', isEqualTo: brand);
      }

      if (type != null && type.isNotEmpty) {
        queryRef = queryRef.where('type', isEqualTo: type);
      }

      if (maxPrice != null) {
        queryRef = queryRef.where('pricePerDay', isLessThanOrEqualTo: maxPrice);
      }

      if (isAvailable != null) {
        queryRef = queryRef.where('isAvailable', isEqualTo: isAvailable);
      }

      final snapshot = await queryRef.get();
      return snapshot.docs
          .map((doc) => CarModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to search cars: $e');
    }
  }
}
