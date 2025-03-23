import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rentapp/firebase_options.dart';

// This script can be run as a standalone Dart file or called from the app
void main() async {
  // Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized');
  } else {
    print('Firebase already initialized, using existing instance');
  }

  // Add sample data
  await addSampleCarData();
}

Future<void> addSampleCarData() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference carsCollection = firestore.collection('cars');

  // Sample car data as specified in FIRESTORE_SETUP.md
  final List<Map<String, dynamic>> cars = [
    {
      'model': 'Tesla Model 3',
      'distance': 15.5,
      'fuelCapacity': 100.0,
      'pricePerHour': 25.0
    },
    {
      'model': 'Toyota Camry',
      'distance': 20.0,
      'fuelCapacity': 60.0,
      'pricePerHour': 15.0
    },
    {
      'model': 'Honda Civic',
      'distance': 18.0,
      'fuelCapacity': 50.0,
      'pricePerHour': 12.0
    },
    {
      'model': 'BMW X5',
      'distance': 25.0,
      'fuelCapacity': 80.0,
      'pricePerHour': 30.0
    },
    {
      'model': 'Mercedes-Benz E-Class',
      'distance': 22.0,
      'fuelCapacity': 70.0,
      'pricePerHour': 35.0
    }
  ];

  print('Adding sample car data to Firestore...');

  // Create a batch to add all cars at once
  final WriteBatch batch = firestore.batch();

  try {
    // Check if cars collection already has data
    final QuerySnapshot existingCars = await carsCollection.limit(1).get();

    if (existingCars.docs.isNotEmpty) {
      print('Cars collection already has data. Skipping sample data creation.');
      return;
    }

    // Add each car to the batch
    for (final car in cars) {
      final DocumentReference carRef = carsCollection.doc();
      batch.set(carRef, car);
      print('Added car: ${car['model']}');
    }

    // Commit the batch
    await batch.commit();

    print('All sample car data added successfully!');
  } catch (error) {
    print('Error adding sample car data: $error');
    rethrow;
  }
}
