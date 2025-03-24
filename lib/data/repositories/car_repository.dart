import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/data/models/activity_log.dart';

/// Repository for managing car data in Firestore.
class CarRepository {
  final FirebaseFirestore _firestore;

  /// Creates a new instance of [CarRepository].
  ///
  /// [firestore] is an optional parameter used for dependency injection
  /// in tests. If not provided, the default Firestore instance will be used.
  CarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for cars in Firestore.
  CollectionReference get _carsRef => _firestore.collection('cars');

  /// Gets a stream of all available cars.
  Stream<List<Car>> getCars() {
    return _carsRef.snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // Safely convert to Map and add default values for missing fields
          final data = doc.data() as Map<String, dynamic>;
          // Ensure all required fields have non-null values
          final safeData = {
            ...data,
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Car',
            'brand': data['brand'] ?? 'Unknown Brand',
            'model': data['model'] ?? 'Unknown Model',
            'fuelType': data['fuelType'] ?? 'Petrol',
            'mileage': data['mileage'] ?? 0.0,
            'pricePerDay': data['pricePerDay'] ?? 0.0,
            'description': data['description'] ?? 'No description available',
            'features': data['features'] ?? <String, dynamic>{},
          };
          return Car.fromJson(safeData);
        }).toList();
      } catch (e) {
        debugPrint('Error parsing car documents: $e');
        // Return an empty list on error instead of letting the stream fail
        return <Car>[];
      }
    });
  }

  /// Gets a car by its ID.
  Future<Car?> getCarById(String id) async {
    try {
      final doc = await _carsRef.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      // Ensure all required fields have non-null values
      final safeData = {
        ...data,
        'id': doc.id,
        'name': data['name'] ?? 'Unknown Car',
        'brand': data['brand'] ?? 'Unknown Brand',
        'model': data['model'] ?? 'Unknown Model',
        'fuelType': data['fuelType'] ?? 'Petrol',
        'mileage': data['mileage'] ?? 0.0,
        'pricePerDay': data['pricePerDay'] ?? 0.0,
        'description': data['description'] ?? 'No description available',
        'features': data['features'] ?? <String, dynamic>{},
      };
      return Car.fromJson(safeData);
    } catch (e) {
      debugPrint('Error getting car by ID: $e');
      return null;
    }
  }

  /// Adds a new car to the database.
  Future<String> addCar(Car car, {String? userId}) async {
    try {
      final docRef = await _carsRef.add(car.toJson());
      final carId = docRef.id;

      // Log activity
      await ActivityLogger.logCarAdded(
        carId,
        car.name,
        userId ?? 'system',
      );

      return carId;
    } catch (e) {
      debugPrint('Error adding car: $e');
      throw Exception('Failed to add car: $e');
    }
  }

  /// Updates an existing car in the database.
  Future<void> updateCar(Car car, {String? userId}) async {
    try {
      await _carsRef.doc(car.id).update(car.toJson());

      // Log car update activity
      await ActivityLogger.seedActivityLog(
        type: ActivityType.carUpdated,
        title: 'Car Updated',
        description: '${car.name} details were updated',
        userId: userId ?? 'system',
        relatedId: car.id,
      );
    } catch (e) {
      debugPrint('Error updating car: $e');
      throw Exception('Failed to update car: $e');
    }
  }

  /// Deletes a car from the database.
  Future<void> deleteCar(String id, {String? userId, String? carName}) async {
    try {
      // Get car name before deleting if not provided
      String nameForLog = carName ?? 'Car';
      if (carName == null) {
        final carDoc = await _carsRef.doc(id).get();
        if (carDoc.exists) {
          final data = carDoc.data() as Map<String, dynamic>;
          nameForLog = data['name'] ?? 'Car';
        }
      }

      await _carsRef.doc(id).delete();

      // Log car deletion activity
      await ActivityLogger.seedActivityLog(
        type: ActivityType.carDeleted,
        title: 'Car Deleted',
        description: '$nameForLog was removed from the fleet',
        userId: userId ?? 'system',
        relatedId: id,
      );
    } catch (e) {
      debugPrint('Error deleting car: $e');
      throw Exception('Failed to delete car: $e');
    }
  }

  /// Adds sample cars to the database for testing purposes.
  Future<void> addSampleCars() async {
    try {
      // Check if we already have cars
      final snapshot = await _carsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('Sample cars already exist, skipping');
        return; // Skip if we already have cars
      }

      debugPrint('No cars found, adding sample cars...');
      final sampleCars = [
        Car(
          id: 'car1',
          name: 'Swift Dzire',
          brand: 'Maruti Suzuki',
          model: 'Dzire VXi',
          fuelType: 'Petrol',
          mileage: 22.0,
          pricePerDay: 1500.0,
          pricePerHour: 80.0,
          latitude: 12.9716,
          longitude: 77.5946,
          distance: 3.2,
          fuelCapacity: 37.0,
          rating: 4.3,
          imageUrl: 'assets/cars/swift_dzire.png',
          category: 'Sedan',
          description:
              'A comfortable and fuel-efficient sedan perfect for city driving.',
          features: {
            'seats': 5,
            'transmission': 'Manual',
            'ac': true,
            'bluetooth': true,
          },
        ),
        Car(
          id: 'car2',
          name: 'Honda City',
          brand: 'Honda',
          model: 'City ZX',
          fuelType: 'Petrol',
          mileage: 18.5,
          pricePerDay: 2200.0,
          pricePerHour: 120.0,
          latitude: 12.9819,
          longitude: 77.6278,
          distance: 5.7,
          fuelCapacity: 40.0,
          rating: 4.7,
          imageUrl: 'assets/cars/honda_city.png',
          category: 'Sedan',
          description:
              'Premium sedan with advanced features and smooth driving experience.',
          features: {
            'seats': 5,
            'transmission': 'Automatic',
            'ac': true,
            'bluetooth': true,
            'sunroof': true,
          },
        ),
        Car(
          id: 'car3',
          name: 'Mahindra Thar',
          brand: 'Mahindra',
          model: 'Thar LX',
          fuelType: 'Diesel',
          mileage: 15.2,
          pricePerDay: 3000.0,
          pricePerHour: 150.0,
          latitude: 12.9606,
          longitude: 77.5775,
          distance: 2.8,
          fuelCapacity: 57.0,
          rating: 4.5,
          imageUrl: 'assets/cars/thar.png',
          category: 'SUV',
          description: 'Powerful SUV perfect for off-road adventures.',
          features: {
            'seats': 4,
            'transmission': 'Manual',
            'ac': true,
            'fourWheelDrive': true,
          },
        ),
        Car(
          id: 'car4',
          name: 'Toyota Innova',
          brand: 'Toyota',
          model: 'Innova Crysta',
          fuelType: 'Diesel',
          mileage: 14.0,
          pricePerDay: 3500.0,
          pricePerHour: 180.0,
          latitude: 12.9852,
          longitude: 77.6094,
          distance: 4.5,
          fuelCapacity: 65.0,
          rating: 4.8,
          imageUrl: 'assets/cars/innova.png',
          category: 'MPV',
          description: 'Spacious 7-seater MPV perfect for family trips.',
          features: {
            'seats': 7,
            'transmission': 'Automatic',
            'ac': true,
            'bluetooth': true,
            'airbags': 6,
          },
        ),
        Car(
          id: 'car5',
          name: 'BMW 5 Series',
          brand: 'BMW',
          model: '530i',
          fuelType: 'Petrol',
          mileage: 13.0,
          pricePerDay: 8000.0,
          pricePerHour: 400.0,
          latitude: 12.9772,
          longitude: 77.5946,
          distance: 3.6,
          fuelCapacity: 68.0,
          rating: 4.9,
          imageUrl: 'assets/car_image.png', // Default image for BMW
          category: 'Luxury',
          description:
              'Luxury sedan with premium features and powerful engine.',
          features: {
            'seats': 5,
            'transmission': 'Automatic',
            'ac': true,
            'bluetooth': true,
            'leather': true,
            'sunroof': true,
          },
        ),
        Car(
          id: 'car6',
          name: 'Tesla Model 3',
          brand: 'Tesla',
          model: 'Model 3',
          fuelType: 'Electric',
          mileage: 0.0,
          pricePerDay: 6500.0,
          pricePerHour: 350.0,
          latitude: 12.9852,
          longitude: 77.6094,
          distance: 4.1,
          fuelCapacity: 0.0,
          rating: 4.7,
          imageUrl: 'assets/car_image.png', // Default image for Tesla
          category: 'Electric',
          description: 'Fully electric sedan with autopilot capabilities.',
          features: {
            'seats': 5,
            'transmission': 'Automatic',
            'ac': true,
            'autopilot': true,
            'fastCharging': true,
          },
        ),
        // Add Tata SA12 car that appears in screenshot
        Car(
          id: 'car7',
          name: 'tata sa12',
          brand: 'Mercedes',
          model: 'S-Class',
          fuelType: 'Petrol',
          mileage: 10.0,
          pricePerDay: 12000.0,
          pricePerHour: 1250.0,
          latitude: 12.9882,
          longitude: 77.6194,
          distance: 3.2,
          fuelCapacity: 45.0,
          rating: 4.5,
          imageUrl: 'assets/car_image.png', // Default image for Tata
          category: 'Luxury',
          description:
              'Luxury car with premium features and a powerful engine.',
          features: {
            'navigation': true,
            'air_conditioning': true,
            'bluetooth': true,
            'sunroof': true,
            'automatic': true,
            'backup_camera': true,
            'leather_seats': true,
          },
        ),
      ];

      // Add each car to Firestore with set() to use our custom IDs
      for (final car in sampleCars) {
        await _carsRef.doc(car.id).set(car.toJson());
        debugPrint('Added car: ${car.name}');
      }

      debugPrint('Added ${sampleCars.length} sample cars successfully');
    } catch (e) {
      debugPrint('Error adding sample cars: $e');
      throw Exception('Failed to add sample cars: $e');
    }
  }
}
