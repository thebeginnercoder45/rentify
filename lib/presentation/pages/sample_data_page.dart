import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentapp/data/models/car.dart';

class SampleDataPage extends StatefulWidget {
  const SampleDataPage({Key? key}) : super(key: key);

  @override
  State<SampleDataPage> createState() => _SampleDataPageState();
}

class _SampleDataPageState extends State<SampleDataPage> {
  bool _isLoading = false;
  String _message = '';

  Future<void> _addSampleCars() async {
    setState(() {
      _isLoading = true;
      _message = 'Adding sample cars...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final carsRef = firestore.collection('cars');

      // Check if we already have cars
      final snapshot = await carsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _message = 'Sample cars already exist in Firestore.';
        });
        return;
      }

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
          name: 'Toyota Fortuner',
          brand: 'Toyota',
          model: 'Fortuner 4x4',
          fuelType: 'Diesel',
          mileage: 14.2,
          pricePerDay: 4500.0,
          pricePerHour: 250.0,
          latitude: 12.9553,
          longitude: 77.6654,
          distance: 8.1,
          fuelCapacity: 80.0,
          rating: 4.9,
          imageUrl: 'assets/cars/toyota_fortuner.png',
          category: 'SUV',
          description:
              'Powerful SUV perfect for adventure and off-road experiences.',
          features: {
            'seats': 7,
            'transmission': 'Automatic',
            'ac': true,
            'bluetooth': true,
            'cameraRear': true,
            'sunroof': true,
          },
        ),
        Car(
          id: 'car6',
          name: 'Hyundai Creta',
          brand: 'Hyundai',
          model: 'Creta SX',
          fuelType: 'Petrol',
          mileage: 17.0,
          pricePerDay: 2800.0,
          pricePerHour: 150.0,
          latitude: 12.9231,
          longitude: 77.6851,
          distance: 4.5,
          fuelCapacity: 50.0,
          rating: 4.6,
          imageUrl: 'assets/cars/hyundai_creta.png',
          category: 'SUV',
          description: 'Stylish compact SUV with premium features and comfort.',
          features: {
            'seats': 5,
            'transmission': 'Manual',
            'ac': true,
            'bluetooth': true,
            'cameraRear': true,
          },
        ),
      ];

      // Add each car to Firestore with set() to use our custom IDs
      for (final car in sampleCars) {
        await carsRef.doc(car.id).set(car.toJson());
      }

      setState(() {
        _isLoading = false;
        _message =
            'Successfully added ${sampleCars.length} sample cars to Firestore!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error adding sample cars: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _addSampleCars,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Sample Cars to Firestore'),
              ),
              const SizedBox(height: 24),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _message.contains('Error')
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('Error')
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
