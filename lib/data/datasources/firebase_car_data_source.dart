import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentapp/data/models/car.dart';

/// Data source for accessing car data from Firebase Firestore.
class FirebaseCarDataSource {
  final FirebaseFirestore firestore;
  final String collectionName = 'cars';

  /// Creates a new [FirebaseCarDataSource] instance.
  FirebaseCarDataSource({required this.firestore});

  /// Gets all available cars from Firestore.
  Future<List<Car>> getCars() async {
    try {
      var snapshot = await firestore.collection(collectionName).get();
      return snapshot.docs
          .map((doc) => Car.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting cars: $e');
      return [];
    }
  }

  /// Gets a car by its ID.
  Future<Car?> getCarById(String id) async {
    try {
      var doc = await firestore.collection(collectionName).doc(id).get();
      if (!doc.exists) return null;
      return Car.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('Error getting car by ID: $e');
      return null;
    }
  }

  /// Searches for cars by model name.
  Future<List<Car>> searchCarsByModel(String query) async {
    try {
      var snapshot = await firestore
          .collection(collectionName)
          .where('model', isGreaterThanOrEqualTo: query)
          .where('model',
              isLessThanOrEqualTo:
                  query + '\uf8ff') // Unicode trick for "startsWith"
          .get();
      return snapshot.docs
          .map((doc) => Car.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error searching cars by model: $e');
      return [];
    }
  }

  /// Filters cars by price range.
  Future<List<Car>> filterCarsByPrice(double minPrice, double maxPrice) async {
    try {
      var snapshot = await firestore
          .collection(collectionName)
          .where('pricePerHour', isGreaterThanOrEqualTo: minPrice)
          .where('pricePerHour', isLessThanOrEqualTo: maxPrice)
          .get();
      return snapshot.docs
          .map((doc) => Car.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error filtering cars by price: $e');
      return [];
    }
  }

  /// Adds a new car to Firestore.
  Future<String> addCar(Car car) async {
    try {
      debugPrint('Adding car to Firestore: ${car.id}');
      debugPrint('Car image URL: ${car.imageUrl}');

      // Create car data with proper timestamps
      final carData = car.toFirestore();

      // Add extra timestamps for new cars
      if (!carData.containsKey('createdAt')) {
        carData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Double check image URL is included
      debugPrint('Car data before saving: $carData');
      debugPrint('Image URL in car data: ${carData['imageUrl']}');

      // Ensure car ID is preserved if provided
      String carId = car.id;

      // Use the car's ID if provided, otherwise create a new document
      if (car.id.isNotEmpty) {
        await firestore.collection(collectionName).doc(car.id).set(carData);
      } else {
        final docRef = await firestore.collection(collectionName).add(carData);
        carId = docRef.id;
      }

      // Verify car was saved with image URL
      debugPrint('Car saved with ID: $carId');
      final savedCar = await getCarById(carId);
      debugPrint('Saved car image URL: ${savedCar?.imageUrl}');

      return carId;
    } catch (e) {
      debugPrint('Error adding car: $e');
      throw Exception('Failed to add car: $e');
    }
  }

  /// Updates an existing car in Firestore.
  Future<void> updateCar(String id, Car car) async {
    try {
      await firestore.collection(collectionName).doc(id).update(car.toJson());
    } catch (e) {
      debugPrint('Error updating car: $e');
      throw Exception('Failed to update car: $e');
    }
  }

  /// Updates the availability status of a car.
  Future<void> updateCarAvailability(String id, bool isAvailable) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      debugPrint('Error updating car availability: $e');
      throw Exception('Failed to update car availability: $e');
    }
  }

  /// Deletes a car from Firestore.
  Future<void> deleteCar(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting car: $e');
      throw Exception('Failed to delete car: $e');
    }
  }
}
