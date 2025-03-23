import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/firebase_options.dart';
import 'package:rentapp/injection_container.dart' as di;
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/booking_bloc.dart';
import 'package:rentapp/presentation/pages/splash_screen.dart';
import 'package:rentapp/data/models/booking.dart';
import 'package:rentapp/presentation/bloc/search_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_event.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout
  bool firebaseInitialized = false;
  String? errorMessage;

  try {
    // Check if Firebase is already initialized to prevent duplicate initialization
    if (Firebase.apps.isEmpty) {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Firebase initialization timed out');
      });
    } else {
      // Get the existing app
      Firebase.app();
    }

    firebaseInitialized = true;

    // Initialize dependency injection
    di.initInjection();
  } catch (e) {
    // Handle specific duplicate app error
    if (e
        .toString()
        .contains('A Firebase App named "[DEFAULT]" already exists')) {
      try {
        // Try to get the existing app instance
        Firebase.app();
        firebaseInitialized = true;
        // Initialize dependency injection
        di.initInjection();
      } catch (innerError) {
        errorMessage = 'Firebase initialization error: $innerError';
        firebaseInitialized = false;
      }
    } else {
      errorMessage = e.toString();
      firebaseInitialized = false;
    }
  }

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    errorMessage: errorMessage,
  ));
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? errorMessage;

  const MyApp({
    Key? key,
    this.firebaseInitialized = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CarBloc>(create: (context) => di.getIt<CarBloc>()),
        BlocProvider<BookingBloc>(create: (context) => di.getIt<BookingBloc>()),
        BlocProvider<SearchBloc>(create: (context) => di.getIt<SearchBloc>()),
        BlocProvider<AuthBloc>(
          create: (context) => di.getIt<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Rent App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3A3A3A),
            primary: const Color(0xFF3A3A3A),
            secondary: const Color(0xFFF7F7F7),
            tertiary: const Color(0xFF9E9E9E),
            onPrimary: Colors.white,
            onSecondary: const Color(0xFF3A3A3A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF3A3A3A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Color(0xFF3A3A3A)),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A3A3A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3A3A3A),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
        // Start with the splash screen or error screen
        home: !firebaseInitialized
            ? _FirebaseErrorScreen(errorMessage: errorMessage)
            : const SplashScreen(),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String? errorMessage;

  const _FirebaseErrorScreen({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ??
                      'The app could not connect to Firebase. Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Reload the app by restarting with MaterialApp
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyApp(
                          firebaseInitialized: false,
                        ),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
