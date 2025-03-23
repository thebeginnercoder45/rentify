import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class SampleDataUploader {
  final FirebaseFirestore _firestore;

  SampleDataUploader(this._firestore);

  Future<void> uploadSampleCars() async {
    try {
      debugPrint('Starting to upload sample cars...');
      final batch = _firestore.batch();
      final carCollection = _firestore.collection('cars');

      // Check if we already have cars in the database
      // We're going to skip this check and add cars regardless for troubleshooting
      final existingCars = await carCollection.limit(1).get();
      if (existingCars.docs.isNotEmpty) {
        debugPrint(
            'Found ${existingCars.docs.length} existing cars in database. Adding more sample cars anyway.');
      } else {
        debugPrint('No existing cars found in database. Adding sample cars.');
      }

      // Add sample cars to the batch
      final sampleCars = _getSampleCars();
      debugPrint('Preparing to add ${sampleCars.length} sample cars');

      for (var car in sampleCars) {
        final docRef = carCollection.doc();
        final carData = {
          ...car.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        batch.set(docRef, carData);
        debugPrint('Added ${car.name} (${car.brand}) to batch');
      }

      // Commit the batch
      debugPrint('Committing batch of sample cars to Firestore...');
      await batch.commit();
      debugPrint('Successfully uploaded sample cars to Firestore');
    } catch (e) {
      debugPrint('Error uploading sample cars: $e');
    }
  }

  List<Car> _getSampleCars() {
    return [
      Car(
        id: '',
        name: 'Honda Civic',
        brand: 'Honda',
        model: 'Civic Sedan',
        fuelType: 'Petrol',
        mileage: 18.5,
        pricePerDay: 2500.0,
        pricePerHour: 120.0,
        latitude: 12.9716,
        longitude: 77.5946,
        distance: 1.2,
        fuelCapacity: 47.0,
        rating: 4.7,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/rentapp-3de0c.appspot.com/o/cars%2Fcivic.png?alt=media',
        category: 'Sedan',
        description: 'Sleek and fuel-efficient sedan with great handling.',
        features: {
          'seats': 5,
          'transmission': 'Automatic',
          'ac': true,
          'bluetooth': true,
          'airbags': 6,
        },
      ),
      Car(
        id: '',
        name: 'Toyota Fortuner',
        brand: 'Toyota',
        model: 'Fortuner 4x4',
        fuelType: 'Diesel',
        mileage: 14.2,
        pricePerDay: 4500.0,
        pricePerHour: 200.0,
        latitude: 12.9819,
        longitude: 77.6080,
        distance: 3.5,
        fuelCapacity: 80.0,
        rating: 4.8,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/rentapp-3de0c.appspot.com/o/cars%2Ffortuner.png?alt=media',
        category: 'SUV',
        description: 'Powerful SUV perfect for long drives and adventures.',
        features: {
          'seats': 7,
          'transmission': 'Automatic',
          'ac': true,
          'bluetooth': true,
          'fourWheelDrive': true,
          'airbags': 7,
          'sunroof': true,
        },
      ),
      Car(
        id: '',
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
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/rentapp-3de0c.appspot.com/o/cars%2Fthar.png?alt=media',
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
        id: '',
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
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/rentapp-3de0c.appspot.com/o/cars%2Finnova.png?alt=media',
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
        id: '',
        name: 'Hyundai i20',
        brand: 'Hyundai',
        model: 'i20 Asta',
        fuelType: 'Petrol',
        mileage: 20.0,
        pricePerDay: 2000.0,
        pricePerHour: 100.0,
        latitude: 12.9717,
        longitude: 77.6261,
        distance: 1.8,
        fuelCapacity: 45.0,
        rating: 4.6,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/rentapp-3de0c.appspot.com/o/cars%2Fi20.png?alt=media',
        category: 'Hatchback',
        description: 'Compact and stylish hatchback with great features.',
        features: {
          'seats': 5,
          'transmission': 'Manual',
          'ac': true,
          'bluetooth': true,
          'airbags': 6,
        },
      ),
    ];
  }
}
