import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/car/data/repositories/car_repository.dart';
import 'features/car/presentation/bloc/car_bloc.dart';
import 'features/car/presentation/screens/car_listing_screen.dart';
import 'features/booking/data/repositories/booking_repository.dart';
import 'features/booking/presentation/bloc/booking_bloc.dart';
import 'features/booking/presentation/screens/booking_screen.dart';
import 'features/booking/presentation/screens/bookings_list_screen.dart';
import 'features/payment/data/repositories/payment_repository.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/payment/presentation/screens/payment_screen.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'firebase_options.dart';
import 'config/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => FirebaseAuthRepository()),
        RepositoryProvider(create: (context) => CarRepository()),
        RepositoryProvider(create: (context) => BookingRepository()),
        RepositoryProvider(create: (context) => PaymentRepository()),
        RepositoryProvider(create: (context) => AdminRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => AuthBloc(
                  authRepository: context.read<FirebaseAuthRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) =>
                    CarBloc(carRepository: context.read<CarRepository>()),
          ),
          BlocProvider(
            create: (context) => BookingBloc(context.read<BookingRepository>()),
          ),
          BlocProvider(
            create: (context) => PaymentBloc(context.read<PaymentRepository>()),
          ),
          BlocProvider(
            create: (context) => AdminBloc(context.read<AdminRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Rentify',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}
