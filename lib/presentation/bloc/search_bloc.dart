import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';
import 'package:rentapp/presentation/bloc/search_event.dart';
import 'package:rentapp/presentation/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final CarRepository carRepository;
  List<Car> _allCars = [];

  SearchBloc({required this.carRepository}) : super(SearchInitial()) {
    on<SearchCarsByQuery>(_onSearchCarsByQuery);
    on<SearchCarsByCategory>(_onSearchCarsByCategory);
    on<FilterCarsByPriceRange>(_onFilterCarsByPriceRange);
    on<ClearSearch>(_onClearSearch);

    // Load all cars initially
    _loadAllCars();
  }

  Future<void> _loadAllCars() async {
    try {
      // Get all cars and store them with timeout
      final cars = await carRepository.fetchCars().timeout(
            const Duration(seconds: 5),
            onTimeout: () => [], // Return empty list on timeout
          );
      _allCars = cars;
    } catch (e) {
      // Log the error but continue
      print('[SEARCH] Error loading all cars: $e');
      // Don't throw, just continue with empty list
      _allCars = [];
    }
  }

  void _onSearchCarsByQuery(
    SearchCarsByQuery event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      List<Car> cars = [];
      if (_allCars.isEmpty) {
        // If cache is empty, get cars
        cars = await carRepository.fetchCars();
      } else {
        cars = _allCars;
      }

      final filteredCars = cars
          .where((car) =>
              car.name.toLowerCase().contains(event.query.toLowerCase()) ||
              car.brand.toLowerCase().contains(event.query.toLowerCase()) ||
              car.category.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      if (filteredCars.isEmpty) {
        emit(SearchEmpty());
      } else {
        emit(SearchLoaded(filteredCars));
      }
    } catch (e) {
      emit(SearchError('Error searching for cars: ${e.toString()}'));
    }
  }

  void _onSearchCarsByCategory(
    SearchCarsByCategory event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      List<Car> cars = [];
      if (_allCars.isEmpty) {
        // If cache is empty, get cars
        cars = await carRepository.fetchCars();
      } else {
        cars = _allCars;
      }

      final filteredCars = cars
          .where((car) =>
              car.category.toLowerCase() == event.category.toLowerCase())
          .toList();

      if (filteredCars.isEmpty) {
        emit(SearchEmpty());
      } else {
        emit(SearchLoaded(filteredCars));
      }
    } catch (e) {
      emit(SearchError('Error filtering cars by category: ${e.toString()}'));
    }
  }

  void _onFilterCarsByPriceRange(
    FilterCarsByPriceRange event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      List<Car> cars = [];
      if (_allCars.isEmpty) {
        // If cache is empty, get cars
        cars = await carRepository.fetchCars();
      } else {
        cars = _allCars;
      }

      final filteredCars = cars
          .where((car) =>
              car.pricePerDay >= event.minPrice &&
              car.pricePerDay <= event.maxPrice)
          .toList();

      if (filteredCars.isEmpty) {
        emit(SearchEmpty());
      } else {
        emit(SearchLoaded(filteredCars));
      }
    } catch (e) {
      emit(SearchError('Error filtering cars by price: ${e.toString()}'));
    }
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }
}
