import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class CarBloc extends Bloc<CarEvent, CarState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  bool _isLoading = false; // Flag to prevent multiple loading attempts

  CarBloc() : super(CarInitial()) {
    on<LoadCars>(_onLoadCars);
    on<AddCar>(_onAddCar);
    on<UpdateCar>(_onUpdateCar);
    on<DeleteCar>(_onDeleteCar);
    on<SearchCars>(_onSearchCars);
    on<FilterCarsByCategory>(_onFilterCarsByCategory);
    // Initial load with a slight delay to ensure Firebase is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      add(const LoadCars());
    });
  }

  /// Check if the device is connected to the internet
  Future<bool> _isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  Future<void> _onLoadCars(LoadCars event, Emitter<CarState> emit) async {
    // Prevent multiple simultaneous loading attempts
    if (_isLoading && state is CarsLoading) return;
    _isLoading = true;

    emit(CarsLoading());
    try {
      debugPrint('Loading all cars from Firestore');
      debugPrint('Using collection: cars');

      // Check connectivity first
      final isConnected = await _isConnected();
      if (!isConnected) {
        emit(CarsError(
            'No internet connection. Please check your network settings.'));
        _isLoading = false;
        return;
      }

      try {
        final QuerySnapshot snapshot =
            await _firestore.collection('cars').get();
        final List<Car> cars = snapshot.docs
            .map((doc) => Car.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList();

        if (cars.isEmpty) {
          // If no cars were found, add sample cars as fallback
          emit(CarsLoaded(await _getLocalSampleCars()));
        } else {
          emit(CarsLoaded(cars));
        }
      } catch (firestoreError) {
        debugPrint('Error loading cars: $firestoreError');
        debugPrint('Error details: $firestoreError');

        // If there's a permission error, use local sample data instead
        if (firestoreError.toString().contains('permission-denied')) {
          debugPrint('Using local sample cars due to permission error');
          emit(CarsLoaded(await _getLocalSampleCars()));
        } else {
          emit(CarsError('Failed to load cars: $firestoreError'));
        }
      }
    } catch (e) {
      debugPrint('Error getting cars: $e');
      // Provide fallback data for a better user experience
      emit(CarsLoaded(await _getLocalSampleCars()));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onAddCar(AddCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      debugPrint('Adding car: ${event.car.name}');
      debugPrint('Car image URL: ${event.car.imageUrl}');

      // Validate car data before saving
      if (event.car.name.isEmpty ||
          event.car.brand.isEmpty ||
          event.car.pricePerDay <= 0) {
        emit(CarsError(
            'Invalid car data: All required fields must be provided'));
        return;
      }

      debugPrint('Car details: ${event.car.toFirestore()}');

      // Make sure we have a valid car with ID
      final car = event.car.id.isEmpty
          ? event.car.copyWith(id: const Uuid().v4())
          : event.car;

      debugPrint('Car ID: ${car.id}');

      // Check image URL again to make sure it's being passed correctly
      debugPrint('Image URL before saving: ${car.imageUrl}');

      // Check connectivity first
      final isConnected = await _isConnected();
      debugPrint('Network connection available: $isConnected');

      try {
        // Add car directly to Firestore
        final carRef = car.id.isNotEmpty
            ? _firestore.collection('cars').doc(car.id)
            : _firestore.collection('cars').doc();

        debugPrint('Firestore document reference created: ${carRef.path}');

        // Set the car data with proper metadata
        final carData = {
          ...car.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'id': carRef.id, // Ensure ID is included in the document
        };
        debugPrint('Car data to save: $carData');
        debugPrint('Image URL in car data: ${carData['imageUrl']}');

        // Use batched writes or transactions for more reliable operations
        final batch = _firestore.batch();
        batch.set(carRef, carData);

        // Execute the batch
        await batch.commit();
        debugPrint('Car data saved to Firestore successfully');

        // Add a small delay to ensure Firestore has completed indexing
        await Future.delayed(const Duration(milliseconds: 300));

        // Reload cars to update the list
        await _loadCars(emit);

        // Emit success state
        final savedCar = car.copyWith(id: carRef.id);
        emit(CarAdded(savedCar));
        debugPrint('CarAdded state emitted with ID: ${carRef.id}');

        if (!isConnected) {
          // If offline, also emit a warning that data will sync later
          Future.delayed(const Duration(milliseconds: 100), () {
            emit(CarsError(
                'Car saved locally. Will sync when connected to the internet.'));
          });
        }
      } catch (e) {
        debugPrint('Error adding car to Firestore: $e');
        debugPrint('Error details: ${e.toString()}');

        // Check if it's a timeout or network error
        if (e.toString().contains('TimeoutException') ||
            e.toString().contains('network') ||
            e.toString().contains('unavailable')) {
          emit(CarsError(
              'Network error: Please check your internet connection. Your data will be saved when connection is restored.'));
        } else {
          emit(CarsError('Failed to add car: $e'));
        }
      }
    } catch (e) {
      debugPrint('Error in car addition process: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      emit(CarsError('Failed to add car: $e'));
    }
  }

  Future<void> _onUpdateCar(UpdateCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      debugPrint('Updating car: ${event.car.id}');
      debugPrint('Car image URL: ${event.car.imageUrl}');

      // Add car data to Firestore with the image URL
      final carData = event.car.toFirestore();
      debugPrint('Car data for update: $carData');
      debugPrint('Image URL in update data: ${carData['imageUrl']}');

      // Update the car in Firestore
      await _firestore.collection('cars').doc(event.car.id).update(carData);

      // Get the updated car
      final carDoc =
          await _firestore.collection('cars').doc(event.car.id).get();
      final car = Car.fromFirestore(carDoc);
      debugPrint('Car updated successfully');
      debugPrint('Updated car image URL: ${car.imageUrl}');

      emit(CarUpdated(car));

      // Reload all cars to update the state
      add(const LoadCars());
    } catch (e) {
      debugPrint('Error updating car: $e');
      emit(CarsError('Failed to update car: $e'));
    }
  }

  Future<void> _onDeleteCar(DeleteCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      debugPrint('Deleting car with ID: ${event.carId}');

      // Delete the car from Firestore
      await _firestore.collection('cars').doc(event.carId).delete();
      debugPrint('Car deleted successfully');

      emit(CarDeleted(event.carId));

      // Reload all cars to update the state
      add(const LoadCars());
    } catch (e) {
      debugPrint('Error deleting car: $e');
      emit(CarsError('Failed to delete car: $e'));
    }
  }

  Future<void> _onSearchCars(SearchCars event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      debugPrint('Searching cars with query: ${event.query}');

      final snapshot = await _firestore.collection('cars').get();
      final allCars =
          snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();

      if (event.query.isEmpty) {
        emit(CarsLoaded(allCars));
        return;
      }

      // Filter cars by name, brand, model or category
      final query = event.query.toLowerCase();
      final filteredCars = allCars
          .where((car) =>
              car.name.toLowerCase().contains(query) ||
              car.brand.toLowerCase().contains(query) ||
              car.model.toLowerCase().contains(query) ||
              car.category.toLowerCase().contains(query))
          .toList();

      debugPrint('Found ${filteredCars.length} cars matching query');
      emit(CarsLoaded(filteredCars));
    } catch (e) {
      debugPrint('Error searching cars: $e');
      emit(CarsError('Failed to search cars: $e'));
    }
  }

  Future<void> _onFilterCarsByCategory(
      FilterCarsByCategory event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      debugPrint('Filtering cars by category: ${event.category}');

      // Query cars by category
      final snapshot = event.category == 'All'
          ? await _firestore.collection('cars').get()
          : await _firestore
              .collection('cars')
              .where('category', isEqualTo: event.category)
              .get();

      final cars = snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();
      debugPrint('Found ${cars.length} cars in category');
      emit(CarsLoaded(cars));
    } catch (e) {
      debugPrint('Error filtering cars: $e');
      emit(CarsError('Failed to filter cars: $e'));
    }
  }

  // Helper method to load all cars
  Future<void> _loadCars(Emitter<CarState> emit) async {
    // Prevent multiple simultaneous loading attempts
    if (_isLoading && state is CarsLoading) return;
    _isLoading = true;

    try {
      debugPrint('Loading all cars from Firestore');

      // Try to load from cache first if available
      List<Car> cars = [];
      bool loadedFromCache = false;

      try {
        final metadata = await _firestore
            .collection('cars')
            .get(GetOptions(source: Source.cache));

        if (metadata.docs.isNotEmpty) {
          cars = metadata.docs.map((doc) => Car.fromFirestore(doc)).toList();
          loadedFromCache = true;
          debugPrint('Loaded ${cars.length} cars from cache');
        }
      } catch (e) {
        debugPrint('No cached data available: $e');
      }

      if (!loadedFromCache) {
        try {
          // Try to get from server
          final snapshot = await _firestore
              .collection('cars')
              .orderBy('updatedAt', descending: true)
              .get(GetOptions(source: Source.server))
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Loading cars timed out');
            },
          );

          cars = snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();
          debugPrint('Loaded ${cars.length} cars from server');
        } catch (e) {
          debugPrint('Error loading from server, attempting default get: $e');

          // Last resort - try default get which may use cache or server
          final snapshot = await _firestore
              .collection('cars')
              .orderBy('updatedAt', descending: true)
              .get()
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Loading cars timed out');
            },
          );

          cars = snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();
          debugPrint('Loaded ${cars.length} cars from default source');
        }
      }

      debugPrint('Car names: ${cars.map((car) => car.name).join(', ')}');
      emit(CarsLoaded(cars));
    } catch (e) {
      debugPrint('Error loading cars: $e');
      debugPrint('Error details: ${e.toString()}');
      emit(CarsError('Failed to load cars: $e'));
    } finally {
      _isLoading = false;
    }
  }

  // Create sample cars for offline or fallback use
  Future<List<Car>> _getLocalSampleCars() async {
    return [
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
        name: 'Mercedes',
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
        imageUrl: 'assets/car_image.png',
        category: 'Luxury',
        description: 'Luxury car with premium features and a powerful engine.',
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
  }
}
