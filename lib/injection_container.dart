import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:rentapp/data/datasources/firebase_booking_data_source.dart';
import 'package:rentapp/data/datasources/firebase_car_data_source.dart';
import 'package:rentapp/data/repositories/booking_repository_impl.dart';
import 'package:rentapp/data/repositories/car_repository_impl.dart';
import 'package:rentapp/domain/repositories/booking_repository.dart';
import 'package:rentapp/domain/repositories/car_repository.dart';
import 'package:rentapp/domain/usecases/cancel_booking.dart';
import 'package:rentapp/domain/usecases/create_booking.dart';
import 'package:rentapp/domain/usecases/filter_cars_by_price.dart';
import 'package:rentapp/domain/usecases/get_car_by_id.dart';
import 'package:rentapp/domain/usecases/get_cars.dart';
import 'package:rentapp/domain/usecases/search_cars.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/bloc/search_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

GetIt getIt = GetIt.instance;

void initInjection() {
  try {
    // Firebase
    getIt.registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instance);
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

    // Data Sources
    getIt.registerLazySingleton<FirebaseCarDataSource>(
        () => FirebaseCarDataSource(firestore: getIt<FirebaseFirestore>()));
    getIt.registerLazySingleton<FirebaseBookingDataSource>(
        () => FirebaseBookingDataSource(firestore: getIt<FirebaseFirestore>()));

    // Repositories
    getIt.registerLazySingleton<CarRepository>(
        () => CarRepositoryImpl(getIt<FirebaseCarDataSource>()));
    getIt.registerLazySingleton<BookingRepository>(
        () => BookingRepositoryImpl(getIt<FirebaseBookingDataSource>()));

    // Use Cases
    getIt.registerLazySingleton<GetCars>(() => GetCars(getIt<CarRepository>()));
    getIt.registerLazySingleton<GetCarById>(
        () => GetCarById(getIt<CarRepository>()));
    getIt.registerLazySingleton<SearchCars>(
        () => SearchCars(getIt<CarRepository>()));
    getIt.registerLazySingleton<FilterCarsByPrice>(
        () => FilterCarsByPrice(getIt<CarRepository>()));
    getIt.registerLazySingleton<CreateBooking>(
        () => CreateBooking(getIt<BookingRepository>()));
    getIt.registerLazySingleton<CancelBooking>(
        () => CancelBooking(getIt<BookingRepository>()));

    // BLoCs
    getIt.registerFactory(() => CarBloc());
    getIt.registerFactory(
        () => SearchBloc(carRepository: getIt<CarRepository>()));
    getIt.registerFactory(() => BookingBloc(
          bookingRepository: getIt<BookingRepository>(),
          createBookingUseCase: getIt<CreateBooking>(),
          cancelBookingUseCase: getIt<CancelBooking>(),
        ));
    getIt.registerFactory(() => AuthBloc(
          auth: getIt<FirebaseAuth>(),
          firestore: getIt<FirebaseFirestore>(),
        ));
  } catch (e) {
    throw e;
  }
}
