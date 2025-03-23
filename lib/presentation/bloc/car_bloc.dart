import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';

class CarBloc extends Bloc<CarEvent, CarState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<void> _onLoadCars(LoadCars event, Emitter<CarState> emit) async {
    // Prevent multiple simultaneous loading attempts
    if (_isLoading && state is CarsLoading) return;
    _isLoading = true;

    emit(CarsLoading());
    try {
      print('[CAR DEBUG] Loading all cars from Firestore');
      print('[CAR DEBUG] Using collection: cars');

      // First check if collection exists and has any documents
      final collectionRef = _firestore.collection('cars');
      final metadata = await collectionRef.get();
      print(
          '[CAR DEBUG] Collection exists: ${metadata.metadata.isFromCache ? 'from cache' : 'from server'}');
      print(
          '[CAR DEBUG] Documents count before query: ${metadata.docs.length}');

      // Add timeout to prevent hanging
      final snapshot = await _firestore
          .collection('cars')
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timed out while loading cars');
        },
      );

      print(
          '[CAR DEBUG] Query completed: ${snapshot.docs.length} documents found');

      if (snapshot.docs.isEmpty) {
        print('[CAR DEBUG] No cars found in the cars collection');
        print('[CAR DEBUG] Triggering sample car upload...');

        // Try to add sample cars directly from the CarBloc
        try {
          final collectionRef = _firestore.collection('cars');
          final carData = {
            'name': 'Test Car',
            'brand': 'Test Brand',
            'model': 'Test Model',
            'category': 'Sedan',
            'pricePerDay': 1000.0,
            'pricePerHour': 50.0,
            'mileage': 20.0,
            'fuelType': 'Petrol',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await collectionRef.add(carData);
          print('[CAR DEBUG] Added test car directly from car_bloc');

          // Try to fetch the cars again
          final newSnapshot = await _firestore
              .collection('cars')
              .get()
              .timeout(const Duration(seconds: 5));

          print(
              '[CAR DEBUG] After adding test car, found ${newSnapshot.docs.length} documents');
        } catch (e) {
          print('[CAR DEBUG] Error adding test car: $e');
        }
      }

      final cars = snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();
      print('[CAR DEBUG] Loaded ${cars.length} cars successfully');
      print('[CAR DEBUG] Car names: ${cars.map((car) => car.name).join(', ')}');

      emit(CarsLoaded(cars));
    } catch (e) {
      print('[CAR DEBUG] Error loading cars: $e');
      print('[CAR DEBUG] Error details: ${e.toString()}');
      print('[CAR DEBUG] Error stack trace: ${StackTrace.current}');
      emit(CarsError('Failed to load cars: $e'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onAddCar(AddCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      print(
          '[CAR DEBUG] Adding new car: ${event.car.name} (${event.car.brand})');

      // Add createdAt timestamp
      final carData = event.car.toFirestore();
      carData['createdAt'] = FieldValue.serverTimestamp();

      // If id is new, use it. Otherwise, Firestore will generate one
      final carRef = event.car.id.isNotEmpty
          ? _firestore.collection('cars').doc(event.car.id)
          : _firestore.collection('cars').doc();

      // Set the car data
      await carRef.set(carData);
      print('[CAR DEBUG] Car added with ID: ${carRef.id}');

      // Get the updated car with the Firestore ID
      final carDoc = await carRef.get();
      final car = Car.fromFirestore(carDoc);

      emit(CarAdded(car));

      // Reload all cars to update the state
      add(const LoadCars());
    } catch (e) {
      print('[CAR DEBUG] Error adding car: $e');
      emit(CarsError('Failed to add car: $e'));
    }
  }

  Future<void> _onUpdateCar(UpdateCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      print('[CAR DEBUG] Updating car: ${event.car.id}');

      // Update the car in Firestore
      await _firestore
          .collection('cars')
          .doc(event.car.id)
          .update(event.car.toFirestore());

      // Get the updated car
      final carDoc =
          await _firestore.collection('cars').doc(event.car.id).get();
      final car = Car.fromFirestore(carDoc);
      print('[CAR DEBUG] Car updated successfully');

      emit(CarUpdated(car));

      // Reload all cars to update the state
      add(const LoadCars());
    } catch (e) {
      print('[CAR DEBUG] Error updating car: $e');
      emit(CarsError('Failed to update car: $e'));
    }
  }

  Future<void> _onDeleteCar(DeleteCar event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      print('[CAR DEBUG] Deleting car with ID: ${event.carId}');

      // Delete the car from Firestore
      await _firestore.collection('cars').doc(event.carId).delete();
      print('[CAR DEBUG] Car deleted successfully');

      emit(CarDeleted(event.carId));

      // Reload all cars to update the state
      add(const LoadCars());
    } catch (e) {
      print('[CAR DEBUG] Error deleting car: $e');
      emit(CarsError('Failed to delete car: $e'));
    }
  }

  Future<void> _onSearchCars(SearchCars event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      print('[CAR DEBUG] Searching cars with query: ${event.query}');

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

      print('[CAR DEBUG] Found ${filteredCars.length} cars matching query');
      emit(CarsLoaded(filteredCars));
    } catch (e) {
      print('[CAR DEBUG] Error searching cars: $e');
      emit(CarsError('Failed to search cars: $e'));
    }
  }

  Future<void> _onFilterCarsByCategory(
      FilterCarsByCategory event, Emitter<CarState> emit) async {
    emit(CarsLoading());
    try {
      print('[CAR DEBUG] Filtering cars by category: ${event.category}');

      // Query cars by category
      final snapshot = event.category == 'All'
          ? await _firestore.collection('cars').get()
          : await _firestore
              .collection('cars')
              .where('category', isEqualTo: event.category)
              .get();

      final cars = snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();
      print('[CAR DEBUG] Found ${cars.length} cars in category');
      emit(CarsLoaded(cars));
    } catch (e) {
      print('[CAR DEBUG] Error filtering cars: $e');
      emit(CarsError('Failed to filter cars: $e'));
    }
  }
}
